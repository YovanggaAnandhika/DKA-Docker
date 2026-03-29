import { Injectable, Logger, HttpStatus, HttpException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User, ConnectionType, UserStatus } from '../database/entities/user.entity';
import { Accounting } from '../database/entities/accounting.entity';
import { Nas } from '../database/entities/nas.entity';
import { CoaService } from './coa.service';

@Injectable()
export class RadiusService {
    private readonly logger = new Logger(RadiusService.name);

    constructor(
        @InjectRepository(User) private userRepo: Repository<User>,
        @InjectRepository(Accounting) private accountingRepo: Repository<Accounting>,
        @InjectRepository(Nas) private nasRepo: Repository<Nas>,
        private coaService: CoaService,
    ) { }

    async authorize(body: any): Promise<void> {
        // Standard FreeRADIUS rest module 'authorize' usually returns 204 if OK
        return;
    }

    async authenticate(body: any): Promise<any> {
        const attrs = this.flattenAttributes(body);
        const username = attrs['User-Name'];
        const password = attrs['User-Password'];

        this.logger.log(`Auth request for user: ${username}`);

        const user = await this.userRepo.findOne({
            where: { username },
            relations: ['profile', 'profile.fup_tiers']
        });

        if (!user) {
            throw new HttpException({ 'Reply-Message': 'User not found' }, HttpStatus.NOT_FOUND);
        }

        if (user.password !== password) {
            throw new HttpException({ 'Reply-Message': 'Invalid password' }, HttpStatus.UNAUTHORIZED);
        }

        if (user.status !== UserStatus.ACTIVE) {
            throw new HttpException({ 'Reply-Message': 'User is not active' }, HttpStatus.UNAUTHORIZED);
        }

        // 1. Check if user is already over quota or expired
        this.checkUserQuotas(user);

        // 2. Determine final speeds
        const speeds = this.calculateEffectiveSpeeds(user);

        // Prepare response attributes
        const reply: any = {};

        if (user.connection_type === ConnectionType.PPP) {
            // Mikrotik PPP Rate Limit: rx-rate/tx-rate
            reply['Mikrotik-Rate-Limit'] = `${speeds.upload}M/${speeds.download}M`;
        } else {
            // Hotspot / Generic WISPr
            reply['WISPr-Bandwidth-Max-Down'] = speeds.download * 1024 * 1024;
            reply['WISPr-Bandwidth-Max-Up'] = speeds.upload * 1024 * 1024;
        }

        // Session Timeout
        const accessPeriod = user.access_period_override ?? user.profile.access_period;
        if (accessPeriod > 0) {
            const expiry = new Date(user.register_date.getTime() + accessPeriod * 1000);
            const remainingTime = Math.max(0, Math.floor((expiry.getTime() - Date.now()) / 1000));
            reply['Session-Timeout'] = remainingTime;
        }

        // Data Quota (Limit Bytes)
        const dataQuotaMB = user.max_data_quota_override ?? user.profile.max_data_quota;
        if (dataQuotaMB > 0) {
            const totalQuotaBytes = BigInt(dataQuotaMB) * BigInt(1024 * 1024);
            const usedBytes = BigInt(user.total_used_data || 0);
            const remainingBytes = totalQuotaBytes > usedBytes ? totalQuotaBytes - usedBytes : BigInt(0);

            // Limit for Mikrotik (Total bytes)
            reply['Mikrotik-Total-Limit'] = Number(remainingBytes);
        }

        return reply;
    }

    private calculateEffectiveSpeeds(user: User): { download: number, upload: number } {
        if (!user.profile.fup_tiers || user.profile.fup_tiers.length === 0) {
            return { download: user.profile.max_download, upload: user.profile.max_upload };
        }

        // Sort tiers by threshold descending
        const sortedTiers = [...user.profile.fup_tiers].sort((a, b) => b.threshold - a.threshold);
        const activeTier = sortedTiers.find(tier => user.total_used_data >= BigInt(tier.threshold) * BigInt(1024 * 1024));

        if (activeTier) {
            this.logger.log(`User ${user.username} is under FUP Tier (>= ${activeTier.threshold}MB). Throttling.`);
            return {
                download: activeTier.max_download,
                upload: activeTier.max_upload
            };
        }

        return {
            download: user.profile.max_download,
            upload: user.profile.max_upload
        };
    }

