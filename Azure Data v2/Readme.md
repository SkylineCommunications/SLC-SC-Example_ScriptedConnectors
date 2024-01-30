**Requirements:**

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
