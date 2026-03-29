import dataSource from '../database/data-source';
import { seedDatabase } from '../database/seeds/main.seeder';

const run = async () => {
    try {
        await dataSource.initialize();
        console.log('Data Source initialized');
        await seedDatabase(dataSource);
        await dataSource.destroy();
        process.exit(0);
    } catch (error) {
        console.error('Error during seeding:', error);
        process.exit(1);
    }
};

run();
