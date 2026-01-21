#!/usr/bin/perl -w

# Naudojimas:
#   perl uzd11.pl

my $log_failas = "/home/stud/stud/access_log";

open(my $FH, $log_failas) or die "Nepavyko atidaryti $log_failas: $!";

# Naudojam hash, kad IP nepasikartotų
my %ip_su_404;

while (my $eilute = <$FH>) {
    chomp $eilute;
    next if length($eilute) == 0;

    my @dalis = split(/\s+/, $eilute);

    my $ip     = $dalis[0];
    my $status = $dalis[-2];

    if ($status eq "404") {
        $ip_su_404{$ip} = 1;   # užtenka pažymėti, kad toks IP egzistuoja
    }
}

close($FH);

print "IP adresai, kurie gavo klaidos koda 404:\n";
foreach my $ip (sort keys %ip_su_404) {
    print "$ip\n";
}
