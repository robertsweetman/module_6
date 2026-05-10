# Introduction and Overview <!-- 800 words -->

## Cloud Computing and Modern Software Development

Moderns software development methodologies like Agile, Scrum etc. have relied heavily on the shift towards on demand based cloud based computing (LEAD INNOVATIONZ, 2025).

These approaches leverage automation using CI/CD pipelines to enable rapid prototyping, innovation at scale and offer a commercial flexibility lacking in purely on-prem deployments (Surya S, 2023). 

Containerisation and Serverless are the epitome of this approach where application running costs can be directly linked to business revenue and even API requests in the case of serverless. (REF:)

The move from multi-week on-prem deployments to a service model can be summed up in the phrase "cattle, not pets" as described by the DevOps movement (Hava, 2020). Resources become ephemeral and disposable.

Infrastructure automation tools like Terraform, Bicep (Azure), Cloudfront (AWS) enable the flexibility to stand services up, turn them off and then rebuild them at the touch of a button.

## Move Fast and (Don't) Break Things

Mark Zuckerberg announced in 2014 that Meta's internal motto would change from "Move fast and break things" to "Move fast with stable infrastructure" (Wikipedia, 2023). The era of "Move Fast and Break Things" is over both technically and culturally (Taneja, 2019). End user demand and expectation of a reliable, consistent online experience is now absolute following people's interactions with the internet over the last 20+ years (John, 2026)

Empowering dozens of engineering teams to make daily changes across different applications and repositories requires automation to support test environments, deployment pipelines and visibility of changes over time.

Having an at-a-glance way to see what's been deployed when and where allows software delivery managers, team leads and business leaders to surface the rolling changes that now make up process of modern software development. TODO: (REF: CI/CD what it means and why it's an indicator of a successfull or high performing team)

## Batteries Included via IaC automation

This automation - infrastructure as code (IaC) - is now the enabling layer to having a robust, scalable, monitorable and disaster resistant solution (about.gitlab.com, 2026)

It defines everything from hub/spoke networking, firewalls, traffic to/from the environment, secure access, monitoring, security, alerts, user groups and roles defining who can do what inside a particular cloud.

## What's going on?

With all this fast moving software development happening it's challenging for various stake holders to understand where a particular program or service has reached in its deployment cycle.

Each stakeholder group has their own particular view and context:

Developers & Testers
 - What application versions are deployed?
 - Are all environments (dev/test/production) on the same release?
 - Where a new version is in the pre-deployment test cycle

Project & Release Managers
 - What versions are likely to be coming next?
 - Are there items that need resolving or are holding up progress?
 - Is there any sort of release pipeline holdup 

Support
 - When was the last release/change made?
 - What was in it that might impact users or their experience? 

Business Owners
 - Is version 'x' with feature 'y' released yet?
 - How many sprints left till a particular feature is released?
 - Where in the feature delivery pipeline is a particula application?
  - Development/Testing/Live

While Azure DevOps provides an individual 'per-project' view there's no single place where this sort of information can be surfaced across an organisation

(REF: developing in silos, business management, expectation management) 

## Solution Overview

A cloud-based delivery visibility site provides a single, organisation-wide view of application and infrastructure status, connecting code changes to deployment outcomes across environments.

It aligns with the software development lifecycle by supporting planning, build, test, release, and live monitoring. 

<!--
=== REPORT STRUCTURE — What to cover in this section ===

• Explain fundamental computer networking concepts in relation to cloud computing (e.g., structure, cloud architecture, components, quality of service) (K16).
• Provide an overview of the cloud-based tool you will design and build, including its function and alignment to the software development lifecycle (K16).

=== MARKING RUBRIC — LO1: K16 ===

B grade:
Analyses the interaction between networking components within the organisational environment. Justifies the architecture using context-specific data. Evaluates alternative architectural patterns.

A grade:
Critically appraises how networking selections (e.g. Latency vs. Throughput address strategic organisational requirements.

=== KSB DESCRIPTION ===

K16: Fundamental computer networking concepts in relation to digital and technology solutions. For example, structure, cloud architecture, components, quality of service.
-->
