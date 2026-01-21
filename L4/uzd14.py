#!/usr/bin/python3

# Naudojimas: python3 uzd14.py google.com

import sys
import csv

def load_ranking(filename):
    # Nuskaito csv failą ir grąžina žodyną {domenas: reitingas}.
    ranks = {}

    try:
        with open(filename, newline='', encoding='utf-8') as f:
            reader = csv.reader(f)
            for row in reader:
                # praleidžiam tuščias eilutes
                if not row:
                    continue

                # Dažniausiai būna: <reitingas,domenas>
                try:
                    rank = int(row[0])
                    domain = row[1].strip()
                except (ValueError, IndexError):
                    continue

                ranks[domain] = rank
    except FileNotFoundError:
        print("Nepavyko atidaryti failo:", filename)
        return None

    return ranks

def main():
    if len(sys.argv) < 2:
        print("Naudojimas: python3 uzd14.py DOMENAS")
        sys.exit(1)

    domain = sys.argv[1]

    tranco_file = "tranco-top-1m.csv"
    umbrella_file = "umbrella-top-1m.csv"

    tranco_ranks = load_ranking(tranco_file)
    umbrella_ranks = load_ranking(umbrella_file)
    
    if tranco_ranks is None and umbrella_ranks is None:
        print("Nepavyko įkelti nei Tranco, nei Umbrella reitingų duomenų.")
        sys.exit(1)

    print("Domenas:", domain)

    # Tranco
    if tranco_ranks is not None and domain in tranco_ranks:
        print("Tranco Top 1M reitingas:", tranco_ranks[domain])
    else:
        print("Tranco Top 1M: domenas nerastas arba duomenys neįkelti.")

    # Umbrella
    if umbrella_ranks is not None and domain in umbrella_ranks:
        print("Umbrella Top 1M reitingas:", umbrella_ranks[domain])
    else:
        print("Umbrella Top 1M: domenas nerastas arba duomenys neįkelti.")

if __name__ == "__main__":
    main()

