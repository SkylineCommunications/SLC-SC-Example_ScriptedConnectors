# Advanced Exercise

## Polling the data

Create a data source to poll the status of a networking device

1. Open the Data Sources module:
   1. In DataMiner Cube, click Apps in the sidebar to the left and select Data Sources,
1. Click Create Data Source.
1. Configure the Data source name field with an identifiable name (e.g. Router Status) and ensure the Type is set to Python.
1. Create Python script that
   1. fetches the response from the URL <https://routersimulation.azurewebsites.net/RouterStatus>
   1. pushes data to DataMiner with **identifier** = Lab router and **type** = Router Status;

```python

import requests

def main():
    # Use this boiler plate code but fill in the URL, type and identifier

    # Define header parameters for the request to the local API
    header_params = {
        "identifier": , 
        "type":,
    }
    
    # Create a session object to manage and persist settings across requests
    session = requests.Session()

    # Send a GET request to the status API to get the current status in JSON format
    status = session.get("url")
    
    
    # Send a PUT request to the local Data API with the status data
    # Include the header parameters for additional context
    session.put("http://localhost:34567/api/data/parameters", json=status.json(), headers=header_params) 

# Execute the main function when the script is run
if __name__ == "__main__":
    main()

```

- [] Locate the newly created element in the Surveyor.
- [] Verify that the element is being populated with data.

## Configure units and precision

1. Create a data source that will configure the decimal precision & units for the parameters in the following way.
1. Configure the Data source name field with an identifiable name (e.g. Units & decimal precision) and ensure the Type is set to Python.
1. Create Python script that
   1. pushes the decimal and unit configuration
   1. uses the **type** = Router Status.  

```python


import requests

def main():
   # Use this boiler plate code but fill in the URL, type and identifier

    # Define header parameters for the request to the local API
    header_params = {
       "type": "Router Status",
    }
    
    # Create a session object to manage and persist settings across requests
    session = requests.Session()
    
# Configuration to change units and decimal precision    
config = {
        "decimals": {
            "cpuUtilization": 2,
            "Temperature": 2
        },
        "units": {
            "cpuUtilization": "%",
            "Temperature": "deg C",
            "memoryUsage": "%",
            "Fans": [
                {"Speed": "RPM"}
            ],
            "Interfaces": [
                {"Speed": "Mbps"}
            ]
        }
    }

   
    # Send a PUT request to the local Data API with the status data
    # Include the header parameters for additional context
    session.put("http://localhost:34567/api/config", json=config, headers=header_params) 

# Execute the main function when the script is run
if __name__ == "__main__":
    main()


```

Earn 25 DevOps points by emailing screenshots of the Parameters page and the Interface page of the element card to <support.data-acquisition@skyline.be>. Be sure to send them before Thursday, June 13th, 6 PM CEST.