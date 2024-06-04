# Advanced Exercise


Create a data source to poll the status of a networking device

## Polling the data

1. Open the Data Sources module:
  a. In DataMiner Cube, click Apps in the sidebar to the left and select Data Sources,
2. Click Create Data Source.
3. Configure the Data source name field with an identifiable name (e.g. Router Status) and ensure the Type is set to Python.
4. Create Python script to fetch the response from 

## Configure units and digits

```python

import requests

def main():
    # Define the service for which we are checking the status
    # Example services using this API are GitHub, Dropbox, Discord, Vimeo
    service = "Dropbox"
    
    # Set the base URL of the status page API for the service
    # Example API URLs for these services are:
    # https://www.githubstatus.com, https://status.dropbox.com, https://discordstatus.com, https://www.vimeostatus.com/
    urlapi = "https://status.dropbox.com"

    # Define header parameters for the request to the local API
    header_params = {
        "identifier": "router status",
        "type": "Router Status",
    }
    
    # Create a session object to manage and persist settings across requests
    session = requests.Session()

    # Send a GET request to the status API to get the current status in JSON format
    status = session.get("https://routersimulation.azurewebsites.net/RouterStatus")
    
    # Send a PUT request to the local Data API with the status data
    # Include the header parameters for additional context
    session.put("http://localhost:34567/api/data/parameters", json=status.json(), headers=header_params) 

# Execute the main function when the script is run
if __name__ == "__main__":
    main()
```