#!/bin/bash

value=$(sed -n '/^host_name/s/.*= *//p' $1)

echo $value
