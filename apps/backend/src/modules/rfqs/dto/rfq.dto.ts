import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  ArrayMaxSize, ArrayMinSize, IsArray, IsBoolean, IsEmail, IsIn, IsNotEmpty,
  IsNumber, IsOptional, IsString, IsUUID, MaxLength, Min, MinLength, ValidateNested,
} from 'class-validator';

export class CreateRfqItemDto {
  @ApiPropertyOptional({ description: 'Catalogue product id (omit for custom "we source it" items)' })
  @IsOptional()
  @IsUUID()
  productId?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(160)
  customName?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(2000)
  customDetails?: string;

  @ApiProperty()
  @IsNumber()
  @Min(0.0001)
  quantity!: number;

  @ApiPropertyOptional({ default: 'units' })
  @IsOptional()
  @IsString()
  @MaxLength(24)
  unit?: string;
}

export class CreateRfqDto {
  @ApiProperty() @IsString() @IsNotEmpty() @MaxLength(120) contactName!: string;
  @ApiProperty() @IsEmail() contactEmail!: string;
  @ApiProperty() @IsString() @IsNotEmpty() @MaxLength(32) contactPhone!: string;

  @ApiProperty() @IsString() @IsNotEmpty() @MaxLength(80) destinationCountry!: string;
  @ApiPropertyOptional() @IsOptional() @IsString() @MaxLength(80) destinationCity?: string;
  @ApiPropertyOptional() @IsOptional() @IsString() @MaxLength(500) deliveryAddress?: string;

  @ApiPropertyOptional({ enum: ['buyer_freight', 'egt_turnkey_freight'] })
  @IsOptional()
  @IsIn(['buyer_freight', 'egt_turnkey_freight'])
  shippingPreference?: string;

  @ApiPropertyOptional({ default: 'USD' }) @IsOptional() @IsString() @MaxLength(8) currency?: string;
  @ApiPropertyOptional() @IsOptional() @IsNumber() @Min(0) budget?: number;
  @ApiPropertyOptional() @IsOptional() @IsNumber() @Min(0) targetPrice?: number;

  @ApiPropertyOptional({ default: false }) @IsOptional() @IsBoolean() privateLabel?: boolean;
  @ApiPropertyOptional() @IsOptional() @IsString() @MaxLength(200) packagingPreference?: string;

  @ApiProperty({ minLength: 15 }) @IsString() @MinLength(15) @MaxLength(5000) requirementDetails!: string;

  @ApiProperty({ type: [CreateRfqItemDto] })
  @IsArray() @ArrayMinSize(1) @ArrayMaxSize(50)
  @ValidateNested({ each: true }) @Type(() => CreateRfqItemDto)
  items!: CreateRfqItemDto[];
}

export class TransitionRfqDto {
  @ApiProperty({ enum: ['under_review','sourcing','supplier_matched','sample_discussion','quotation_ready','buyer_action_required','approved','order_processing','completed','closed'] })
  @IsIn(['under_review','sourcing','supplier_matched','sample_discussion','quotation_ready','buyer_action_required','approved','order_processing','completed','closed'])
  to!: string;
}
