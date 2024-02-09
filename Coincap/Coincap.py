# Import necessary modules 
import sys
import requests

# Recursive function to convert strings to floats in a JSON object
def convert_strings_to_floats(json_obj):
    if isinstance(json_obj, dict):
        for key, value in json_obj.items():
            json_obj[key] = convert_strings_to_floats(value)
    elif isinstance(json_obj, list):
        for i in range(len(json_obj)):
            json_obj[i] = convert_strings_to_floats(json_obj[i])
    elif isinstance(json_obj, str):
        try:
            return float(json_obj)
        except ValueError:
            return json_obj
    return json_obj
    
# Main function to execute the script
def main():
    
   # Set headers for Data API request
    header_params = {
        "identifier": 'coincap.io tracker',
        "type": 'Crypto Assets Tracker',
    }
 
    # Print header parameters for reference
    print(header_params)

    # Create a session for HTTP requests
    session = requests.Session()

    # Make a GET request to coincap API and convert response to floats
    coincapResponse = session.get("https://api.coincap.io/v2/assets")
    body = convert_strings_to_floats(coincapResponse.json())

    # Send the Data API request with the converted body
    session.put("http://localhost:34567/api/data/parameters", json=body, headers=header_params)

if __name__ == "__main__":
    main()
