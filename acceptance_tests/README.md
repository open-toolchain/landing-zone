# Accteptance Tests

Accecptance tests use the [tfxjs](https://github.com/IBM/tfxjs) framework.

## Prerequisites

- nodejs installed locally.

## Installing tfxjs

- To install all needed dependencies, run `npm run build` from this directory

## Running the Tests

Create a file in this directory called `.env` and add the following line to allow the use of your API key when running the acceptance tests. This is needed to ensure data blocks can be used when running `terraform plan`.

```
API_KEY=<your ibmcloud platform api key>
```

From the `./acceptance_test` directory use the command `npm run test` to run all acceptance tests