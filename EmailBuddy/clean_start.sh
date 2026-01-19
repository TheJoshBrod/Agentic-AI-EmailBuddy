#!/bin/bash
echo "Cleaning up previous session state..."
rm -rf .jac

echo "Reinstalling dependencies..."
jac install
jac add --cl

echo "Starting EmailBuddy..."
jac start main.jac
