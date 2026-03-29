import { Entity, PrimaryGeneratedColumn, Column, ManyToOne } from 'typeorm';
import { Profile } from './profile.entity';

@Entity('profile_fup_tiers')
export class ProfileFupTier {
    @PrimaryGeneratedColumn()
    id: number;

    @Column({ type: 'int' })
    threshold: number; // MB

    @Column({ type: 'int' })
    max_download: number; // Mbps

    @Column({ type: 'int' })
    max_upload: number; // Mbps

    @ManyToOne(() => Profile, (profile) => profile.fup_tiers, { onDelete: 'CASCADE' })
    profile: Profile;
}
