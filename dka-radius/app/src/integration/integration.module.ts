import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { IntegrationService } from './integration.service';
import { IntegrationController } from './integration.controller';
import { User } from '../database/entities/user.entity';
import { Profile } from '../database/entities/profile.entity';
import { Accounting } from '../database/entities/accounting.entity';

@Module({
  imports: [TypeOrmModule.forFeature([User, Profile, Accounting])],
  controllers: [IntegrationController],
  providers: [IntegrationService],
})
export class IntegrationModule { }
