# Amsterdam Internet Exchange

This scripted connector scrapes data from the AMS-IX website (https://www.ams-ix.net/) for various locations, including Amsterdam, Bay Area, Caribbean, Chicago, Hong Kong, and Mumbai. It then sends the collected data to a Data API. 

The script utilizes the BeautifulSoup library to parse the HTML, retrieves specific data from each location, corrects numeric values and units, and finally constructs a JSON body for the API request. 

The locations are mapped to their respective codes, and the script iterates through them to compile the necessary information before sending it to the Data API endpoint.
