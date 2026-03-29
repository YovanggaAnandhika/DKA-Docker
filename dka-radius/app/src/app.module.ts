import { Module } from '@nestjs/common';
import { RouterModule } from '@nestjs/core';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { User } from './database/entities/user.entity';
import { Profile } from './database/entities/profile.entity';
import { Accounting } from './database/entities/accounting.entity';
import { Nas } from './database/entities/nas.entity';
import { ProfileFupTier } from './database/entities/profile-fup-tier.entity';
import { RadiusModule } from './radius/radius.module';
import { IntegrationModule } from './integration/integration.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
    }),
    TypeOrmModule.forRootAsync({
      imports: [ConfigModule],
      useFactory: (configService: ConfigService) => ({
        type: 'postgres',
        host: configService.get<string>('DB_HOST'),
        port: configService.get<number>('DB_PORT'),
        username: configService.get<string>('DB_USERNAME'),
        password: configService.get<string>('DB_PASSWORD'),
        database: configService.get<string>('DB_DATABASE'),
        entities: [User, Profile, Accounting, Nas, ProfileFupTier],
        synchronize: true, // For development; use migrations for production
      }),
      inject: [ConfigService],
    }),
    TypeOrmModule.forFeature([User, Profile, Accounting, Nas]),
    RadiusModule,
    IntegrationModule,
    RouterModule.register([
      {
        path: 'api/v1/radius',
        module: RadiusModule,
      },
      {
        path: 'api/v1/resources',
        module: IntegrationModule,
      },
    ]),
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule { }
