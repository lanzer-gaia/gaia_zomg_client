@echo off
SET ccTime=%1
SET _year=%ccTime:~0,4%
SET _day=%ccTime:~4,2%
SET _month=%CCTime:~6,2%
SET _seconds=%CCTime:~-2,2%
SET _minute=%CCTime:~-4,2%
SET _hour=%CCTime:~-6,2%
SET _result=%_day%/%_month%/%_year% %_hour%:%_minute%:%_seconds%
ECHO %_result%


