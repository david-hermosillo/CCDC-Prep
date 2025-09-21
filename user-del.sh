#!/bin/bash

for user in $(cat users.txt); do
    sudo userdel -r "$user"
done