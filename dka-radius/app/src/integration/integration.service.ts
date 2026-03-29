import { Injectable, HttpStatus, HttpException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User, ConnectionType, UserStatus } from '../database/entities/user.entity';
import { Profile } from '../database/entities/profile.entity';
import { Accounting } from '../database/entities/accounting.entity';

@Injectable()
export class IntegrationService {
    constructor(
        @InjectRepository(User) private userRepo: Repository<User>,
        @InjectRepository(Profile) private profileRepo: Repository<Profile>,
        @InjectRepository(Accounting) private accountingRepo: Repository<Accounting>,
    ) { }

    async createProfile(data: any) {
        const profile = this.profileRepo.create(data);
        return this.profileRepo.save(profile);
    }

    async createUser(data: any) {
        const user = this.userRepo.create(data);
        return this.userRepo.save(user);
    }

    async getUsage(username: string) {
        const user = await this.userRepo.findOne({ where: { username }, relations: ['profile'] });
        if (!user) throw new HttpException('User not found', HttpStatus.NOT_FOUND);

        return {
            username: user.username,
            total_used_data: user.total_used_data.toString(), // Convert bigint to string
            connection_type: user.connection_type,
        };
    }

    async listUsers() {
        const users = await this.userRepo.find({ relations: ['profile'] });
        return users.map(u => ({
            ...u,
            total_used_data: u.total_used_data.toString()
        }));
    }
}
