#!/bin/bash

if ! command -v node &> /dev/null
then
    exit 1
fi

if ! command -v npm &> /dev/null
then
    exit 1
fi

if ! grep -q '"lz-string"' package.json &> /dev/null; then
    npm install lz-string --save
else
    npm update lz-string
fi

# Run the JS file with Node.js
node lz_string_generate_test_cases.js