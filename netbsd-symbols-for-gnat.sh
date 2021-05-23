#!/bin/sh

# NetBSD does symbol versioning using libc_func() __asm(name); in its headers.
#
# There is no known way to find 'name' from within a C program, aside from
# parsing the ELF structure and matching likely candidates.
# Gcc does not replace libc_func with name in asm() statements.

# A simple solution is to generate assembly output with a (cross) compiler,
# declare a global variable and extract the real symbol that follows it.
# This should be reasonably arch-independent since we're dealing with
# assembler directives only.

SYMBOLS="
abort
accept
atoi
bind
clearerr
clock_getres
clock_gettime
close
connect
dup
dup2
fclose
fdopen
fflush
fgetc
fgets
fputc
fputs
free
fseek
ftell
getenv
gethostbyaddr
gethostbyname
gethostname
getpagesize
getpeername
getpid
getservbyname
getservbyport
getsockname
getsockopt
gettimeofday
inet_ntop
inet_pton
isatty
kill
listen
lseek
malloc
memcpy
memmove
mktemp
mmap
mprotect
munmap
nanosleep
pclose
poll
popen
pthread_attr_destroy
pthread_attr_getschedparam
pthread_attr_getschedpolicy
pthread_attr_getscope
pthread_attr_init
pthread_attr_setschedparam
pthread_attr_setschedpolicy
pthread_attr_setscope
pthread_barrier_destroy
pthread_barrier_init
pthread_barrier_wait
pthread_cond_destroy
pthread_cond_init
pthread_cond_signal
pthread_cond_timedwait
pthread_cond_wait
pthread_condattr_destroy
pthread_condattr_init
pthread_create
pthread_detach
pthread_exit
pthread_getschedparam
pthread_getspecific
pthread_key_create
pthread_kill
pthread_mutex_destroy
pthread_mutex_init
pthread_mutex_lock
pthread_mutex_unlock
pthread_mutexattr_destroy
pthread_mutexattr_init
pthread_mutexattr_setprotocol
pthread_self
pthread_setname_np
pthread_setschedparam
pthread_setspecific
pthread_sigmask
read
realloc
recv
recvfrom
recvmsg
rewind
select
sendmsg
sendto
setsockopt
setvbuf
shutdown
sigaction
sigaddset
sigaltstack
sigdelset
sigemptyset
sigfillset
sigismember
sigwait
socket
socketpair
strerror
strlen
strncpy
sysconf
system
tmpfile
tmpnam
ungetc
unlink
usleep
write
"
CC=gcc
WD=`mktemp -d`

findsymbol()
{
	sym=$1
	shift

	# skip til we find the label
	while [ "$1" != "findthissym:" ]; do
		shift
	done

	if [ "$1" = "findthissym:" -a -n "$3" ]; then
		# $2 contains storage directive (.quad)
		# $3 is our symbol
		if [ "$sym" != "$3" ]; then
			echo "$sym -> $3"
		fi
	fi
}

for sym in $SYMBOLS; do
	cat > "$WD/i.c" <<EOF
#include <sys/types.h>
#include <sys/select.h>
#include <sys/socket.h>
#include <sys/mman.h>
#include <unistd.h>
#include <signal.h>
#include <poll.h>
#include <time.h>
#include <pthread.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <arpa/inet.h>
#include <netdb.h>
void *findthissym = ${sym};
EOF
	${CC} ${CFLAGS} ${CPPFLAGS} -lpthread -S -o $WD/o.s $WD/i.c
	findsymbol ${sym} `cat $WD/o.s`
done
rm -r $WD
