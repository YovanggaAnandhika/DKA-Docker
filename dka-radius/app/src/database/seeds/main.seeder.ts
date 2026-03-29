import { DataSource } from 'typeorm';
import { Profile } from '../entities/profile.entity';
import { User, ConnectionType, UserStatus } from '../entities/user.entity';
import { Nas } from '../entities/nas.entity';
import { ProfileFupTier } from '../entities/profile-fup-tier.entity';

export const seedDatabase = async (dataSource: DataSource) => {
    const profileRepo = dataSource.getRepository(Profile);
    const fupRepo = dataSource.getRepository(ProfileFupTier);
    const userRepo = dataSource.getRepository(User);
    const nasRepo = dataSource.getRepository(Nas);

    // 1. Create Default Profiles
    const basicProfile = profileRepo.create({
        name: 'Basic Plan',
        max_download: 1,
        max_upload: 1,
        max_data_quota: 1024, // 1GB hard limit
        access_period: 3600 * 24, // 1 day
    });
    await profileRepo.save(basicProfile);

    const tieredProfile = profileRepo.create({
        name: 'Tiered Unlimited (FUP Bertingkat)',
        max_download: 20,
        max_upload: 10,
        max_data_quota: 0,
        access_period: 0,
    });
    await profileRepo.save(tieredProfile);

    // Add tiers to tieredProfile
    const tiers = [
        fupRepo.create({ profile: tieredProfile, threshold: 10240, max_download: 10, max_upload: 5 }), // 10GB -> 10Mbps
        fupRepo.create({ profile: tieredProfile, threshold: 20480, max_download: 5, max_upload: 2 }),  // 20GB -> 5Mbps
        fupRepo.create({ profile: tieredProfile, threshold: 30720, max_download: 2, max_upload: 1 }),  // 30GB -> 2Mbps
    ];
    await fupRepo.save(tiers);

    // 2. Create Initial Users
    const user1 = userRepo.create({
        username: 'dka',
        password: 'dka',
        connection_type: ConnectionType.HOTSPOT,
        status: UserStatus.ACTIVE,
        profile: basicProfile,
    });
    const user2 = userRepo.create({
        username: 'test_ppp',
        password: 'password456',
        connection_type: ConnectionType.PPP,
        status: UserStatus.ACTIVE,
        profile: tieredProfile,
    });
    await userRepo.save([user1, user2]);

    // 3. Create initial NAS
    const nas1 = nasRepo.create({
        nasname: '80.80.0.1', // User provided Mikrotik IP
        secret: 'Cyberhack2010', // User provided secret
        shortname: 'mikrotik_simulation',
        type: 'Mikrotik',
    });
    await nasRepo.save([nas1]);

    console.log('Database seeded successfully!');
};
