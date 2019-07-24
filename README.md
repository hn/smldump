# smldump

Dump structure from a binary SML (Smart Message Language) file. SML is used in various smart metering (electricity, gas, water ...) systems in germany. As of now, the script also parses a small selection of OBIS (Object Identification System) classification numbers.

## Usage

```
$ smldump.pl /tmp/smartmeterblob.bin
1B 1B 1B 1B
01 01 01 01

76: 
    05: 00 01 41 A9
    62: 00
    62: 00
    72: 
        63: 01 01
        76: 
            01: 
            01: 
            05: 00 00 6B 39
            0B: 09 01 49 53 12 34 56 78 9A BC
            01: 
            01: 
    63: 91 7E
    00: 

76: 
    05: 00 01 41 AA
    62: 00
    62: 00
    72: 
        63: 07 01
        77: 
            01: 
            0B: 09 01 49 53 12 34 56 78 9A BC
            07: 01 00 62 0A FF FF
            72: 
                62: 01
                65: 00 00 98 F7
            79: 
                77: 
                    07: 81 81 C7 82 03 FF       # OBIS Hersteller-Identifikation
                    01: 
                    01: 
                    01: 
                    01: 
                    04: 49 53 4B
                    01: 
                77: 
                    07: 01 00 00 00 09 FF       # OBIS Server-Id / Geraeteeinzelidentifikation
                    01: 
                    01: 
                    01: 
                    01: 
                    0B: 09 01 49 53 12 34 56 78 9A BC
                    01: 
                77: 
                    07: 01 00 01 08 00 FF       # OBIS Aktueller Zaehlerstand
                    65: 00 01 01 82
                    01: 
                    62: 1E
                    52: 03
                    69: 00 00 00 00 00 00 00 08
                    01: 
                77: 
                    07: 01 00 01 08 01 FF       # OBIS Zaehlerstand zu Tarif 1
                    01: 
                    01: 
                    62: 1E
                    52: 03
                    69: 00 00 00 00 00 00 00 08
                    01: 
[...]
```
