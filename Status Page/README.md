# Status Page

These Scripted Connectors retrieve status information from the Atlassian Status Page API.

- **StatusPageStatus.py** fetches an indicator - one of none, minor, major, or critical, as well as a human description of the blended component status. Examples of the blended status include "All Systems Operational", "Partial System Outage", and "Major Service Outage".
- **StatusPageComponents.py** fetches the components of the service. Each component is listed along with its status - one of operational, degraded_performance, partial_outage, or major_outage.