    async accounting(body: any): Promise<any> {
        const attrs = this.flattenAttributes(body);
        const username = attrs['User-Name'];
        const sessionId = attrs['Acct-Session-Id'];
        const statusType = attrs['Acct-Status-Type'];

        // Handle NAS-level accounting events (Accounting-On/Off)
        // These don't have session IDs or user names, so we just acknowledge them.
        if (statusType === 'Accounting-On' || statusType === 'Accounting-Off') {
            this.logger.log(`NAS Event: ${statusType} from ${attrs['NAS-IP-Address']}`);
            return attrs;
        }

        if (!sessionId) {
            this.logger.warn(`Accounting request missing Acct-Session-Id. Status: ${statusType}`);
            return attrs;
        }

        // Helper to calculate total bytes from Octets and Gigawords safely
        const calculateBytes = (octets: any, gigawords: any) => {
            return BigInt(octets || 0) + (BigInt(gigawords || 0) << BigInt(32));
        };

        const currentInput = calculateBytes(attrs['Acct-Input-Octets'], attrs['Acct-Input-Gigawords']);
        const currentOutput = calculateBytes(attrs['Acct-Output-Octets'], attrs['Acct-Output-Gigawords']);
        const sessionTotal = currentInput + currentOutput;

        // 1. Get previous record from this session to calculate the INCREMENT
        const previousRecord = await this.accountingRepo.findOne({
            where: { acct_session_id: sessionId },
        });

        const lastInput = previousRecord ? BigInt(previousRecord.acct_input_octets) : BigInt(0);
        const lastOutput = previousRecord ? BigInt(previousRecord.acct_output_octets) : BigInt(0);
        const lastTotal = lastInput + lastOutput;

        const increment = sessionTotal > lastTotal ? sessionTotal - lastTotal : BigInt(0);

        // 2. Save/Update accounting record (upsert based on session id)
        await this.accountingRepo.upsert({
            acct_session_id: sessionId,
            user_name: username,
            nas_ip_address: attrs['NAS-IP-Address'],
            acct_status_type: attrs['Acct-Status-Type'],
            acct_input_octets: currentInput,
            acct_output_octets: currentOutput,
            acct_session_time: parseInt(attrs['Acct-Session-Time'] || 0),
            raw_attributes: body,
        }, ['acct_session_id']);

        // 3. Update user total data only if there's an increment
        const user = await this.userRepo.findOne({
            where: { username },
            relations: ['profile', 'profile.fup_tiers']
        });

        if (user && increment > BigInt(0)) {
            // Explicitly cast to BigInt since TypeORM bigint is a string in JS
            const currentTotal = BigInt(user.total_used_data || 0);
            const newTotal = currentTotal + increment;

            await this.userRepo.update(user.id, { total_used_data: newTotal });

            // Re-fetch or update the local object for quota checks
            user.total_used_data = newTotal;

            // 4. Auto-Disconnect logic
            const dataQuota = user.max_data_quota_override ?? user.profile.max_data_quota;
            const quotaBytes = dataQuota > 0 ? BigInt(dataQuota) * BigInt(1024 * 1024) : null;

            if (quotaBytes && user.total_used_data >= quotaBytes) {
                this.logger.warn(`User ${username} exceeded hard quota (${user.total_used_data} bytes). Disconnecting...`);
                await this.coaService.disconnectUser(username, attrs['NAS-IP-Address'], sessionId);
            } else if (user.profile.fup_tiers && user.profile.fup_tiers.length > 0) {
                const sortedTiers = [...user.profile.fup_tiers].sort((a, b) => b.threshold - a.threshold);
                const reachedTier = sortedTiers.find(tier => user.total_used_data >= BigInt(tier.threshold) * BigInt(1024 * 1024));

                if (reachedTier) {
                    this.logger.warn(`User ${username} reached FUP Tier (${reachedTier.threshold}MB). Disconnecting for throttle...`);
                    await this.coaService.disconnectUser(username, attrs['NAS-IP-Address'], sessionId);
                }
            }
        }

        return attrs;
    }

    async lookupNas(body: any): Promise<any> {
        // Dynamic client lookup for FreeRADIUS
        const nasIp = body['Packet-Src-IP-Address']?.[0] || body['nasname']?.[0];
        const nas = await this.nasRepo.findOne({ where: { nasname: nasIp } });

        if (!nas) {
            throw new HttpException('NAS not found', HttpStatus.NOT_FOUND);
        }

        return {
            'FreeRADIUS-Client-Secret': nas.secret,
            'FreeRADIUS-Client-Shortname': nas.shortname,
            'FreeRADIUS-Client-NAS-Type': nas.type || 'Mikrotik',
        };
    }

    private checkUserQuotas(user: User) {
        const dataQuota = user.max_data_quota_override ?? user.profile.max_data_quota;
        if (dataQuota > 0) {
            const quotaBytes = BigInt(dataQuota) * BigInt(1024 * 1024);
            if (user.total_used_data >= quotaBytes) {
                this.logger.warn(`User ${user.username} rejected: Quota Habis`);
                throw new HttpException({
                    'Reply-Message': 'Maaf, Kuota Data Anda Telah Habis. Silakan Isi Ulang Paket Anda.'
                }, HttpStatus.UNAUTHORIZED);
            }
        }

        const accessPeriod = user.access_period_override ?? user.profile.access_period;
        if (accessPeriod > 0) {
            const expiry = new Date(user.register_date.getTime() + accessPeriod * 1000);
            if (Date.now() >= expiry.getTime()) {
                this.logger.warn(`User ${user.username} rejected: Masa Aktif Habis`);
                throw new HttpException({
                    'Reply-Message': 'Maaf, Masa Aktif Akun Anda Telah Berakhir. Silakan Hubungi Admin.'
                }, HttpStatus.UNAUTHORIZED);
            }
        }
    }

    private flattenAttributes(body: any): any {
        const result = {};
        for (const key in body) {
            if (body[key]?.value) {
                result[key] = body[key].value[0];
            }
        }
        return result;
    }
}
