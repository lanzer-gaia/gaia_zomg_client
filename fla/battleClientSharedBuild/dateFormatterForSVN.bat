@echo off

SET ccTime=%1
SET _prefix=%ccTime:~0,-6%
SET _suffix=%ccTime:~-6%
SET _result=%_prefix%T%_suffix%

SET ccTime2=%2
SET _prefix2=%ccTime2:~0,-6%
SET _suffix2=%ccTime2:~-6%
SET _result2=%_prefix2%T%_suffix2%

ECHO {%_result%}:{%_result2%}
 

