#!/bin/bash
echo "Cleaning up previous session state..."
rm -rf .jac

echo "Reinstalling dependencies..."
JAC_PATH="/home/jodab/DevAdvocate/Projects/Agentic-AI-EmailBuddy/EmailBuddy0/env/bin/jac"

echo "Reinstalling dependencies..."
$JAC_PATH install
$JAC_PATH add --cl

echo "Starting EmailBuddy..."
$JAC_PATH start main.jac
