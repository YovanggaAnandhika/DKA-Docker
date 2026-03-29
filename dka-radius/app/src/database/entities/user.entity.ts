import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, ManyToOne, JoinColumn } from 'typeorm';
import { Profile } from './profile.entity';

export enum ConnectionType {
    PPP = 'ppp',
    HOTSPOT = 'hotspot',
}

export enum UserStatus {
    ACTIVE = 'active',
    SUSPENDED = 'suspended',
    CANCELED = 'canceled',
}

@Entity('users')
export class User {
    @PrimaryGeneratedColumn()
    id: number;

    @Column({ unique: true })
    username: string;

    @Column()
    password: string;

    @Column({ type: 'enum', enum: ConnectionType, default: ConnectionType.HOTSPOT })
    connection_type: ConnectionType;

    @Column({ type: 'enum', enum: UserStatus, default: UserStatus.ACTIVE })
    status: UserStatus;

    @CreateDateColumn()
    register_date: Date;

    @Column({ type: 'bigint', default: 0 })
    total_used_data: bigint; // Bytes

    @Column({ type: 'int', nullable: true })
    max_data_quota_override: number; // MB, null = use profile

    @Column({ type: 'int', nullable: true })
    access_period_override: number; // Seconds, null = use profile

    @ManyToOne(() => Profile, (profile) => profile.users, { eager: true })
    @JoinColumn({ name: 'profile_id' })
    profile: Profile;
}
