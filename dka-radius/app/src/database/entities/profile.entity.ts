import { Entity, PrimaryGeneratedColumn, Column, OneToMany } from 'typeorm';
import { User } from './user.entity';
import { ProfileFupTier } from './profile-fup-tier.entity';

@Entity('profiles')
export class Profile {
    @PrimaryGeneratedColumn()
    id: number;

    @Column({ unique: true })
    name: string;

    @Column({ type: 'int', default: 0 })
    max_download: number; // Mbps

    @Column({ type: 'int', default: 0 })
    max_upload: number; // Mbps

    @Column({ type: 'int', default: 0 })
    max_data_quota: number; // MB, 0 = unlimited

    @Column({ type: 'int', default: 0 })
    access_period: number; // Seconds, 0 = unlimited

    @OneToMany(() => User, (user) => user.profile)
    users: User[];

    @OneToMany(() => ProfileFupTier, (tier) => tier.profile, { cascade: true })
    fup_tiers: ProfileFupTier[];
}
