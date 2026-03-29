import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { RadiusService } from './radius.service';
import { RadiusController, NasController } from './radius.controller';
import { CoaService } from './coa.service';
import { User } from '../database/entities/user.entity';
import { Profile } from '../database/entities/profile.entity';
import { Accounting } from '../database/entities/accounting.entity';
import { Nas } from '../database/entities/nas.entity';

@Module({
  imports: [TypeOrmModule.forFeature([User, Profile, Accounting, Nas])],
  controllers: [RadiusController, NasController],
  providers: [RadiusService, CoaService],
  exports: [RadiusService],
})
export class RadiusModule { }
