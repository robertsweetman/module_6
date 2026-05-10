# Develop Cloud Based Tool <!-- 1200 words -->

IMPORTANT: REFER BACK TO THE FUNCTIONAL, NON-FUNCTIONAL and SECURITY requirements

## Development Workflow

Use Azure DevOps to capture all the tasks, split these into sprints, create milestones and report against those. Architectural design docs and so forth get published in the Azure DevOps wiki

TODO: add a Gantt chart here?

TODO: Everything uses IaC - WHY?! (do we even have to explain this? It's 2026)

## Challenges encountered

### Publishing events
Publishing from a pipeline run to an accessible but secure endpoint

### Event Design


### No-SQL dashboard design


### Azure DevOps security

Who can publish what to where? Is sending a CURL event from a pipeline even a good idea?

### Azure Function and Function App debugging

## Testing Methodology

In order to meet the non-functional requirements (speed, security) etc. a tester was assigned to the project TODO: research testing methodologies - perf, resource utilization, COSTS - not just security. 

Is scalability an issue? Azure functions/function apps are inherantly scalable. 

## Resilience and recovery from failure

TODO: come up with a better title for this section. 

## Alternative architectures

### Containers

Work is only going to be carried out on a per-change basis and with containers there's actually 'too much' network/infra overhead to justify this. We'd need a queue anyway so... might as well go full serverless...

### Hosted Server

Let's not host a website - that's so 2010's now (Function Apps FTW!!)


<!--
=== REPORT STRUCTURE — What to cover in this section ===

• Implement your cloud-based tool design, documenting techniques and methods used (K24).
• Describe how tools that support teamwork (e.g., configuration management, version control, release management) were or could be used in the development process (K28).
• Test your tool's performance, flexibility, resource optimisation, and scalability (K24).

=== MARKING RUBRIC — LO2: K24 ===

B grade:  
Analyses trade-offs between design alternatives (e.g. Serverless vs. Containers). Synthesises testing data to evaluate quality controls and resource optimisation.

A grade:
Critically evaluates design effectiveness across multiple failure scenarios. Justifies the selection of architectural patterns against legacy system constraints.

=== MARKING RUBRIC — LO4: K28 ===

B grade:
Analyses how tools support distributed teams and code integration. Justifies the use of specific configuration management approaches (e.g. Infrastructure as Code).

A grade:
Evaluates the effectiveness of the teamwork toolchain. Compares alternative tools and justifies selections based on their impact on team productivity and cloud code quality.

=== KSB DESCRIPTIONS ===

K24: How to interpret and implement a design, compliant with functional, non-functional and security requirements including principles and approaches to addressing legacy software development issues from a technical and socio-technical perspective. For example, architecture, languages, operating systems, hardware, and business change.

K28: Approaches to effective teamwork and the range of software development tools supporting effective teamwork. For example, configuration management, version scontrol and release management.
-->
