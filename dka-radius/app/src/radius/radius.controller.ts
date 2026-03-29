import { Controller, Post, Body, HttpCode, HttpStatus } from '@nestjs/common';
import { RadiusService } from './radius.service';

@Controller()
export class RadiusController {
    constructor(private readonly radiusService: RadiusService) { }

    @Post('authorize')
    @HttpCode(HttpStatus.NO_CONTENT)
    async authorize(@Body() body: any) {
        return this.radiusService.authorize(body);
    }

    @Post('authenticate')
    async authenticate(@Body() body: any) {
        return this.radiusService.authenticate(body);
    }

    @Post('accounting')
    @HttpCode(HttpStatus.CREATED)
    async accounting(@Body() body: any) {
        return this.radiusService.accounting(body);
    }

    @Post('client') // For dynamic client lookup (optional, if using same base path)
    async lookupNas(@Body() body: any) {
        return this.radiusService.lookupNas(body);
    }
}

@Controller('nas') // Will be /api/v1/radius/nas
export class NasController {
    constructor(private readonly radiusService: RadiusService) { }

    @Post()
    async lookupNas(@Body() body: any) {
        return this.radiusService.lookupNas(body);
    }
}
