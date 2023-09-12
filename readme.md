# API_CLIENT PL/SQL package

This project was started as small utility package for working with SOAP/REST APIs directly from PL/SQL code. 
It was also useful as tool for working with the OpenStack API.

## Documentation

Package can be used with Oracle Database of version 11.2 and later.
By default a new user named API_USER will be created and all objects and the package will be owned by API_USER.

## Install

There provided 4 scripts for creating all objects:
01_api_client_user - creating API_USER user with nessesary grants;
02_api_client_objects - creating tables, sequences and indexes;
03_api_client_package_header - API_CLIENT package header;
04_api_client_package_body - API_CLIENT package body.

## Development

To view an example of using the API_CLIENT package, script 05_api_client_example is offered.

## Prospects

I plan to add a package for testing with different types of protocols and services in the near future.
