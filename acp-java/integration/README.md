## start shell /MISC_DIR/ACP_JAVA_DIR

**integration functional test**
```
perl ./integration/run_integration_func.pl <ip> <port>
```
ex) perl ./integration/run_integration_func.pl jam2in-m001 11291

**integration performance test**
```
perl ./integration/run_integration_perf.pl <ip> <port> <permormance>
```
ex) perl ./integration/run_integration_perf.pl jam2in-m001 11291 40000

**integration replication test**

- make znode
```
./integration/setup-test-zk-intg-rp.bash (default use port 11291 ~ 11294)
```

- start test(master_port 11291, slave_port 11292)
```
perl ./integration/run_integration_repl.pl <master_port> <slave_port> <run_time> [keyset_size]
```
ex) perl ./integration/run_integration_repl.pl 11291 11292 5000000 300


- start test(switchover)(master_port 11293, slave_port 11294)
```
perl ./integration/run_integration_repl_switchover.pl <master_port> <slave_port> <run_time> [keyset_size]
```
ex) perl ./intgration/run_integration_repl_switchover.pl 11293 11294 5000000 300

**integration migration test**
```
perl ./integration/run_integration_mig.pl <run_time> [keyset_size]
```
ex) perl ./integration/run_integration_mig.pl 300 5000000

**integration IDC test**
