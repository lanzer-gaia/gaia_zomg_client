#!/bin/sh

compc -output=../../swcs/componentBases/uimanager2.swc -load-config=../battleMain/build-config-swc.xml -compiler.debug=false -link-report=uimanager2.swc.report.xml -compiler.external-library-path="/Applications/Adobe Flash Builder 4.5/sdks/3.6.0/frameworks/libs/player/10/playerglobal.swc" -compiler.external-library-path=/Users/bhalsted/src/other/gaia/trunk/mmo/Battle/swcs/assets -compiler.library-path="/Applications/Adobe Flash Builder 4.5/sdks/3.6.0/frameworks/libs" -compiler.namespaces.namespace http://www.gaiaonline.com/2008 ../../src/manifest.xml -include-namespaces http://www.gaiaonline.com/2008 -compiler.source-path "/Applications/Adobe Flash CS4/Common/Configuration/ActionScript 3.0/projects/Flash/src" ../../src ../../../../src --

