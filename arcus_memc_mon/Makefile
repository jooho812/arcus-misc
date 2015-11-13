OBJECTS = arcus_memc_mon_rm_znode.o arcus_memc_mon_logger.o
CFLAGS = -g -Wall -Werror
CC = gcc

all : arcus_memc_mon

arcus_memc_mon : $(OBJECTS) arcus_memc_mon.c
	libtool --mode=link $(CC) $(CFLAGS) -o $@ $^ -D_REENTRANT -L../../arcus/lib -lzookeeper_mt -pthread

arcus_memc_mon_rm_znode.o : arcus_memc_mon_rm_znode.c
	$(CC) $(CFLAGS) -c -o $@ $^ -I../../arcus/include/zookeeper

clean :
	rm -rf *.o arcus_memc_mon
