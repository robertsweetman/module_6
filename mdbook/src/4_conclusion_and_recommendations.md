# Conclusion and Recommendations <!-- 800 words -->

TODO: Highlight how this sort of observability and visibility is going to become even more important as AI enables the INCREASE in deployment speed, change rate increases and so on <-- come up with a better way to describe this

## ROI

Ongoing cost is very low
ROI in terms of time saved is very high
 - come up with meetings saved in status updates
 - executives time is valuable so anything that saves this matters

## Further enhancements and reliability

Attach an MCP server to the database backend so people can ask natural language questions about project progress

Improve/expand the record schema to include more things - especially related to DORA metrics - refer back to these again

Observability and Monitoring improvements possibly? What new things can be done with App Insights? Or do we just lob all the data/events into App Insights and use THAT for reporting even? Possibly less integration work and the framework/endpoint is already there!! 

## Summary

This cloud-based tool delivers a secure dashboard that shows application releases and deployment status across the organisation.

It uses an event-driven architecture that posts Azure DevOps pipeline status messages which are picked up by Azure functions and stored in a NoSQL backend. The function app uses this backend as the basis for the dashboard which is only accessible via Entra ID access using 2FA. 

Application insights monitoring, especially around user logins, complete the security protecting this sensitive data.

By making this information widely accessible across the organisation a high ROI is achieved by reducing status reporting meetings, cross team calls, faster triage of release based issues while running on low cost serverless and managed cloud resources.
 

<!--
=== REPORT STRUCTURE — What to cover in this section ===

• Provide recommendations for implementing your cloud-based tool.
• Summarise your project's goals, methodology, and anticipated ROI.

(Milestone 3: Assess the impact of the tool within your organisation and provide recommendations to further enhance architecture resiliency and scalability with cloud-based solutions.)
-->
