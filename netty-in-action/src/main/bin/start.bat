@echo off
SetLocal EnableDelayedExpansion

SET CLASSPATH=.;..;..\conf
FOR %%i IN ("../lib/*.jar") DO SET CLASSPATH=!CLASSPATH!;..\lib\%%i

ECHO %CLASSPATH%

java -cp %CLASSPATH% com.haogrgr.netty.chapter2_3.EchoServer

EndLocal