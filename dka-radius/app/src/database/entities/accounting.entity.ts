import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn } from 'typeorm';

@Entity('accounting')
export class Accounting {
    @PrimaryGeneratedColumn()
    id: number;

    @Column({ name: 'acct_session_id', unique: true })
    acct_session_id: string;

    @Column({ name: 'user_name' })
    user_name: string;

    @Column({ name: 'nas_ip_address', nullable: true })
    nas_ip_address: string;

    @Column({ name: 'acct_status_type', nullable: true })
    acct_status_type: string;

    @Column({ type: 'bigint', name: 'acct_input_octets', default: 0 })
    acct_input_octets: bigint;

    @Column({ type: 'bigint', name: 'acct_output_octets', default: 0 })
    acct_output_octets: bigint;

    @Column({ name: 'acct_session_time', default: 0 })
    acct_session_time: number;

    @Column({ type: 'jsonb', nullable: true })
    raw_attributes: any;

    @CreateDateColumn()
    created_at: Date;
}
