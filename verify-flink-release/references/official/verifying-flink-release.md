# Verifying a Flink Release

> Source: https://cwiki.apache.org/confluence/spaces/FLINK/pages/73631094/Verifying+a+Flink+Release
> Snapshot: Confluence v8, 2023-03-14

It is **NOT** necessary to run all checks to cast a vote for a release candidate.
However, you should clearly state which checks you did.
The release manager needs to ensure that each following check was done.

# Checking Artifacts

***Some of these are strictly required for a release to be ASF compliant.***

* Check if checksums and GPG files match the corresponding release files ***(required)***A detailed description on how this is done can be found in the [apache.org documentation about verifying releases](https://www.apache.org/info/verification.html).
* Verify that the source archives do not contain any binaries ***(required)***
* Build the source with Maven to ensure all source files have Apache headers ***(required)***
* Check that all POM files point to the same version.
  That includes the quickstart artifact POM files
  + <https://github.com/apache/flink/tree/master/flink-quickstart/flink-quickstart-java/src/main/resources/archetype-resources>
  + <https://github.com/apache/flink/tree/master/flink-quickstart/flink-quickstart-scala/src/main/resources/archetype-resources>
* Read the `README.md` file to ensure there is nothing unexpected

# Checking Licenses

***These checks are strictly required for a release to be ASF compliant.***

**Important:** These checks must be performed for

* the *Source Release*
* the *Binary Release*
* the Maven Artifacts (jar files uploaded to Maven Central)

Checks to be made include

* All Java artifacts must contain an Apache License file and a NOTICE file. Python artifacts only require an Apache License file.
* Non-Apache licenses of bundled dependencies must be forwarded
* The NOTICE files aggregate all copyright notices and list all bundled dependencies (except Apache licensed dependencies)

A detailed explanation on the steps above is in <https://cwiki.apache.org/confluence/display/FLINK/Licensing> (see the bottom of the document for the actions to take)

# Testing Functionality

***This is not necessarily required for a release to be ASF compliant, but required to ensure a high quality release.***

*This is not an exhaustive list - it is mainly a suggestion where to start testing.*

### Built-in tests

Check if the source release is building properly with Maven, including checkstyle and all tests (`mvn clean verify`)

* Build for Scala 2.12

Run the scripted nightly tests: <https://github.com/apache/flink/tree/master/flink-end-to-end-tests>

Run the Jepsen Tests for Flink: <https://github.com/apache/flink/tree/master/flink-jepsen>

### Quickstarts

Verify that the quickstarts for Scala and Java are working with the staging repository for both IntelliJ and Eclipse.

* <https://ci.apache.org/projects/flink/flink-docs-release-1.7/dev/projectsetup/java_api_quickstart.html>
* <https://ci.apache.org/projects/flink/flink-docs-release-1.7/dev/projectsetup/scala_api_quickstart.html>

### Simple Starter Experience and Use Cases

Run all examples from the IDE (Eclipse & IntelliJ)

Start a local cluster (**`start-cluster.sh`**) and verify that the processes come up

* Examine the \*.out files (should be empty) and the log files (should contain no exceptions)
* Test for Linux, OS X, Windows (for Windows as far as possible, not all scripts exist)
* Shutdown and verify there are no exceptions in the log output (after shutdown)
* Check all start+submission scripts for paths with and without spaces (./bin/\* scripts are quite fragile for paths with spaces)

Verify that the examples are running from both ./bin/flink and from the web-based job submission tool

* Start multiple taskmanagers in the local cluster
* Change the flink-conf.yml to define more than one task slot
* Run the examples with a parallelism > 1
* Examine the log output - no error messages should be encountered

### Testing Larger Setups

*These tests may require access to larger clusters or a public cloud budget. Below are suggestions for common things to test.*

A nice program to use for tests is <https://github.com/apache/flink/tree/master/flink-end-to-end-tests/flink-datastream-allround-test>
It uses built-in data generation and verification and uses some sensitive features.

Test against different file systems (Local/NFS, HDFS, S3, ...)

* Use file systems for checkpoints
* Use file systems for input/output

Run examples on different resource infrastructures

* YARN
* Mesos
* Kubernetes

Test against different source and sink systems (Kafka, Kinesis, etc.)

# Checking Documentation

* Check that all links work, the front page is up to date
* Check that new features are documented and updates to existing features are written down.
* Ensure that the migration guide from the last release to the new release is available and up to date.
