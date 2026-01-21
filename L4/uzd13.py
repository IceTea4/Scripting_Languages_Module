#!/usr/bin/python3

# Naudojimas: python3 uzd13.py Kaunas

import sys
import requests
import json

def main():
    # Patikrinam, ar įvestas bent vienas argumentas
    if len(sys.argv) < 2:
        print("Naudojimas: python3 uzd13.py MIESTAS")
        sys.exit(1)

    # Vietovė iš argumento
    location = sys.argv[1]

    # API duomenys
    api_key = "2d351b25a5ec46fab0694510221411"
    url = "http://api.weatherapi.com/v1/current.json"

    # Parametrai užklausai
    params = {
        "key": api_key,
        "q": location
    }

    # GET užklausa
    r = requests.get(url=url, params=params)

    # Patikrinam status_code
    if r.status_code != 200:
        print("Rezultatai yra nepasiekiami:", r.status_code)
        sys.exit(1)

    # Gauta JSON informacija
    try:
        data = r.json()
    except:
        print("Nepavyko nuskaityti JSON duomenu")
        sys.exit(1)

    # Temperatūra current/temp_c
    temp_c = data["current"]["temp_c"]
    # Kada paskutinį kartą atnaujinta current/last_updated
    last_updated = data["current"]["last_updated"]

    print("Vietovė:", location)
    print("Temperatūra dabar (°C):", temp_c)
    print("Paskutinį kartą atnaujinta:", last_updated)

if __name__ == "__main__":
    main()
