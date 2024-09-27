# Hilo Connect

Hilo Connect is a scalable and asynchronous solution for utilities and virtual power plants to manage and control end-customer DERs. A demand response management system (DRMS) or Edge DERMS can send demand response events and specific device instructions to thermostats and other end-user devices, helping to balance energy loads and improve overall grid stability.

This repository is dedicated to collaborating on the JSON schema used to inform participant aggregators about the lifecycle of a demand response event, as well as providing a detailed instruction set for fine-grained control of behind-the-meter DERs.

# Schema

[![Publish demandresponse.schema.json](https://github.com/hiloenergie/schema/actions/workflows/schema-update-cd.yml/badge.svg)](https://github.com/hiloenergie/schema/actions/workflows/schema-update-cd.yml)

Updates to the schema in this repository are automatically published at https://schema.hiloenergie.com/json/v1/demandresponse.schema.json

The repository also contains examples of life cycle events and a simple tool to generate device plans for testing purposes.

The delivery envelope is defined by the CloudEvents 1.0 spec and is published at https://github.com/cloudevents/spec/blob/v1.0.2/cloudevents/formats/cloudevents.json

# Wiki documentation

[![Pack Wiki Files](https://github.com/hiloenergie/schema/actions/workflows/wiki-update.yml/badge.svg)](https://github.com/hiloenergie/schema/actions/workflows/wiki-update.yml)

Updates to the Github wiki are automatically packed and published under the above link.