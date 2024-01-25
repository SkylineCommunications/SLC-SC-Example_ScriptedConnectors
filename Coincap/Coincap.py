import sys
import requests

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
    
def main(argv):
    identifier = "coincap.io tracker"
    type = "Crypto Assets Tracker"

    header_params = {
        "identifier": identifier,
        "type": type,
    }

    n = len(argv)
    if(n >= 2):
        header_params = {
            "identifier": argv[0],
            "type": argv[1],
        }    

    print(header_params)
    session = requests.Session()

    coincapResponse = session.get("https://api.coincap.io/v2/assets")
    body = convert_strings_to_floats(coincapResponse.json())
    
    session.put("http://localhost:34567/api/data/parameters", json=body, headers=header_params)

if __name__ == "__main__":
    main(sys.argv[1:])