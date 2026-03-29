import { DataSource } from 'typeorm';
import { config } from 'dotenv';
import { User } from './entities/user.entity';
import { Profile } from './entities/profile.entity';
import { Accounting } from './entities/accounting.entity';
import { Nas } from './entities/nas.entity';
import { ProfileFupTier } from './entities/profile-fup-tier.entity';

config();

export default new DataSource({
    type: 'postgres',
    host: process.env.DB_HOST || 'localhost',
    port: parseInt(process.env.DB_PORT || '5432', 10),
    username: process.env.DB_USERNAME || 'postgres',
    password: process.env.DB_PASSWORD || 'postgres',
    database: process.env.DB_DATABASE || 'radius_db',
    entities: [User, Profile, Accounting, Nas, ProfileFupTier],
    migrations: ['src/database/migrations/*.ts'],
    synchronize: false,
});
