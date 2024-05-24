#!/bin/bash

source tman.sh

TASK_PREFIX="TEST_TEST"

function tman_add_100()
{
    local iter_counts=100

    echo "Add $iter_counts tasks"
    for i in $(seq $iter_counts); do
        local taskid="${TASK_PREFIX}_$i"
        echo "My test example $taskid" | tman add $taskid
    done
}

function tman_del_100()
{
    local iter_counts=100

    echo "Add 100 tasks"
    for i in $(seq $iter_counts); do
        local taskid="${TASK_PREFIX}_$i"
        echo "Yes" | tman del $taskid
    done
}


#tman_add_100
#tman_del_100
# delete: bash tests/use/add.sh  46.14s user 18.75s system 107% cpu 1:00.52 total
# add:    bash tests/use/add.sh  39.40s user 15.31s system 107% cpu 50.929 total

