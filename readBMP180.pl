#!/usr/bin/perl

# Copyright 2014 by Jason Seymour
# Rev 1.0

# This is a Perl script to read temperature and barometric
# pressure from an Adafruit BMP180 breakout board.

use Device::SMBus;
use Time::HeRes;


# Instantiate an SMBus object referring to the correct I2C bus
# and the device address of the sensor. The Adafruit BMP180
# sensor always has an address of 0x77. The rev2 RPi puts the
# primary I2C bus on i2c-1. The rev1 uses i2c-0.

my $bmp180 = Device::SMBus->new(
  I2CBusDevicePath => '/dev/i2c-1',
  I2CDeviceAddress => 0x77,
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

my $cal_AC1	= 0;
my $cal_AC2	= 0;
my $cal_AC3	= 0;
my $cal_AC4	= 0;
my $cal_AC5	= 0;
my $cal_AC6	= 0;
my $cal_B1	= 0;
my $cal_B2	= 0;
my $cal_MB	= 0;
my $cal_MC	= 0;
my $cal_MD	= 0;

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
	my $readValLo = $bmp180->readByteData($register+1);
	my $bufferHi = $readValHi & 0x7F;
	$bufferHi *= 256;
	my $buffer = $bufferHi + $readValLo;
	if ($readValHi & 0x80) {
		$buffer *= -1;
	}
	my $retVal = $buffer;
	return $retVal;
}

# Read the calibration data from the sensor's eeprom and store it locally

$cal_AC1 = readS16($bmp180,BMP180_CAL_AC1);
$cal_AC2 = readS16($bmp180,BMP180_CAL_AC2);
$cal_AC3 = readS16($bmp180,BMP180_CAL_AC3);
$cal_AC4 = $bmp180->readWordData(BMP180_CAL_AC4);
$cal_AC5 = $bmp180->readWordData(BMP180_CAL_AC5);
$cal_AC6 = $bmp180->readWordData(BMP180_CAL_AC6);
$cal_B1  = readS16($bmp180,BMP180_CAL_B1);
$cal_B2  = readS16($bmp180,BMP180_CAL_B2);
$cal_MB  = readS16($bmp180,BMP180_CAL_MB);
$cal_MC  = readS16($bmp180,BMP180_CAL_MC);
$cal_MD  = readS16($bmp180,BMP180_CAL_MD);

# DIAG: Print out the calibration data to validate that we're working up to this point
print "Calibration Data\n";
print "----------------\n";
printf "AC1 = %6d\n",$cal_AC1;
printf "AC2 = %6d\n",$cal_AC2;
printf "AC3 = %6d\n",$cal_AC3;
printf "AC4 = %6d\n",$cal_AC4;
printf "AC5 = %6d\n",$cal_AC5;
printf "AC6 = %6d\n",$cal_AC6;
printf "B1 = %6d\n",$cal_B1;
printf "B2 = %6d\n",$cal_B2;
printf "MB = %6d\n",$cal_MB;
printf "MC = %6d\n",$cal_MC;
printf "MD = %6d\n",$cal_MD;

# Read the raw (uncompensated) temperature from the sensor

sub readRawTemp {
	my $bmp180 = @_;
	$bmp180->writeByteData(BMP180_CONTROL,BMP180_READTEMPCMD);
	usleep(5);
	my $rawTemp = $bmp180->readWordData(BMP180_TEMPDATA);
	printf "Raw temperature value is 0x%04X (%d)\n", $rawTemp & 0xFFFF, $rawTemp;
	return $rawTemp;
}

# Read the raw (uncompensated) barometric pressure from the sensor

sub readRawPressure {
	my ($bmp180,$mode) = @_;
	my $writeVal = BMP180_READPRESSURECMD + ($mode << 6);
	$bmp180->writeByteData(BMP180_CONTROL,$writeVal);
	if ($mode == BMP180_ULTRALOWPOWER_ {
		usleep(5);
	}
	elseif ($mode == BMP180_HIRES) {
		usleep(14);
	}
	elseif ($mode == BMP180_ULTRAHIRES) {
		usleep(26);
	}
	else {
		usleep(8);
	}
	my $msb = $bmp180->readByteData(BMP180_PRESSUREDATA);
	my $lsb = $bmp180->readByteData(BMP180_PRESSUREDATA+);
	my $xlsb = $bmp180->readByteData(BMP180_PRESSUREDATA+2);
	my $rawPressure = (($msb << 16) + ($lsb << 8) + $xlsb) >> (8 - $mode);
	printf "Raw pressure value is 0x%04X (%d)\n", $rawPressure & 0xFFFF, $rawPressure;
	return $rawPressure;
}

# Read the compensated temperature

sub readTemp {
	my ($bmp180) = @_;
	my $UT = readRawTemp($bmp180);
	my $X1 = (($UT - $cal_AC6) * $cal_AC5) >> 15;
	my $X2 = ($cal_MC << 11) / ($X1 + $cal_MD);
	my $B5 = $X1 + $X2;
	my $temp = (($B5 + 8) >> 4) / 10.0;
	printf "Calibrated temperature = %f C\n", $temp;
	return $temp;
}

# Read the compansated barometric pressure

sub readPressure {
	my ($bmp180,$mode) = @_;
	my $UT = readRawTemp($bmp180);
	my $UP = readRawPressure($bmp180,$mode);

	# Calculate true temperature, but don't convert to simple output format yet
	my $X1 = (($UT - $cal_AC6) * $cal_AC5) >> 15;
	my $X2 = ($cal_MC << 11) / ($X1 + $cal_MD);
	my $B5 = $X1 + $X2;
	my $temp = (($B5 + 8) >> 4) / 10.0;
	printf "Calibrated temperature = %f C\n", $temp;

	# Calculate compensated pressure
	my $B6 = $B5 - 4000;
	$X1 = ($cal_B2 * ($B6 * $B6) >> 12) >> 11;
	$X2 = ($cal_AC2 * $B6) >> 11;
	my $X3 = $X1 + $X2;
	my $B3 = ((($cal_AC1 * 4 + $X3) << $mode) + 2) /4;
	$X1 = ($cal_AC3 * $B6) >> 13;
	$X2 = ($cal_B1 * (($B6 * $B6) >> 12 ) >> 16;
	$X3 = (($X1 + $X2) + 2) >> 2;
	my $B4 = ($cal_AC4 * ($X3 + 32768)) >> 15;
	my $B7 = ($UP - $B3) * (50000 >> $mode);
	my $p = 0;
	if ($B7 < 0x80000000) {
		$p = ($B7 * 2) / $B4;
	} else {
		$p = ($B7 / $B4) * 2;
	}
	$X1 = ($p >> 8) * ($p >> 8);
	$X1 = ($X1 * 3038) >> 16;
	$X2 = (-7357 * $p) >> 16;
	$p = $p + (($X1 + $X2 + 3791) >> 4);
	printf "Calibration pressure is %d Pa\n", $p;
	return $p;
}
