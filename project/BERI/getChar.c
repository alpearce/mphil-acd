#include <stdio.h>
#include <stdlib.h>
#include <termios.h>
#include <unistd.h>
#include <fcntl.h>

struct termios initial_settings,
               new_settings;


unsigned int c_getchar (void)
{
  return getchar();
}


// nonblocking version of getchar though a character will not be
// received if it is still being held in a buffer, e.g. if the
// buffer is waiting for a CR before sending.
unsigned int c_getchar_nonblocking (void)
{
  int fd = fileno(stdin);
  int flags = fcntl(fd, F_GETFL, 0);
  unsigned int c;
  fcntl(fd, F_SETFL, flags | O_NONBLOCK); // set nonblocking
  c=getchar();
  fcntl(fd, F_SETFL, flags); // restore the blocking/nonblocking status
  return c;
}


/* the following functions manipulate the tty which Robert does
   not recommend but left here for reference in case we need to
   control the tty to remove buffering

void c_setTermNonblocking (void)
{
  tcgetattr(0,&initial_settings);

  new_settings = initial_settings;
  new_settings.c_lflag &= ~ICANON;
  new_settings.c_lflag &= ~ECHO;
  new_settings.c_lflag &= ~ISIG;
  new_settings.c_cc[VMIN] = 0;
  new_settings.c_cc[VTIME] = 0;

  tcsetattr(0, TCSANOW, &new_settings);
}


void c_resetTerm (void)
{
  tcsetattr(0, TCSANOW, &initial_settings);
}
*/
