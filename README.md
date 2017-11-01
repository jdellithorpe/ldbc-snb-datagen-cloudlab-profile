CloudLab Profile for Generating LDBC SNB Datasets
=================================================

This is a CloudLab repository-based profile for setting up experiments for
generating LDBC SNB datasets. The experiment nodes are setup for running Hadoop
2.6.0 and the [LDBC SNB data generator](https://github.com/ldbc/ldbc_snb_datagen).

The directory structure has the following important directories:
```
hadoop.conf/ : Hadoop configuration files. Make changes here for your specific
setup.
ldbc_snb_datagen.conf/ : LDBC SNB data generator configuration files. Make
changes here for your specific setup (e.g. params.ini: scale factor, number of
threads to use). 
```

The profile additionally has several CloudLab configuration parameters:

```
Hardware Type : What type of machines to use.
Disk Image : The OS you want to run.
Number of Hadoop Worker Nodes : The number of Hadoop datanodes / nodes for
running map reduce tasks in the cluster. These number of machines + 1 for the
master node will be allocated. 
URN for Dataset Storage : URN for CloudLab dataset in which to store the social
network files.
```

Setup scripts for the experiment download Hadoop to `/opt/hadoop-2.6.0`, and
the dataset is mounted at `/mnt/dataset`. The LDBC SNB dataset generator
repository is automatically cloned to `/mnt/dataset/ldbc_snb_datagen`. 

## Instructions ##
* Before experiment launch:
  * Modify configuration settings in `hadoop.conf` and `ldbc_snb_datagen.conf`
    directories. Configuration settings can of course be modified after the
    experiment has been started. The defaults in the configuration files for
    Hadoop are set for a cluster of m510 machines.
* After experiment startup and ssh'ing into the master node:
  * `cd /opt/hadoop-2.6.0`
  * `bin/hdfs namenode -format`
  * `sbin/start-dfs.sh`
  * `sbin/start-yarn.sh`
  * `cd /mnt/dataset/ldbc_snb_datagen`
  * `./run.sh`
* HDFS web interface should be viewable at (assuming the master server is
  located at ms1134.utah.cloudlab.us):
  * `http://ms1134.utah.cloudlab.us:50070/`
* Yarn web interface is run off of port 8088 (default) on an internal IP
  address. To access from outside CloudLab you can run an ssh tunnel to it,
  like so:
  * `ssh -L 8088:10.10.1.1:8088 user@ms1134.utah.cloudlab.us`
  * `http://localhost:8088/`
* When the dataset generator is finished running, the dataset will be available
  in HDFS under `social_network/`. The query parameters should be available on
  local disk in the `ldbc_snb_datagen` directory under
  `substitution_parameters`.

# Notes on LDBC SNB Datagen #
These notes are relevant at the time of writing and may change with future
updates to the LDBC SNB data generator.
* `walkmod` dependence results in an error at compile time, so this is
  commented out in the POM file.
* `params.ini` contains import configuration settings for the LDBC SNB data
  generator. In particular, the `numThreads` parameter controls the total
  number of reducers that can run in a map-reduce job. You'll want to set this
  to a number that's safely below the total number of cores you have available
  in your allocated cluster.
* The data generator runs in two phases. In the first phase the simulator runs
  and generates data in HDFS for the social network. In the second phase, a
  large fraction of this data is downloaded to local disk and processed in
  order to generate the query parameters. This processing is performed on the
  local machine by a python script (`generateparams/paramgenerator.py`). Couple
  of notes on this:
  * The amount of data that needs to be downloaded from HDFS is very large,
    proportional to the dataset size, so your local disk will need to be large
    enough (wherever run.sh is being run from) to accomodate this.
  * The script `paramgenerator/generateparams.py` takes over 12 hours to
    complete on an Intel Xeon-D machine with 64GB of DDR4 memory (CloudLab m510
    machine) for the SF1000 dataset. 


## Additional Notes ##
* The SF1000 data was successfully generated using 20x m510 machines with 200GB
  of local disk storage allocated per machine.
