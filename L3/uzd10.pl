#!/usr/bin/perl -w

# Naudojimas:
#   perl uzd10.pl
#   perl uzd10.pl 10.0.0.153

my $log_failas = "/home/stud/stud/access_log";

my $ieskomas_ip = shift @ARGV;

open(my $FH, $log_failas) or die "Nepavyko atidaryti $log_failas: $!";

# jei argumentas YRA – naudosim paprastus skaliarus
my $irasu_kiekis = 0;
my $baitu_suma   = 0;

# jei argumento NĖRA – naudosim atvaizdžius
my %ip_irasu_kiekis;   # IP -> kiek įrašų
my %ip_baitu_suma;     # IP -> sėkmingų (200) baitų suma

while (my $eilute = <$FH>) {
    chomp $eilute;
    next if length($eilute) == 0;

    my @dalis = split(/\s+/, $eilute);

    my $ip      = $dalis[0];
    my $status  = $dalis[-2];
    my $baitai  = $dalis[-1];

    if (defined $ieskomas_ip) {
        # REŽIMAS: filtruojam konkretų IP (kaip uzd9.pl)
        next unless $ip eq $ieskomas_ip;

        $irasu_kiekis++;

        if ($baitai ne "-") {
            $baitu_suma += $baitai;
        }
    } else {
        # REŽIMAS: be argumento – kaupiam statistiką visiems IP
        $ip_irasu_kiekis{$ip}++;

        # skaičiuojam tik jei statusas 200 ir baitai ne "-"
        if ($status eq "200" && $baitai ne "-") {
            $ip_baitu_suma{$ip} += $baitai;
        }
    }
}

close($FH);

if (defined $ieskomas_ip) {

    # kaip uzd9.pl – į failą "rez"
    open(my $OUT, ">rez") or die "Nepavyko atidaryti rez: $!";
    print $OUT "IP adresas: $ieskomas_ip\n";
    print $OUT "Irasu kiekis: $irasu_kiekis\n";
    print $OUT "Perduotu baitu suma: $baitu_suma\n";
    close($OUT);

} else {

    # Be argumento – spausdinam visų IP lentelę į ekraną
    print "IP_adresas\tirasu_kiekis\tsekmingi_baitai(statusas_200)\n";

    # kad būtų tvarkinga – surikiuojam pagal IP
    foreach my $ip (sort keys %ip_irasu_kiekis) {
        my $kiekis = $ip_irasu_kiekis{$ip};
        my $baitai = $ip_baitu_suma{$ip} || 0;
        print "$ip\t$kiekis\t$baitai\n";
    }
}
