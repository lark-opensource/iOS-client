C = g++
CFLAGS = -Wall -Wdeprecated
OBJ = JPEG-LIB.o

JPEG-LIB.o: JPEG.c
	$(CC) $(CFLAGS) -c -o $@ $<

JPEG-LIB.a: JPEG-LIB.o
	ar rvs $@ JPEG-LIB.o
