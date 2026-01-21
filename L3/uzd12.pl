#!/usr/bin/perl -w

# Naudojimas:
#   perl uzd12.pl /home/stud 100000

my $pagrindinis_katalogas = shift @ARGV;
my $riba = shift @ARGV;

if ( !defined $pagrindinis_katalogas || !defined $riba ) {
    die "Naudojimas: $0 KATALOGAS RIBA_BAITAIS\n";
}

# Patikrinam, ar riba yra skaičius
if ( $riba !~ /^\d+$/ ) {
    die "Riba turi būti teigiamas skaičius (baitais)\n";
}

opendir(my $DIR, $pagrindinis_katalogas)
    or die "Nepavyko atidaryti katalogo $pagrindinis_katalogas: $!";

# Čia saugosim info apie kiekvieną sub-katalogą:
# katalogas -> { total_size => ..., files => [ [failas, dydis], ... ] }
my %katalogai;

while (my $entry = readdir($DIR)) {

    # praleidžiame "." ir ".."
    next if $entry eq "." || $entry eq "..";

    my $pilnas_kelias = "$pagrindinis_katalogas/$entry";

    # domina tik katalogai
    if ( -d $pilnas_kelias ) {

        opendir(my $SUB, $pilnas_kelias)
            or next; # jei negalim atidaryti – praleidžiam

        my $total_size = 0;
        my @files_info;  # [ [failo_vardas, dydis], ... ]

        while (my $f = readdir($SUB)) {
            next if $f eq "." || $f eq "..";

            my $failo_kelias = "$pilnas_kelias/$f";

            # užduotyje sakoma, kad kataloge nėra kitų katalogų,
            # bet dėl saugumo – praleidžiam, jei tai katalogas
            next if -d $failo_kelias;

            my @stat = stat($failo_kelias);
            my $size = $stat[7]; # 8-as elementas – failo dydis baitais

            $total_size += $size;

            push @files_info, [ $f, $size ];
        }

        closedir($SUB);

        $katalogai{$entry} = {
            total_size => $total_size,
            files      => \@files_info,
        };
    }
}

closedir($DIR);

# Dabar spausdinam tik tuos katalogus, kurių dydis > riba
foreach my $kat (sort keys %katalogai) {
    my $info = $katalogai{$kat};
    my $size = $info->{total_size};

    next if $size <= $riba;

    print "Katalogas: $kat  (viso baitu: $size)\n";

    # Rikiuojam failus pagal dydį (nuo didžiausio)
    my @failai = @{ $info->{files} };
    @failai = sort { $b->[1] <=> $a->[1] } @failai;

    print "  5 didžiausi failai:\n";

    my $kiek_rodyti = @failai < 5 ? scalar @failai : 5;

    for (my $i = 0; $i < $kiek_rodyti; $i++) {
        my ($vardas, $dydis) = @{$failai[$i]};
        print "    $vardas ($dydis baitu)\n";
    }

    print "\n";
}
