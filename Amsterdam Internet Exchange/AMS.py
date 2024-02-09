# Import necessary modules
import sys
import requests
import re
from bs4 import BeautifulSoup

# Define the URL to scrape data from
url = "https://www.ams-ix.net/"
session = requests.Session()

# Set user-agent header for the request
header_get = {
    'User-Agent': 'DataMiner'
}

# Set headers for Data API request
header_params = {
    "identifier": 'ams-ix.net',
    "type": 'AMS Traffic',
}

# Mapping location codes to full location names
location_codes_to_location = {
    'ams':'Amsterdam',
    'bay':'Bay Area',
    'car':'Caribbean',
    'chi':'Chicago',
    'hk':'Hong Kong',
    'mum':'Mumbai',
}

# Function to retrieve data from a specific location
def retrieveValue(location_code):
    final_url = url + location_code
    response = session.get(final_url, headers=header_get)
    soup = BeautifulSoup(response.text, 'html.parser')
    return soup.find('div', class_='sc-iujRgT').find('div', class_='csSFRO').get_text().strip()

# Function to correct the numeric value and unit
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

# Function to create the JSON body for the API request
def createParamJsonBody(location, value):
    correctedValue = correctValue(value)
    return '''"{}":{}'''.format(
        location,
        correctedValue)

# Main execution block
if __name__ == '__main__':
    request_body = '{'
    indexer = 0
    # Iterate through location codes and retrieve values
    for code, location in location_codes_to_location.items():
        value = retrieveValue(code)
        # Create JSON body for each location
        request_body += createParamJsonBody(location, value)
        if(indexer < len(location_codes_to_location) - 1):
            request_body += ''',
'''
        indexer = indexer + 1
        
    request_body += '}'
    # Send the Data API request with the constructed JSON body
    session.put("http://localhost:34567/api/data/parameters", json=request_body, headers=header_params)
