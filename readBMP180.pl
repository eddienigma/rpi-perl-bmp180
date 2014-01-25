#!/usr/bin/perl

# Copyright 2014 by Jason Seymour
# Rev 1.0

# This is a Perl script to read temperature and barometric
# pressure from an Adafruit BMP180 breakout board.

use Device::SMBus;


# Instantiate an SMBus object referring to the correct I2C bus
# and the device address of the sensor. The Adafruit BMP180
# sensor always has an address of 0x77. The rev2 RPi puts the
# primary I2C bus on i2c-1. The rev1 uses i2c-0.

my $bmp180 = Device::SMBus->new(
  I2CBusDevicePath => '/dev/i2c-1',
  I2CDeviceAddress => 0x77
);

# Define a standard list of operating modes for the sensor.
# These control the number of samples per second that the 
# sensor takes internally.

use constant BMP180_ULTRALOWPOWER	=> 0;
use constant BMP180_STANDARD		=> 1;
use constant BMP180_HIRES		=> 2;
use constant BMP180_ULTRAHIRES		=> 3;

# Define the sensor registers. Many of these store calibration data
# which is used to calculate temperature compensated pressure readings.

use constant BMP180_CAL_AC1		=> 0xAA;	# Calibration data (16 bit)
use constant BMP180_CAL_AC2		=> 0xAC;	# Calibration data (16 bit) 
use constant BMP180_CAL_AC3		=> 0xAE;	# Calibration data (16 bit)
use constant BMP180_CAL_AC4		=> 0xB0;	# Calibration data (16 bit)
use constant BMP180_CAL_AC5		=> 0xB2;	# Calibration data (16 bit)
use constant BMP180_CAL_AC6		=> 0xB4;	# Calibration data (16 bit)
use constant BMP180_CAL_B1		=> 0xB6;	# Calibration data (16 bit)
use constant BMP180_CAL_B2		=> 0xB8;	# Calibration data (16 bit)
use constant BMP180_CAL_MB		=> 0xBA;	# Calibration data (16 bit)
use constant BMP180_CAL_MC		=> 0xBC;	# Calibration data (16 bit)
use constant BMP180_CAL_MD		=> 0xBE;	# Calibration data (16 bit)
use constant BMP180_CONTROL		=> 0xF4;
use constant BMP180_TEMPDATA		=> 0xF6;
use constant BMP180_PRESSUREDATA	=> 0xF6;
use constant BMP180_READTEMPCMD		=> 0x2E;
use constant BMP180_READPRESSURECMD	=> 0x34;

# Define a list of variables to store the calibration data into.

my cal_AC1	= 0;
my cal_AC2	= 0;
my cal_AC3	= 0;
my cal_AC4	= 0;
my cal_AC5	= 0;
my cal_AC6	= 0;
my cal_B1	= 0;
my cal_B2	= 0;
my cal_MB	= 0;
my cal_MC	= 0;
my cal_MD	= 0;

# The Device::SMBus module provides methods for reading 8 and 16 bit values
# from the sensor, but these methods don't differentiate between signed and
# unsigned values. We need to create our own functions to read signed values
# and handle them correctly.

sub readS8 {
	my ($bmp180,$register) = @_;
	my $readVal = $bmp180->readByteData($register);
	if($readVal > 127) {
		$readVal -= 256;
	}
	return $readVal;
}

sub readS16 {
	my ($bmp180,$register) = @_;
	my $readValHi = $bmp180->readByteData($register);
	if($readValHi > 127) {
                $readValHi -= 256;
        }
	my $readValLo = $bmp180->readByteData($register+1);
	my $retVal = ($readValHi << 8) + $readValLo;
	return $retVal;
}

# Read the calibration data from the sensor's eeprom and store it locally

cal_AC1 = readS16($bmp180,BMP180_CAL_AC1);
cal_AC2 = readS16($bmp180,BMP180_CAL_AC2);
cal_AC3 = readS16($bmp180,BMP180_CAL_AC3);
cal_AC4 = readS16($bmp180,BMP180_CAL_AC4);
cal_AC5 = readS16($bmp180,BMP180_CAL_AC5);
cal_AC6 = readS16($bmp180,BMP180_CAL_AC6);
cal_B1  = readS16($bmp180,BMP180_CAL_B1);
cal_B2  = readS16($bmp180,BMP180_CAL_B2);
cal_MB  = readS16($bmp180,BMP180_CAL_MB);
cal_MC  = readS16($bmp180,BMP180_CAL_MC);
cal_MD  = readS16($bmp180,BMP180_CAL_MD);

