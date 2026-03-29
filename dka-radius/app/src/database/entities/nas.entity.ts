import { Entity, PrimaryGeneratedColumn, Column } from 'typeorm';

@Entity('nas')
export class Nas {
    @PrimaryGeneratedColumn()
    id: number;

    @Column({ unique: true })
    nasname: string; // IP or hostname

    @Column()
    secret: string;

    @Column({ nullable: true })
    shortname: string;

    @Column({ nullable: true })
    type: string;

    @Column({ nullable: true })
    description: string;
}
