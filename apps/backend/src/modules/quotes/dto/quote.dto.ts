import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  ArrayMaxSize, ArrayMinSize, IsArray, IsIn, IsNumber, IsOptional, IsString,
  IsUUID, MaxLength, Min, ValidateNested,
} from 'class-validator';

export class CreateQuoteItemDto {
  @ApiPropertyOptional() @IsOptional() @IsUUID() productId?: string;
  @ApiProperty() @IsString() @MaxLength(500) description!: string;
  @ApiProperty() @IsNumber() @Min(0.0001) quantity!: number;
  @ApiPropertyOptional({ default: 'units' }) @IsOptional() @IsString() @MaxLength(24) unit?: string;
  @ApiProperty() @IsNumber() @Min(0) unitPrice!: number;
}

export class CreateQuoteDto {
  @ApiProperty() @IsUUID() rfqId!: string;
  @ApiPropertyOptional({ default: 'USD' }) @IsOptional() @IsString() @MaxLength(8) currency?: string;
  @ApiPropertyOptional() @IsOptional() @IsNumber() @Min(0) shippingCost?: number;
  @ApiPropertyOptional({ enum: ['FOB', 'CIF', 'DDP', 'EXW'] }) @IsOptional() @IsIn(['FOB', 'CIF', 'DDP', 'EXW']) incoterm?: string;
  @ApiProperty({ description: 'ISO date the quote remains valid until' }) @IsString() validUntil!: string;
  @ApiPropertyOptional() @IsOptional() @IsString() @MaxLength(2000) notes?: string;
  @ApiProperty({ type: [CreateQuoteItemDto] })
  @IsArray() @ArrayMinSize(1) @ArrayMaxSize(100)
  @ValidateNested({ each: true }) @Type(() => CreateQuoteItemDto)
  items!: CreateQuoteItemDto[];
}

export class RejectQuoteDto {
  @ApiPropertyOptional() @IsOptional() @IsString() @MaxLength(1000) reason?: string;
}
