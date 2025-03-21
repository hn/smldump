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
    "\x00\x00\x60\x01\xFF\xFF" => "Seriennummer",
    "\x01\x00\x00\x00\x09\xFF" => "Server-Id / Geraeteeinzelidentifikation",
    "\x01\x00\x01\x08\x00\xFF" => "Zaehlwerk pos. Wirkenergie (Bezug), tariflos",
    "\x01\x00\x01\x08\x01\xFF" => "Zaehlwerk pos. Wirkenergie (Bezug), Tarif 1",
    "\x01\x00\x01\x08\x02\xFF" => "Zaehlwerk pos. Wirkenergie (Bezug), Tarif 2",
    "\x01\x00\x02\x08\x00\xFF" => "Zaehlwerk neg. Wirkenergie (Einspeisung), tariflos",
    "\x01\x00\x02\x08\x01\xFF" => "Zaehlwerk neg. Wirkenergie (Einspeisung), Tarif 1",
    "\x01\x00\x02\x08\x02\xFF" => "Zaehlwerk neg. Wirkenergie (Einspeisung), Tarif 2",
    "\x01\x00\x0F\x07\x00\xFF" => "Betrag der aktuellen Wirkleistung",
    "\x01\x00\x10\x07\x00\xFF" => "Aktuelle Wirkleistung gesamt",
    "\x01\x00\x24\x07\x00\xFF" => "Aktuelle Wirkleistung L1",
    "\x01\x00\x38\x07\x00\xFF" => "Aktuelle Wirkleistung L2",
    "\x01\x00\x4c\x07\x00\xFF" => "Aktuelle Wirkleistung L3",
    "\x01\x00\x60\x01\x00\xFF" => "Seriennummer aus 96.1.0",
    "\x01\x00\x60\x32\x01\x01" => "Hersteller-Id aus 96.50.1",
    "\x81\x81\xC7\x82\x03\xFF" => "Hersteller-Identifikation",
    "\x81\x81\xC7\x82\x05\xFF" => "Public Key",
    "\x01\x01\x01\x1D\x00\xFF" => "Viertelstundenwert RLM Wirkarbeit",
    "\x07\x14\x03\x00\x00\xFF" => "Gaszaehlerstand (Betriebsvolumen) Bezug",
    "\x07\x00\x34\x00\x26\xFF" => "Zustandszahl",
    "\x07\x00\x36\x00\x00\xFF" => "Gasbrennwert",
);

my %sml = (
    "\x01\x00" => "SML_PublicOpen.Req",
    "\x01\x01" => "SML_PublicOpen.Res",
    "\x02\x00" => "SML_PublicClose.Req",
    "\x02\x01" => "SML_PublicClose.Res",
    "\x03\x00" => "SML_GetProfilePack.Req",
    "\x03\x01" => "SML_GetProfilePack.Res",
    "\x04\x00" => "SML_GetProfileList.Req",
    "\x04\x01" => "SML_GetProfileList.Res",
    "\x05\x00" => "SML_GetProcParameter.Req",
    "\x05\x01" => "SML_GetProcParameter.Res",
    "\x07\x00" => "SML_GetList.Req",
    "\x07\x01" => "SML_GetList.Res",
    "\x08\x00" => "SML_GetCosem.Req",
    "\x08\x01" => "SML_GetCosem.Res",
    "\x09\x00" => "SML_SetCosem.Req",
    "\x09\x01" => "SML_SetCosem.Res",
    "\x0A\x00" => "SML_ActionCosem.Req",
    "\x0A\x01" => "SML_ActionCosem.Res",
    "\xFF\x01" => "SML_Attention.Res",
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
    elsif ( ( $buf & "\x70" ) eq "\x40" ) {    # Boolean
        read( SML, $buf, $al );
        printf( "%*v2.2X", " ", $buf );
    }
    elsif ( ( $buf & "\x70" ) eq "\x50" ) {    # IntegerX
        read( SML, $buf, $al );
        printf( "%*v2.2X", " ", $buf );
    }
    elsif ( ( $buf & "\x70" ) eq "\x60" ) {    # UnsignedX
        read( SML, $buf, $al );
        printf( "%*v2.2X", " ", $buf );
        print "\t# " . $sml{$buf} if ( $sml{$buf} );
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
