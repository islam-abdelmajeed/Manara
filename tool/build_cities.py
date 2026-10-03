"""Builds assets/data/cities.json from GeoNames (CC BY 4.0).

Inputs (from https://download.geonames.org/export/dump/), in one folder:
  cities15000.txt, countryInfo.txt, alternateNamesV2.txt

Usage:
  python tool/build_cities.py <geonames-folder>

Selection rules:
  - Egypt: the capital and every governorate capital (PPLC, PPLA).
  - Palestine: every city of at least 100,000 people.
  - Other Arab League members: the capital and cities of 1,000,000+.
  - Other OIC members: the capital and cities of 3,000,000+.
  - China, India: the capital only.
  - Elsewhere: capitals of countries of 20,000,000+ and cities of 8,000,000+.

Arabic names are GeoNames' `ar` alternate names (preferred, then short,
skipping colloquial and historic). NAME_OVERRIDES replace the few that are
missing or not the common form; DROP removes districts of listed cities.
"""

import json
import sys
from collections import defaultdict
from pathlib import Path

ARAB_LEAGUE = {
    'EG', 'SA', 'AE', 'KW', 'QA', 'BH', 'OM', 'YE', 'IQ', 'SY', 'LB', 'JO',
    'PS', 'SD', 'LY', 'TN', 'DZ', 'MA', 'MR', 'SO', 'DJ', 'KM',
}
# OIC members that are not in the Arab League.
OIC_OTHER = {
    'AF', 'AL', 'AZ', 'BD', 'BJ', 'BN', 'BF', 'CM', 'TD', 'CI', 'GA', 'GM',
    'GN', 'GW', 'GY', 'ID', 'IR', 'KZ', 'KG', 'MY', 'MV', 'ML', 'MZ', 'NE',
    'NG', 'PK', 'SN', 'SL', 'SR', 'TJ', 'TG', 'TR', 'TM', 'UG', 'UZ',
}

# GeoNames id -> Arabic name. "(GeoNames)" marks a name taken from GeoNames'
# own alternatives instead of its first choice; the rest have no usable
# Arabic name in GeoNames.
NAME_OVERRIDES = {
    292672: 'الشارقة',  # (GeoNames) instead of "إمارة الشارقة"
    361055: 'الإسماعيلية',  # (GeoNames) instead of "مدينة الإسماعيلية"
    359796: 'السويس',  # (GeoNames) instead of "سويس"
    360761: 'المنصورة',  # (GeoNames) instead of "منصورة"
    359678: 'الطور',  # (GeoNames) instead of the Latin "Aţ Ţūr"
    99532: 'البصرة',  # (GeoNames) instead of "بصرة"
    2538475: 'الرباط',  # (GeoNames) instead of "رباط"
    109223: 'المدينة المنورة',  # (GeoNames) instead of "المدينة"
    379251: 'الخرطوم بحري',  # (GeoNames) instead of "بحري"
    2210247: 'طرابلس',  # (GeoNames) without diacritics
    3378644: 'جورج تاون',  # (GeoNames) instead of "جورج توغن"
    1261481: 'نيودلهي',  # (GeoNames) instead of "دلهي الجديدة"
    2409306: 'فريتاون',  # (GeoNames) instead of "فريتون"
    379252: 'الخرطوم',  # GeoNames has "خرطوم" and a misspelling
    2422465: 'كوناكري',
    1526273: 'أستانا',
    6611854: 'نايبيداو',
    1282027: 'ماليه',
    1221874: 'دوشنبه',
    4140963: 'واشنطن',
}

COUNTRY_OVERRIDES = {
    'MM': 'ميانمار',  # GeoNames: "ميانمار (بورما)"
}

# Districts of cities already listed.
DROP = {
    268743,  # Ra's Bayrut (Beirut)
    99071,  # Al Mawsil al Jadidah (Mosul)
    7802746,  # Sadr City (Baghdad)
}


def selected(city, countries):
    cc, fcode, pop = city['cc'], city['fcode'], city['pop']
    if cc == 'EG':
        return fcode in ('PPLC', 'PPLA')
    if cc == 'PS':
        return pop >= 100_000
    if cc in ARAB_LEAGUE:
        return fcode == 'PPLC' or pop >= 1_000_000
    if cc in OIC_OTHER:
        return fcode == 'PPLC' or pop >= 3_000_000
    if cc in ('CN', 'IN'):
        return fcode == 'PPLC'
    return (fcode == 'PPLC' and countries[cc]['pop'] >= 20_000_000) or (
        pop >= 8_000_000
    )


def main(folder):
    folder = Path(folder)
    countries = {}
    for line in open(folder / 'countryInfo.txt', encoding='utf8'):
        if line.startswith('#'):
            continue
        f = line.rstrip('\n').split('\t')
        countries[f[0]] = {'pop': int(f[7] or 0), 'gid': int(f[16])}

    cities = []
    for line in open(folder / 'cities15000.txt', encoding='utf8'):
        f = line.rstrip('\n').split('\t')
        city = {
            'id': int(f[0]),
            'nameEn': f[1],
            'lat': float(f[4]),
            'lng': float(f[5]),
            'fcode': f[7],
            'cc': f[8],
            'pop': int(f[14] or 0),
            'tz': f[17],
        }
        if city['id'] not in DROP and selected(city, countries):
            cities.append(city)

    wanted = {c['id'] for c in cities} | {
        countries[c['cc']]['gid'] for c in cities
    }
    names = defaultdict(list)
    with open(folder / 'alternateNamesV2.txt', encoding='utf8') as f:
        for line in f:
            p = line.rstrip('\n').split('\t')
            if p[2] == 'ar' and int(p[1]) in wanted:
                if p[6] == '1' or p[7] == '1':  # colloquial, historic
                    continue
                names[int(p[1])].append((p[4] != '1', p[5] != '1', p[3]))

    def arabic(gid):
        options = sorted(names.get(gid, []))
        return options[0][2] if options else None

    out = []
    for c in sorted(cities, key=lambda c: (c['cc'], -c['pop'])):
        name = NAME_OVERRIDES.get(c['id']) or arabic(c['id'])
        country = COUNTRY_OVERRIDES.get(c['cc']) or arabic(
            countries[c['cc']]['gid']
        )
        if not name or not country:
            raise SystemExit(f'no Arabic name for {c["nameEn"]} ({c["id"]})')
        out.append({
            'id': c['id'],
            'name': name,
            'nameEn': c['nameEn'],
            'country': country,
            'countryCode': c['cc'],
            'lat': c['lat'],
            'lng': c['lng'],
            'timeZone': c['tz'],
        })

    target = Path(__file__).resolve().parent.parent / 'assets/data/cities.json'
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(
        json.dumps(out, ensure_ascii=False, indent=1) + '\n', encoding='utf8'
    )
    print(f'{len(out)} cities -> {target}')


if __name__ == '__main__':
    main(sys.argv[1])
