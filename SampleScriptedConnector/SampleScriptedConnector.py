# Import necessary modules 
import sys
import os
import json
import requests

    
# Main function to execute the script
def main():

    # Define authentication and host details
    bearer ='Ahy+7XhvW6FhRZKb1KYxvzOdrh9TARCdALmyuPtidTo='    
    host ='ziine.dataminer.services'
   
    # Define URL parameters for the Data API request
    url_params = {
        "identifier": 'DeviceIdentifier', #e.g., Sensor001
        "type": 'DeviceType', #e.g., Sensor, Actuator
    }

   # Set HTTP headers for Data API request
    header_params = {
        "Authorization": 'Bearer ' + bearer,
        "Content-Type": 'application/json',        
    }
 
    # Print header parameters for reference
    print(header_params)   

    # Create a session for HTTP requests
    session = requests.Session()

    # Prepare body as a JSON-serializable object
    body = { "Voltage": 0.1 }

    # Send the Data API request and capture the response
    try:
        response = session.put(
            "https://{}/api/custom/data/parameters?identifier={}&type={}".format(host, url_params["identifier"], url_params["type"]),
            json=body,
            headers=header_params,                    
        )

        print("PUT status:", response.status_code)      

     
    except requests.exceptions.RequestException as e:
        print("HTTP request failed:", e)
        sys.exit(1)

if __name__ == "__main__":
    main()
