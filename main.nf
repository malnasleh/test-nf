#!/usr/bin/env nextflow

// Using DSL-2
nextflow.enable.dsl=2

process runTest {
    container "public.ecr.aws/ubuntu/ubuntu:22.04"
    """#!/bin/bash
sleep 10m
    """

}

workflow {
  runTest()
}
