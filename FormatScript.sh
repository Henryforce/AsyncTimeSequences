#!/bin/sh

swift-format format --in-place --recursive Sources --configuration SwiftFormatConfiguration.json

swift-format format --in-place --recursive Tests --configuration SwiftFormatConfiguration.json

