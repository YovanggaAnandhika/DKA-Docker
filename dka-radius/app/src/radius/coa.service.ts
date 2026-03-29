import { Injectable, Logger } from '@nestjs/common';
import { exec } from 'child_process';
import { ConfigService } from '@nestjs/config';
import { Nas } from '../database/entities/nas.entity';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';

@Injectable()
export class CoaService {
    private readonly logger = new Logger(CoaService.name);

    constructor(
        private configService: ConfigService,
        @InjectRepository(Nas)
        private nasRepo: Repository<Nas>
    ) { }

    async disconnectUser(username: string, nasIp: string, sessionId?: string): Promise<void> {
        // Try to find NAS secret in database first
        const nas = await this.nasRepo.findOne({ where: { nasname: nasIp } });
        const secret = nas?.secret || this.configService.get<string>('DKA_NAS_SECRET') || 'Cyberhack2010';

        // Build attribute list for radclient
        let attributes = `User-Name=${username}\nNAS-IP-Address=${nasIp}`;
        if (sessionId) {
            attributes += `\nAcct-Session-Id=${sessionId}`;
        }

        // Use printf to handle newlines correctly for radclient
        const command = `printf "${attributes}" | radclient -x ${nasIp}:3799 disconnect ${secret}`;

        this.logger.log(`Executing CoA Disconnect for ${username} at ${nasIp} (Session: ${sessionId || 'N/A'})`);

        exec(command, (error, stdout, stderr) => {
            if (error) {
                this.logger.error(`CoA Error: ${error.message}`);
                return;
            }
            if (stderr && !stderr.includes('Expected Disconnect-ACK')) {
                this.logger.warn(`CoA Stderr: ${stderr}`);
            }
            this.logger.log(`CoA Output: ${stdout.trim()}`);
        });
    }
}
