#!/usr/bin/perl
#
# smldump.pl
#
# Dump structure from a binary SML (Smart Message Language) file.
# SML is used in various smart metering systems in germany.
#
# QUICK AND DIRTY HACK STYLE
#
# (C) 2019 Hajo Noerenberg
#
# http://www.noerenberg.de/
# https://github.com/hn/smldump
#
# https://de.wikipedia.org/wiki/Smart_Message_Language
# https://www.bsi.bund.de/SharedDocs/Downloads/DE/BSI/Publikationen/TechnischeRichtlinien/TR03109/TR-03109-1_Anlage_Feinspezifikation_Drahtgebundene_LMN-Schnittstelle_Teilb.pdf?__blob=publicationFile&v=1
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 3.0 as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.txt>.
#

use strict;

my %obis = (
    "\x81\x81\xC7\x82\x03\xFF" => "Hersteller-Identifikation",
    "\x01\x00\x00\x00\x09\xFF" => "Server-Id / Geraeteeinzelidentifikation",
    "\x01\x00\x01\x08\x00\xFF" => "Aktueller Zaehlerstand",
    "\x01\x00\x01\x08\x01\xFF" => "Zaehlerstand zu Tarif 1",
    "\x01\x00\x01\x08\x02\xFF" => "Zaehlerstand zu Tarif 2",
    "\x01\x00\x0F\x07\x00\xFF" => "Betrag der aktuellen Wirkleistung",
    "\x81\x81\xC7\x82\x05\xFF" => "Public Key",
    "\x01\x00\x02\x08\x00\xFF" => "Wirkenergie Einspeisung gesamt tariflos",
    "\x01\x00\x02\x08\x01\xFF" => "Wirkenergie Einspeisung Tarif 1",
    "\x01\x00\x02\x08\x02\xFF" => "Wirkenergie Einspeisung Tarif 2",
);

my $buf;

open( SML, "<", $ARGV[0] ) || die( "Unable to open input file: " . $! );
binmode(SML);

read( SML, $buf, 4 );
printf( "%*v2.2X\n", " ", $buf );
die if ( $buf ne "\x1b\x1b\x1b\x1b" );		# Start escape sequence

read( SML, $buf, 4 );
printf( "%*v2.2X\n\n", " ", $buf );
die if ( $buf ne "\x01\x01\x01\x01" );		# SML Version 01

my @level = (0);

while ( read( SML, $buf, 1 ) ) {

    pop(@level) while ( @level && $level[-1] == 0 );
    last if ( !@level && ( $buf eq "\x1B" ) );	# First byte of end escape sequence
    $level[-1]-- if (@level);

    print " " x ( 4 * @level );
    printf( "%02X", ord($buf) );
    my $al = ord( $buf & "\x0F" ) - 1;

    if ( ( $buf & "\x80" ) eq "\x80" ) {       # Extended length
        read( SML, my $albuf, 1 );
        printf( "+%02X", ord($albuf) );
        die("Unsupported") if ( ord( $albuf & "\x70" ) );
        $al = ord( $buf & "\x0F" ) << 4 + ord( $albuf & "\x0F" ) - 2;
    }

    print ": ";

    if ( ( $buf & "\x70" ) eq "\x70" ) {       # List of
        push( @level, ord( $buf & "\x0F" ) );
    }
    elsif ( ( $buf & "\x7F" ) eq "\x00" ) {    # EndOfSmlMSg
        print "\n";
    }
    elsif ( ( $buf & "\x70" ) eq "\x00" ) {    # Octet String
        read( SML, $buf, $al );
        printf( "%*v2.2X", " ", $buf );
        print "\t# OBIS " . $obis{$buf} if ( $obis{$buf} );
    }
    elsif ( ( $buf & "\x70" ) eq "\x50" ) {    # IntegerX
        read( SML, $buf, $al );
        printf( "%*v2.2X", " ", $buf );
    }
    elsif ( ( $buf & "\x70" ) eq "\x60" ) {    # UnsignedX
        read( SML, $buf, $al );
        printf( "%*v2.2X", " ", $buf );
    }
    else {
        die("Unsupported");
    }

    print "\n";
}

printf( "%*v2.2X ", " ", $buf );
read( SML, $buf, 3 );
printf( "%*v2.2X\n", " ", $buf );
die if ( $buf ne "\x1b\x1b\x1b" );		# last three bytes of end escape sequence

read( SML, $buf, 4 );
printf( "%*v2.2X\n", " ", $buf );		# CRC-16/X-25

close(SML);
