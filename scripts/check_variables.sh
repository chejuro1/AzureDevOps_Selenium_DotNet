#!/bin/bash

# Check if arguments are provided
# if [ $# -eq 0 ]; then
#   echo "Error: No variables provided. Please provide at least one variable name as an argument."
#   exit 1
# fi

# Loop through all arguments
for variable_name in "$@"
do
  # Check if the variable is empty
  if [ -z "${!variable_name}" ]; then
    echo "Error: The variable '$variable_name' is empty. Please provide a value."
    exit 1
  else
    echo "Variable '$variable_name' has a value: ${!variable_name}"
  fi

done
