#include <stdio.h>
#include <stdlib.h>
#include <termios.h>
#include <unistd.h>
#include <fcntl.h>

struct termios initial_settings,
               new_settings;

int debugFlag = 0;
int debugFlagChecked = 0;
int traceFlag = 0;
int traceFlagChecked = 0;

int c_getDebugFlag (int counter)
{
  if (counter == 0) {
    FILE *istream;
    if ( (istream = fopen ( "debug", "r" ) ) == NULL)
        debugFlag = 0;
    else {debugFlag = 1; fclose(istream);}
    debugFlagChecked = 1;
  } else debugFlagChecked = 0;
  return (debugFlag);
}

int c_getTraceFlag (int counter)
{
  if (counter == 0) {
    FILE *istream;
    if ( (istream = fopen ( "trace", "r" ) ) == NULL)
        traceFlag = 0;
    else {traceFlag = 1; fclose(istream);}
    traceFlagChecked = 1;
  } else traceFlagChecked = 0;
  return (traceFlag);
}
