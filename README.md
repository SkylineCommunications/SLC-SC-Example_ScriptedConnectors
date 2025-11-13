# SLC-SC-Example_Scripted-Connectors

This repository contains examples of Scripted Connectors.

Scripted Connectors offer flexible access to data from any source imaginable, across hardware, software, and cloud services. These connectors can be written using Python or PowerShell and are available through the module [Data Sources](https://docs.dataminer.services/dataminer/Functions/Data_Sources/Data_Sources.html). The scripts, in turn, transmit JSON data through a local HTTP call to the Data API. Subsequently, this action initiates the generation of an element through an automatically created connector.

This  functionality has not yet been made available to the general public, but is available as a soft launch option. Follow the steps listed in [Installation and setup](https://aka.dataminer.services/scripted-connectors) to activate this functionality.

Examples include

- [Amsterdam Internet Exchange](Amsterdam%20Internet%20Exchange) : scrapes data from the AMS-IX website for various locations, including Amsterdam, Bay Area, Caribbean, Chicago, Hong Kong, and Mumbai.
- [Azure Data v2](Azure%20Data%20v2) : collects data on both active and deallocated Windows Server 2022 VMs in Azure.
- [Sample Scripted Connector](SampleScriptedConnector): starter script designed to demonstrate how to push fixed data to Data API from outside of DataMiner. It leverages a user-defined API. 
- [Coincap](Coincap) : fetches data from the CoinCap API, converting certain string values to floats, and sending the modified data to Data API.
- [Status Page](Status%20Page) : retrieve status information from services using the Atlassian Status Page.


# Meta Data (for Skyline Communications)

Skyline Example Scripted Connectors is added to DCP with Driver ID DMS-DRV-9044 & Device OID 21.
