# PipelineDB

![Build Status](https://img.shields.io/circleci/token/db1a70c164cd6d96544d8eb38b279c48dea24709/project/pipelinedb/pipelinedb/master.svg?style=flat-square)
[![Release](https://img.shields.io/github/release/pipelinedb/pipelinedb.svg?style=flat-square)](https://github.com/pipelinedb/pipelinedb/releases)
[![License](https://img.shields.io/:license-GPLv3-blue.svg?style=flat-square)](https://github.com/pipelinedb/pipelinedb/blob/master/LICENSE)
[![Gitter chat](https://img.shields.io/badge/gitter-join%20chat-brightgreen.svg?style=flat-square)](https://gitter.im/pipelinedb/pipelinedb)
[![Twitter](https://img.shields.io/badge/twitter-@pipelinedb-55acee.svg?style=flat-square)](https://twitter.com/pipelinedb)

## Getting started

If you just want to get started with PipelineDB right away, head over to the [download page](http://pipelinedb.com/download) and follow the simple [installation instructions](http://docs.pipelinedb.com/installation.html).

If you'd like to build PipelineDB from source, keep reading!

## Building from source
Install some dependencies first:
```
sudo apt-get install libreadline6 libreadline6-dev check g++ flex bison python-pip pkgconf zlib1g-dev python-dev libpq-dev libcurl4-openssl-dev expect
sudo pip install -r src/test/py/requirements.txt
```

Next you'll have to install [ZeroMQ](http://zeromq.org/) which PipelineDB uses for inter-process communication. [Here's](https://gist.github.com/usmanm/32a54a6b0f1f29d7737f86e29f837afa) a gist with instructions to build and install ZeroMQ 4.1.5 from source.

#### Build the PipelineDB core (with debug symbols)
```
./configure CFLAGS="-g -O0" --enable-cassert --prefix=</path/to/dev/installation>
make
make install
```

#### Add your dev installation path to the PATH environment variable
```
export PATH=/path/to/dev/installation/bin:$PATH
```

#### Test PipelineDB *(optional)*
Run the following command:

```
make check
```

#### Bootstrap the PipelineDB environment
Create PipelineDB's physical data directories, configuration files, etc:

```
make bootstrap
```

**`make bootstrap` only needs to be run the first time you install PipelineDB**. The resources that `make bootstrap` creates may continue to be used as you change and rebuild PipeineDB.


#### Run PipelineDB
Run all of the daemons necessary for PipelineDB to operate:

```
make run
```

Enter `Ctrl+C` to shut down PipelineDB.

`make run` uses the binaries in the PipelineDB source root compiled by `make`, so you don't need to `make install` before running `make run` after code changes--only `make` needs to be run.

The basic development flow is:

```
make
make run
^C

# Make some code changes...
make
make run
```

#### Send PipelineDB some data

Now let's generate some test data and stream it into a simple continuous view. First, create the stream and the continuous view that reads from it:

    pipeline
    =# CREATE STREAM test_stream (key text, value integer);
    CREATE STREAM
    =# CREATE CONTINUOUS VIEW test_view AS SELECT key, COUNT(*) FROM test_stream GROUP BY key;
    CREATE CONTINUOUS VIEW

Events can be emitted to PipelineDB streams using regular SQL `INSERTS`. Any `INSERT` target that isn't a table is considered a stream by PipelineDB, meaning streams don't need to have a schema created in advance. Let's emit a single event into the `test_stream` stream since our continuous view is reading from it:

    pipeline
    =# INSERT INTO test_stream (key, value) VALUES ('key', 42);
    INSERT 0 1

The 1 in the `INSERT 0 1` response means that 1 event was emitted into a stream that is actually being read by a continuous query.

The `generate-inserts` script is useful for generating and streaming larger amounts of test data. The following invocation of `generate-inserts` will build a SQL multi `INSERT` with 100,000 tuples having random strings assigned to the `key` field, and random `ints` assigned to the `value` field. All of these events will be emitted to `test_stream`, and subsequently read by the `test_view` continuous view. And since our script is just generating SQL, we can pipe its output directly into the `pipeline` client:

    bin/generate-inserts --stream test_stream --key=str --value=int --batchsize=100000 --n=1 | pipeline

Try running `generate-inserts` without piping it into `pipeline` to get an idea of what's actually happening (reduce the `batchsize` first!).

Let's verify that the continuous view was properly updated. Were there actually 100,001 events counted?

    pipeline -c "SELECT sum(count) FROM test_view"
      sum
    -------
    100001
    (1 row)

What were the 10 most common randomly generated keys?

    pipeline -c "SELECT * FROM test_view ORDER BY count DESC limit 10"
     key | count
    -----+-------
    a   |  4571
    e   |  4502
    c   |  4479
    f   |  4473
    d   |  4462
    b   |  4451
    9   |  2358
    5   |  2350
    4   |  2350
    7   |  2327

    (10 rows)

## License

See the [LICENSE](https://github.com/pipelinedb/pipelinedb/blob/master/LICENSE) file for licensing and copyright terms.
