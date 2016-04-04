#!/bin/sh

gulp clean
gulp zip --production
gulp zip --staging

