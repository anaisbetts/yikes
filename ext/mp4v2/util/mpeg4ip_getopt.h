/* This file is a compatibility file that acts like mpeg4ip.h in the
   mpeg4ip distribution.

   This file is in the pubic domain.

   Noa Resare (noa@resare.com)
*/
#include <config.h>

#include <mpeg4ip.h>

#include <sys/types.h>
#include <sys/stat.h>
#include <getopt.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <fcntl.h>
#include <errno.h>

// the home of PATH_MAX. Is this portable?
#include <sys/param.h>

#define OPEN_CREAT O_CREAT
#define FOPEN_READ_BINARY "r"
#define FOPEN_WRITE_BINARY "w"



#define MPEG4IP_PACKAGE PACKAGE
#define MPEG4IP_VERSION VERSION
