import { Test, TestingModule } from '@nestjs/testing';
import { RadiusController } from './radius.controller';

describe('RadiusController', () => {
  let controller: RadiusController;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [RadiusController],
    }).compile();

    controller = module.get<RadiusController>(RadiusController);
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });
});
