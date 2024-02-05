# Azure Data v2

The Scripted Connector collects data on both active and deallocated Windows Server 2022 VMs in Azure. It acquires essential information about Azure virtual machines, encompassing:

- Resource Group Name
- VM ID (Name)
- Location
- Operating System (OS)
- VM Tags
- VM SKU
- Hybrid License status

Additionally, it conducts counts for the following metrics:

- Number of VMs per VM Tag
- Number of VMs and reservations per VM SKU

The gathered details, along with the computed counts, are subsequently transmitted to the Data API.

## Setting it up

1. **App Registration Setup:**
   - Create an app registration in the Azure portal.
   - Configure certificate-based authentication for the app.

2. **Certificate Import:**
   - Import the certificate associated with the app registration to your DataMiner Agent (DMA).

3. **Permission Configuration:**
   - Grant the app the following permissions:
      - Read permissions on the subscriptions containing Virtual Machines.
      - Read permissions on Azure Reservations.

4. **Fill in the following details in the script:**
   - App ID: [Your App ID]
   - Certificate Thumbprint: [Your Certificate Thumbprint]
   - Tenant ID: [Your Tenant ID]
