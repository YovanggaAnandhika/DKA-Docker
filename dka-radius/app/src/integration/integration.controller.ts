import { Controller, Post, Get, Body, Param } from '@nestjs/common';
import { IntegrationService } from './integration.service';

@Controller()
export class IntegrationController {
    constructor(private readonly integrationService: IntegrationService) { }

    @Post('profiles')
    async createProfile(@Body() body: any) {
        return this.integrationService.createProfile(body);
    }

    @Post('users')
    async createUser(@Body() body: any) {
        return this.integrationService.createUser(body);
    }

    @Get('users')
    async listUsers() {
        return this.integrationService.listUsers();
    }

    @Get('users/:username/usage')
    async getUsage(@Param('username') username: string) {
        return this.integrationService.getUsage(username);
    }
}
