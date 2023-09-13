import sys
import requests
import re
from bs4 import BeautifulSoup

url = "https://www.ams-ix.net/"
session = requests.Session()

element_name = ""
if len(sys.argv) >= 2:
    element_name = sys.argv[1]

if element_name == '':
    element_name = 'ams-ix.net'

header_get = {
    'User-Agent': 'DataMiner'
}

header_params = {
    "identifier": element_name,
    "type": 'AMS Traffic',
}

location_codes_to_location = {
    'ams':'Amsterdam',
    'bay':'Bay Area',
    'car':'Caribbean',
    'chi':'Chicago',
    'hk':'Hong Kong',
    'mum':'Mumbai',
}

def retrieveValue(location_code):
    final_url = url + location_code
    response = session.get(final_url, headers=header_get)
    soup = BeautifulSoup(response.text, 'html.parser')
    return soup.find('div', class_='sc-iujRgT').find('div', class_='csSFRO').get_text().strip()

def correctValue(value):
    match = re.match(r'([\d.]+)\s+(\w+)/s', value)
    if match:
        numeric_value = float(match.group(1))  # Extract and convert the numeric value to float
        unit = match.group(2)  # Extract the unit

        if unit == 'Tb':
            numeric_value *= 1000

        # Print the results
        print("Numeric Value:", numeric_value)
        print("Unit:", unit)
        return numeric_value
    else:
        print("No match found in the input string.")
        return 0

def createParamJsonBody(location, value):
    correctedValue = correctValue(value)
    return '''"{}":{}'''.format(
        location,
        correctedValue)

if __name__ == '__main__':
    request_body = '{'
    indexer = 0
    for code, location in location_codes_to_location.items():
        value = retrieveValue(code)
        request_body += createParamJsonBody(location, value)
        if(indexer < len(location_codes_to_location) - 1):
            request_body += ''',
'''
        indexer = indexer + 1
        
    request_body += '}'
    session.put("http://localhost:34567/api/data/parameters", json=request_body, headers=header_params)