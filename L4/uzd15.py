#!/usr/bin/python3

# Naudojimas: python3 uzd15.py 193.219.32.13

import sys
import tarfile
import csv
import ipaddress
from io import TextIOWrapper

def load_ip_db(tar_path):
    # Nuskaito tar.gz archyvą ir grąžina visą CSV kaip sąrašą eilučių.
    rows = []
    
    try:
        file = tarfile.open(tar_path, "r:gz")
    except FileNotFoundError:
        print("Nepavyko atidaryti duomenų bazės failo:", tar_path)
        return None

    # Archyve gali būti ne vienas failas, todėl einame per visus
    for member in file.getmembers():
        # Mums reikia tik tikro failo, ne katalogo
        if member.isfile():
            f = file.extractfile(member)
            # csv.reader nori tekstinio failo, todėl darome TextIOWrapper
            csvreader = csv.reader(TextIOWrapper(f, 'utf-8'))
            for row in csvreader:
                # Kiekviena row yra [ip_pradzia, ip_pabaiga, salies_kodas]
                if row:
                    rows.append(row)
            break

    file.close()
    return rows

def find_country(ip_str, rows):
    # Paverčiam IPv4 string į int
    try:
        ip_num = int(ipaddress.IPv4Address(ip_str))
    except ipaddress.AddressValueError:
        print("Neteisingas IP adresas:", ip_str)
        return None

    # Nuosekli paieška per visą sąrašą
    for row in rows:
        ip_start_str = row[0]
        ip_end_str = row[1]
        country_code = row[2]

        # Konversija į int
        ip_start = int(ipaddress.IPv4Address(ip_start_str))
        ip_end = int(ipaddress.IPv4Address(ip_end_str))

        # Tikriname, ar mūsų IP patenka į šį rėžį
        if ip_start <= ip_num <= ip_end:
            return country_code

    return None

def main():
    if len(sys.argv) < 2:
        print("Naudojimas: python3 uzd15.py IP_ADRESAS")
        sys.exit(1)

    ip_str = sys.argv[1]

    # Kelias iki duomenų bazės failo
    tar_path = "/home/stud/stud/dbip-country-lite-2021-12.csv.tar.gz"

    # Nuskaitome duomenis
    rows = load_ip_db(tar_path)
    
    if rows is None:
        sys.exit(1)

    # Randame šalį
    country = find_country(ip_str, rows)

    print("IP adresas:", ip_str)
    if country is not None:
        print("Šalies kodas:", country)
    else:
        print("Šalis duomenų bazėje nerasta.")

if __name__ == "__main__":
    main()
