#!/bin/bash

function tman_add()
{
    local taskids=("DE-me1" "DE-me2")
    #tman add DE-me5 bugfix high
    for ID in ${taskids[@]}; do
        echo $ID
    done
}


tman_add

