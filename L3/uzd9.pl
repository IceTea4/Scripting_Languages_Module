#!/usr/bin/perl -w

# Naudojimas:
#   perl uzd9.pl 10.0.0.153
#
# Argumentas: IP adresas

my $log_failas = "/home/stud/stud/access_log";

# paimame IP iš argumentų
my $ieskomas_ip = shift @ARGV;

if ( !defined $ieskomas_ip ) {
    die
}

open(my $FH, $log_failas) or die "Nepavyko atidaryti $log_failas: $!";

my $irasu_kiekis = 0;
my $baitu_suma   = 0;

while (my $eilute = <$FH>) {
    chomp $eilute;

    # praleidžiam tuščias eilutes
    next if length($eilute) == 0;

    # suskaidom eilutę per tarpus
    my @dalis = split(/\s+/, $eilute);

    # pirmas elementas – IP adresas
    my $ip = $dalis[0];

    # priešpaskutinis ir paskutinis elementai – statuso kodas ir baitai
    my $baitai   = $dalis[-1];

    if ($ip eq $ieskomas_ip) {
        $irasu_kiekis++;

        # jei baitų lauke ne "-" – pridedam
        if ($baitai ne "-") {
            $baitu_suma += $baitai;
        }
    }
}

close($FH);

# Rezultatą rašome į failą "rez"
open(my $OUT, ">rez") or die "Nepavyko atidaryti rez: $!";
print $OUT "IP adresas: $ieskomas_ip\n";
print $OUT "Irasu kiekis: $irasu_kiekis\n";
print $OUT "Perduotu baitu suma: $baitu_suma\n";
close($OUT);
