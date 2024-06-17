#!/bin/bash

source tman.sh

TASK_PREFIX="TEST_TEST"
ITERS=1000

function tman_add()
{
    echo "Add $ITERS tasks"
    for i in $(seq $ITERS); do
        local taskid="${TASK_PREFIX}_$i"
        echo "My test example $taskid" | tman add $taskid
    done
}

function tman_del()
{
    echo "Add 100 tasks"
    for i in $(seq $ITERS); do
        local taskid="${TASK_PREFIX}_$i"
        echo "Yes" | tman del $taskid
    done
}


#tman_add
#tman_del
# delete: bash tests/use/add.sh  46.14s user 18.75s system 107% cpu 1:00.52 total
# add:    bash tests/use/add.sh  39.40s user 15.31s system 107% cpu 50.929 total

