# Sample Scripted Connector

## Overview

The **Sample Scripted Connector** scripted connector is a starter script designed to demonstrate how to push fixed data to DataMiner using the Data API. Unlike other connectors that fetch data from external sources, this script simply uses hardcoded data and sends it directly to DataMiner via HTTP PUT requests.

This connector is ideal for:

- Learning how to use the Data API for pushing data
- Testing DataMiner integrations without external dependencies
- Prototyping and development workflows
- Understanding authentication and HTTP request patterns

## Features

- **Simple Data Push**: Sends fixed data to DataMiner without requiring external data sources
- **Bearer Token Authentication**: Uses secure bearer token authentication with the Data API
- **Error Handling**: Includes exception handling for HTTP request failures
- **Lightweight**: Minimal dependencies with only Python's `requests` library required

## Prerequisites

- Python 3.x
- `requests` library (install via `pip install requests`)
- Access to a DataMiner agent with the Data API enabled
- Valid bearer token for authentication
- **User-defined API deployed and configured on DataMiner** - This connector requires the user-defined API [DataAPI Proxy](https://catalog.dataminer.services/details/159e3f05-b1e6-43c8-b71f-44f9b8a6f4f3) to be deployed and configured on DataMiner. The API exposes the `/api/custom/data/parameters` endpoint that this connector sends requests to.

## Configuration

Before running the script, update the following variables in `dummy.py`:

```python
bearer = 'YOUR_BEARER_TOKEN_HERE'
host = 'system-organisation.on.dataminer.services'
```

### Parameters

The script sends data to the DataMiner Data API with the following configuration:

| Parameter | Description | Example |
|-----------|-------------|---------|
| `identifier` | The unique identifier for the data element | `Equipment01` |
| `type` | The data type or category | `PFU` |
| `body` | The JSON data payload to push | `{"Voltage": 0.1}` |

## Usage

Run the script from the command line:

```bash
python dummy.py
```

### Expected Output

On successful execution:

```
{'Authorization': 'Bearer YOUR_BEARER_TOKEN', 'Content-Type': 'application/json'}
PUT status: 200
```

### Error Handling

If the HTTP request fails, the script will display an error message and exit:
```
HTTP request failed: [error details]
```

## How It Works

1. **Authentication Setup**: Defines bearer token and host details for API access
2. **URL Construction**: Builds the API endpoint with identifier and type parameters
3. **Request Headers**: Sets up authorization and content-type headers
4. **Data Payload**: Creates a JSON object with fixed data (e.g., `{"Voltage": 0.1}`)
5. **HTTP PUT Request**: Sends the data to the user-defined API endpoint on DataMiner
6. **Response Handling**: Prints the HTTP status code and handles any exceptions

## User-Defined API

This scripted connector sends requests to a **user-defined API** endpoint exposed by DataMiner. The user-defined API that needs to be deployed and configured on your DataMiner instance before this connector can function.

**Reference**: [Skyline DataMiner Catalog - Custom User-Defined API](https://catalog.dataminer.services/details/159e3f05-b1e6-43c8-b71f-44f9b8a6f4f3)

### Endpoint

The script targets:
```
https://{host}/api/custom/data/parameters?identifier={identifier}&type={type}
```

**Method**: PUT  
**Content-Type**: application/json  
**Authentication**: Bearer Token

This endpoint is exposed by the user-defined API and handles incoming PUT requests with custom data payloads.

## Customization

To modify the data being pushed, edit the `body` variable:

```python
body = { "Voltage": 0.1, "Current": 2.5, "Name": "Device 01" }
```

To change the target identifier or type:

```python
url_params = {
    "identifier": 'DeviceIdentifier',
    "type": 'DeviceType',
}
```

## Related Resources

- [Skyline DataMiner Data API Documentation](https://docs.dataminer.services/dataminer/Functions/Data_Sources/Data_API.html)
- [Other Scripted Connectors](../)

