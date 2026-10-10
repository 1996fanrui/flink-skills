# Creating a Flink Release

> Source: https://cwiki.apache.org/confluence/spaces/FLINK/pages/73631092/Creating+a+Flink+Release
> Snapshot: Confluence v243, 2026-08-28

This is based on the release guide of the Apache Beam project: <https://beam.apache.org/contribute/release-guide/>

## Introduction

The Apache Flink project periodically declares and publishes releases. A release is one or more packages of the project artifact(s) that are approved for general public distribution and use. They may come with various degrees of caveat regarding their perceived quality and potential for change, such as “alpha”, “beta”, “incubating”, “stable”, etc.

The Flink community treats releases with great importance. They are a public face of the project and most users interact with the project only through the releases. Releases are signed off by the entire Flink community in a public vote.

Each release is executed by a *Release Manager*, who is selected/proposed by the [Flink PMC members](http://flink.apache.org/community.html#people). This document describes the process that the Release Manager follows to perform a release. Any changes to this process should be discussed and adopted on the [dev@ mailing list](http://flink.apache.org/community.html#mailing-lists).

Please remember that publishing software has legal consequences. This guide complements the foundation-wide [Product Release Policy](http://www.apache.org/dev/release.html) and [Release Distribution Policy](http://www.apache.org/dev/release-distribution).

## Overview

![](https://cwiki.apache.org/confluence/download/attachments/73631092/release-guide-1.png?version=1&modificationDate=1501073770000&api=v2)

The release process consists of several steps:

1. Decide to release
2. Prepare for the release
3. Build a release candidate
4. Vote on the release candidate
5. If necessary, fix any issues and go back to step 3.
6. Finalize the release
7. Promote the release

## Decide to release

Deciding to release and selecting a Release Manager is the first step of the release process. This is a consensus-based decision of the entire community.

Anybody can propose a release on the dev@ mailing list, giving a solid argument and nominating a committer as the Release Manager (including themselves). There’s no formal process, no vote requirements, and no timing requirements. Any objections should be resolved by consensus before starting the release.

In general, the community prefers to have a rotating set of 3-5 Release Managers. Keeping a small core set of managers allows enough people to build expertise in this area and improve processes over time, without Release Managers needing to re-learn the processes for each release. That said, if you are a committer interested in serving the community in this way, please reach out to the community on the dev@ mailing list.

### Checklist to proceed to the next step

1. Community agrees to release
2. Community selects a Release Manager

## Prepare for the release

Before your first release, you should perform one-time configuration steps. This will set up your security keys for signing the release and access to various release repositories.

To prepare for each release, you should audit the project status in the JIRA issue tracker, and do necessary bookkeeping. Finally, you should create a release branch from which individual release candidates will be built.

### One-time setup instructions

#### GPG Key

You need to have a GPG key to sign the release artifacts. Please be aware of the ASF-wide [release signing guidelines](https://www.apache.org/dev/release-signing.html). If you don’t have a GPG key associated with your Apache account, please create one according to the guidelines.

Determine your Apache GPG Key and Key ID, as follows:

```
gpg --list-keys
```

```
This will list your GPG keys. One of these should reflect your Apache account, for example:
```

```
--------------------------------------------------
pub   2048R/845E6689 2016-02-23
uid                  Nomen Nescio <anonymous@apache.org>
sub   2048R/BA4D50BE 2016-02-23
```

Here, the key ID is the 8-digit hex string in the `pub` line: `845E6689`.

Now, add your Apache GPG key to the Flink’s `KEYS` file in the [`release`](https://dist.apache.org/repos/dist/release/flink/KEYS) repository at `dist.apache.org`. Follow the instructions listed at the top of these files. (Note: Only PMC members have write access to the release repository. If you end up getting 403 errors ask on the mailing list for assistance.) PMC member can refer following scripts to add your Apache GPG key to the KEYS in the release repository.

```
svn co https://dist.apache.org/repos/dist/release/flink flink-dist-release-repo
cd flink-dist-release-repo
(gpg --list-sigs <YOUR_KEY_ID> && gpg --armor --export <YOUR_KEY_ID>) >> KEYS
svn ci -m "[flink] Add <YOUR_NAME>'s public key"
```

Configure `git` to use this key when signing code by giving it your key ID, as follows:

```
git config --global user.signingkey 845E6689
```

You may drop the `--global` option if you’d prefer to use this key for the current repository only.

You may wish to start `gpg-agent` to unlock your GPG key only once using your passphrase. Otherwise, you may need to enter this passphrase hundreds of times. The setup for `gpg-agent` varies based on operating system, but may be something like this:

```
eval $(gpg-agent --daemon --no-grab --write-env-file $HOME/.gpg-agent-info)
export GPG_TTY=$(tty)
export GPG_AGENT_INFO
```

#### Access to Apache Nexus repository

Configure access to the [Apache Nexus repository](https://repository.apache.org/), which enables final deployment of releases to the Maven Central Repository.

1. You log in with your Apache account.
2. Confirm you have appropriate access by finding `org.apache.flink` under `Staging Profiles`.
3. Navigate to your `Profile` (top right dropdown menu of the page).
4. Choose `User Token` from the dropdown, then click `Access User Token`. Copy a snippet of the Maven XML configuration block.
5. Insert this snippet twice into your global Maven `settings.xml` file, typically `${HOME}/.m2/settings.xml`. The end result should look like this, where `TOKEN_NAME` and `TOKEN_PASSWORD`are your secret tokens:

   **settings.xml**

   ```
   <settings>
      <servers>
        <server>
          <id>apache.releases.https</id>
          <username>TOKEN_NAME</username>
          <password>TOKEN_PASSWORD</password>
        </server>
        <server>
          <id>apache.snapshots.https</id>
          <username>TOKEN_NAME</username>
          <password>TOKEN_PASSWORD</password>
        </server>
      </servers>
    </settings>
   ```

#### Website development setup

Get ready for updating the Flink website by following the [website development instructions](https://flink.apache.org/contributing/improve-website.html).

#### GNU Tar Setup for Mac

Skip this step if you are not using a Mac. The default tar application on Mac does not support GNU archive format and defaults to Pax. This bloats the archive with unnecessary metadata that can result in additional files when decompressing (see [1.15.2-RC2 vote thread](https://lists.apache.org/thread/mzbgsb7y9vdp9bs00gsgscsjv2ygy58q)). Install gnu-tar and create a symbolic link to use in preference of the default tar program.

```
brew install gnu-tar
ln -s /opt/homebrew/bin/gtar /usr/local/bin/tar
# Make sure which directory "gtar" is installed to, at the time of writing it is "/opt/homebrew/bin/gtar"
which tar
```

Note on the Mac, by default "tar" points to */usr/bin/tar.* So either change your PATH to pick up  */usr/local/bin/* first or call "gtar" instead of "tar".

```

```

### Create a new version in JIRA

When contributors resolve an issue in JIRA, they are tagging it with a release that will contain their changes. With the release currently underway, new issues should be resolved against a subsequent future release. Therefore, you should create a release item for this subsequent release, as follows:

1. In JIRA, navigate to the [Flink`> Administration > Versions`](https://issues.apache.org/jira/plugins/servlet/project-config/FLINK/versions).
2. Add a new release: choose the next minor version number compared to the one currently underway, select today’s date as the `Start Date`, and choose `Add`.

(Note: Only PMC members have access to the project administration. If you do not have access, ask on the mailing list for assistance.)

### Triage release-blocking issues in JIRA

There could be outstanding release-blocking issues, which should be triaged before proceeding to build a release candidate. We track them by assigning a specific `Fix version` field even before the issue resolved.

The list of release-blocking issues is available at the [version status page](https://issues.apache.org/jira/browse/FLINK/?selectedTab=com.atlassian.jira.jira-projects-plugin:versions-panel). Triage each unresolved issue with one of the following resolutions:

* If the issue has been resolved and JIRA was not updated, resolve it accordingly.
* If the issue has not been resolved and it is acceptable to defer this until the next release, update the `Fix Version` field to the new version you just created. Please consider discussing this with stakeholders and the dev@ mailing list, as appropriate.
  + When using "Bulk Change" functionality of Jira
    - First, add the newly created version to `Fix Version` for all unresolved tickets that have old the old version among its `Fix Version`s.
    - Afterwards, remove the old version from the `Fix Version`.
* If the issue has not been resolved and it is not acceptable to release until it is fixed, the release cannot proceed. Instead, work with the Flink community to resolve the issue.

### Review and update documentation

There are a few pages in the documentation that need to be reviewed and updated for each release.

* Ensure that there exists a release notes page for each non-bugfix release (e.g., 1.5.0) in `./docs/release-notes`/, that it is up-to-date, and linked from the start page of the documentation.
* [Upgrading Applications and Flink Versions: https://ci.apache.org/projects/flink/flink-docs-master/ops/upgrading.html](https://ci.apache.org/projects/flink/flink-docs-master/ops/upgrading.html)
* please extend this list.

### Cross team testing

For user facing features that go into the release we'd like to ensure they can actually *be used*by Flink users. To achieve this the release managers ensure that an issue for cross team testing is created in the Apache Flink Jira. This can and should be picked up by other community members to verify the functionality and usability of the feature.
The issue should contain some entry points which enables other community members to test it. It should not contain documentation on how to use the feature as this should be part of the actual documentation. The cross team tests are performed after the feature freeze. Documentation should be in place before that. Those tests are manual tests, so do not confuse them with automated tests.
To sum that up:

* User facing features should be tested by other contributors
* The scope is usability and sanity of the feature
* The feature needs to be already documented
* The contributor creates an issue containing some pointers on how to get started (e.g. link to the documentation, suggested targets of verification)
* Other community members pick those issues up and provide feedback
* Cross team testing happens right after the feature freeze

### Unless the pages have not been updated before, please create a JIRA ticket and mark it as release blocker.

### Setup environment variables

Set up a few environment variables to simplify commands that follow. (We use `bash` Unix syntax in this guide.)

```
RELEASE_VERSION="1.5.0"
SHORT_RELEASE_VERSION="1.5"
CURRENT_SNAPSHOT_VERSION="$SHORT_RELEASE_VERSION-SNAPSHOT"
NEXT_SNAPSHOT_VERSION="1.6-SNAPSHOT"
SHORT_NEXT_SNAPSHOT_VERSION="1.6"
```

### Review Release Notes in JIRA

JIRA automatically generates Release Notes based on the `Fix Version` field applied to issues. Release Notes are intended for Flink users (not Flink committers/contributors). You should ensure that Release Notes are informative and useful.

Open the release notes from the [version status page](https://issues.apache.org/jira/browse/FLINK/?selectedTab=com.atlassian.jira.jira-projects-plugin:versions-panel) by choosing the release underway and clicking Release Notes.

You should verify that the issues listed automatically by JIRA are appropriate to appear in the Release Notes. Specifically, issues should:

* Be appropriately classified as `Bug`, `New Feature`, `Improvement`, etc.
* Represent noteworthy user-facing changes, such as new functionality, backward-incompatible API changes, or performance improvements.
* Have occurred since the previous release; an issue that was introduced and fixed between releases should not appear in the Release Notes.
* Have an issue title that makes sense when read on its own.

Adjust any of the above properties to the improve clarity and presentation of the Release Notes.

Ensure that the JIRA release notes are also included in the release notes of the documentation (see section "Review and update documentation").

#### Content of Release Notes field from JIRA tickets

To get the list of "release notes" field from JIRA, you can ran the following script using JIRA REST API (notes the maxResults limits the number of entries):

```
curl -s https://issues.apache.org/jira//rest/api/2/search?maxResults=200&jql=project%20%3D%20FLINK%20AND%20%22Release%20Note%22%20is%20not%20EMPTY%20and%20fixVersion%20%3D%20${RELEASE_VERSION} | jq '.issues[]|.key,.fields.summary,.fields.customfield_12310192' | paste - - -
```

`jq`  is present in most Linux distributions and on MacOS can be installed via brew.

### Verify Java and Maven Version

All of the following steps require to use **Maven 3.9.16 and Java 8 (for 1.x series) or Java 11 (for 2.0 or later)**. Modify your PATH environment variable (or using tools like jenv) accordingly if needed.

Please make sure you are using Maven 3.9.16 and Java 8(for 1.x series) or Java 11 (for 2.0 or later)

### Clone flink into a fresh workspace

Create a new directory for this release and clone the Flink repo from github to ensure you have a clean workspace. This step is optional.

### Verify that a Release Build Works

Run `mvn -Prelease clean install` to ensure that the build processes that are specific to that profile are in good shape. This step is optional.

### Verify that no exclusions were erroneously added to the japicmp plugin that break compatibility guarantees

Check the exclusions for the japicmp-maven-plugin in the root pom for exclusions that:

* for minor releases, break source compatibility for  `@Public` APIs
* for patch releases, break source/binary compatibility for `@Public`  / `@PublicEvolving`  APIs

Any such exclusion must be properly justified, in advance.

### Create a release branch

Release candidates are built from a release branch. As a final step in preparation for the release, you should create the release branch, push it to the code repository (you should probably do this once the whole process is done), and update version information on the original branch.



Most of the following commands have to be executed in the `tools` directory, we will prefix the command prompt to make this explicit.

Major release

#### Major release

If you are doing a new major release, you need to update Flink version in the following repositories

##### Flink repository

Create a branch for the new version that we want to release before updating the master branch to the next development version:

```
tools $ releasing/create_snapshot_branch.sh
tools $ git checkout master
tools $ OLD_VERSION=$CURRENT_SNAPSHOT_VERSION NEW_VERSION=$NEXT_SNAPSHOT_VERSION releasing/update_branch_version.sh
```

In the master branch, add a new value (i.e. `v1_16("1.16")`) to the `FlinkVersion` enum, as the last entry. The enum resides under `flink-annotations` module in `org.apache.flink` package:

```
v1_12("1.12"),
v1_13("1.13"),
v1_14("1.14"),
v1_15("1.15"),
v1_16("1.16");
```

##### Flink CI runs

1. In `master`, update the branch list of the GitHub Actions nightly workflow (see [apache/flink:.github/workflows/nightly-trigger.yml#L31ff](https://github.com/apache/flink/blob/master/.github/workflows/nightly-trigger.yml#L31)): The two most-recent releases and `master` should be covered.
2. In Azure DevOps for flink-master-mirror (see <https://dev.azure.com/apache-flink/apache-flink/_build?definitionId=1>), you need to go to Edit → Click on the 3 dots under each other → Triggers → Go to scheduled → make sure that you have the two most-recent releases and `master`  as included branch filters → Click on `Save & Queue` → Click on `Save`

The newly created branch and updated master branch need to be pushed to the official repository.

##### Flink Docker repository

Afterwards fork off from `dev-master` a `dev-x.y` branch in the <https://github.com/apache/flink-docker> repository. Make sure that `flink-docker/.github/workflows/ci.yml` points to the correct snapshot version; for `dev-x.y` it should point to `x.y-SNAPSHOT`, while for `dev-master` it should point to the most recent snapshot version (`$NEXT_SNAPSHOT_VERSION`).

After pushing the new major release branch, as the last step you should also update the documentation workflow to also build the documentation for the new release branch. Check [Managing Documentation](https://cwiki.apache.org/confluence/spaces/FLINK/pages/85470059/Managing+Documentation) on details on how to do that. You may also want to manually trigger a build to make the changes visible as soon as possible.

##### Flink Benchmarks repository

First of all, checkout the `master` branch to `dev-x.y` branch in <https://github.com/apache/flink-benchmarks>, so that we can have a branch named `dev-x.y` which could be built on top of ($`CURRENT_SNAPSHOT_VERSION`).

Then, inside the repository you need to manually update the `flink.version`property inside the main **pom.xml** file for `master` branch. It should be pointing to the most recent snapshot version (`$NEXT_SNAPSHOT_VERSION`). For example:

```
<flink.version>1.18-SNAPSHOT</flink.version>
```

Minor release

#### Minor release

If you're creating a new minor release you do not need to modify Flink Benchmarks. You will skip the "Major release" step and simply check out the the already existing branch for that version:

```
tools $ git checkout release-$SHORT_RELEASE_VERSION
```

The rest of this guide assumes that commands are run in the root (or tools directory) of a repository on the branch of the release version with the above environment variables set.

### Checklist to proceed to the next step

1. Release Manager’s GPG key is published to `dist.apache.org`
2. Release Manager’s GPG key is configured in `git` configuration
3. Release Manager's GPG key is configured as the default gpg key.
4. Release Manager has `org.apache.flink` listed under `Staging Profiles` in Nexus
5. Release Manager’s Nexus User Token is configured in `settings.xml`
6. There are no release blocking JIRA issues
7. Release Notes in JIRA have been audited and adjusted
8. Update upgrade compatibility table (docs/ops/[upgrading.md](http://upgrading.md)).
9. Update [Release Overview in Confluence](https://cwiki.apache.org/confluence/display/FLINK/Release+Management+and+Feature+Plan)
10. (major only) Release branch has been created and pushed
    1. Cron job has been added on the release branch in (tools/azure-pipelines/[build-apache-repo.yml](https://github.com/apache/flink/blob/master/tools/azure-pipelines/build-apache-repo.yml)) and Azure DevOps pipelines
11. (major only) Originating branch has the version information updated to the new version
12. (major only) New version is added to the `FlinkVersion` Enum.
13. (major only) Make sure flink-docker has dev-x.y branch and docker e2e tests run against this branch
14. (major only) docs/config.toml has been updated appropriately.
15. (major only) The documentation for the new major release is visible under <https://nightlies.apache.org/flink/flink-docs-release-$SHORT_RELEASE_VERSION> (after at least one doc build finishes).
16. (major only) The documentation for the new major release does not contain "-SNAPSHOT" in its version title, and all links refer to the corresponding version docs instead of master.
17. (major only) The `flink.version` property of Flink Benchmark repo has been updated to the latest snapshot version.

## Build a release candidate

The core of the release process is the build-vote-fix cycle. Each cycle produces one release candidate. The Release Manager repeats this cycle until the community approves one release candidate, which is then finalized.

### Build and stage Java and Python artifacts

Set up a few environment variables to simplify Maven commands that follow. This identifies the release candidate being built. Start with `RC_NUM` equal to `1` and increment it for each candidate.

```
RC_NUM="1"
TAG="release-${RELEASE_VERSION}-rc${RC_NUM}"
```

Now, create a release branch (![(warning)](https://cwiki.apache.org/confluence/s/-2gn2bt/9116/n2r6gc/_/images/icons/emoticons/warning.svg) this step can **not** be skipped for minor releases):

```
$ cd tools
tools $ OLD_VERSION=$CURRENT_SNAPSHOT_VERSION NEW_VERSION=$RELEASE_VERSION RELEASE_CANDIDATE=$RC_NUM releasing/create_release_branch.sh
```

Tag the release commit:

```
git tag -s ${TAG} -m "${TAG}"
```

You can use `-c "user.signingkey=<gpg-fingerprint>"` as an additional git parameter if you have multiple signing keys in your keychain.

We now need to do several things:

* Create the source release archive
* Deploy jar artefacts to the [Apache Nexus Repository](https://repository.apache.org/), which is the staging area for deploying the jars to Maven Central
* Build PyFlink wheel packages (since 1.11)

You might want to create a directory on your local machine for collecting the various source and binary releases before uploading them. Creating the binary releases is a lengthy process but you can do this on a another machine (for example, in the "cloud"). When doing this, you can skip signing the release files on the remote machine, download them to your local machine and sign them there.

First, we build the source release:

```
tools $ RELEASE_VERSION=$RELEASE_VERSION releasing/create_source_release.sh
```

Next, we stage the maven artifacts:

```
tools $ releasing/deploy_staging_jars.sh
```

Review all staged artifacts in the staging repositories(<https://repository.apache.org/#stagingRepositories>). They should contain all relevant parts for each module, including `pom.xml`, jar, test jar, source, test source, javadoc, etc. Carefully review any new artifacts.

Close the staging repository on Apache Nexus. When prompted for a description, enter “Apache Flink, version X, release candidate Y“.

Then, you need to build the PyFlink wheel packages.(since 1.11)

1. Push the release candidate branch to your forked personal Flink repository, e.g.

   ```
   tools $ git push <remote> refs/heads/release-${RELEASE_VERSION}-rc${RC_NUM}:release-${RELEASE_VERSION}-rc${RC_NUM}
   ```
2. Trigger the “Nightly (beta)“ GitHub workflow manually
   1. Go to your GitHub fork website page
   2. Under the “Actions“ tab, click “Nightly (beta)“
   3. Select your recently pushed release candidate branch
   4. You should now see that a new run is triggered
3. Download the PyFlink wheel packages from the triggered “Nightly (beta)“ run artifacts after the “Build Python wheels on linux“ and “Build Python wheels on macos“ have finished.
   1. Download the PyFlink wheel packages
      1. Open the workflow run result page
      2. Scroll down to the “Artifacts“ section
      3. Click `wheel_linux_nightly-beta-1`  and `wheel_macos_nightly-beta-1`  separately to download the zip files
   2. Unzip these two zip files

      ```
      $ cd /path/to/downloaded_wheel_packages
      $ unzip wheel_Linux_build_wheels\ wheel_Linux_build_wheels_on_Linux.zip
      $ unzip wheel_Darwin_build_wheels\ wheel_Darwin_build_wheels_on_macos.zip
      ```

      If the unzipped content is still an archive (e.g. `tar.gz`), make sure to extract that as well.
   3. Create directory `dist` under the directory of `flink-python`

      ```
      $ cd <flink-dir>
      $ mkdir flink-python/dist
      ```
   4. Move the unzipped wheel packages to the directory of `flink-python/dist`

      ```
      $ mv /path/to/wheel_Darwin_build_wheels\ mac/* flink-python/dist/
      $ mv /path/to/wheel_Linux_build_wheels\ linux/* flink-python/dist/
      $ cd tools
      ```

Finally, we create the binary convenience release files:

```
tools $ RELEASE_VERSION=$RELEASE_VERSION releasing/create_binary_release.sh
```

If you want to run this step in parallel on a remote machine you have to make the release commit available there (for example by pushing to a repository). **This is important****: the commit inside the binary builds has to match the commit of the source builds and the tagged release commit.**When building remotely, you can skip gpg signing by setting  `SKIP_GPG=true`. You would then sign the files manually after downloading them to your machine:

```
for f in flink-*-bin*.tgz; do gpg --armor --detach-sig $f; done
gpg --armor --detach-sig apache_flink*.tar.gz
gpg --armor --detach-sig apache_flink*.whl
```

The release manager need to make sure the PyPI project `apache-flink` and `apache-flink-libraries` has enough available space for the python artifacts. The remaining space must be larger than the size of `tools/releasing/release/python`. Login with the PyPI admin account ([account info](https://lists.apache.org/thread.html/8273a5e8834b788d8ae552a5e177b69e04e96c0446bb90979444deee@%3Cprivate.flink.apache.org%3E) is only available to PMC members) and check the remaining space in [project settings](http://pypi.org/manage/project/apache-flink-libraries/settings).

Request an increase if there's not enough space. Note, it could take some days for PyPI to review our request.

### Stage source and binary releases on [dist.apache.org](http://dist.apache.org)

Copy the source release to the dev repository of `dist.apache.org`.

1. If you have not already, check out the Flink section of the `dev` repository on `dist.apache.org` via Subversion. In a fresh directory:

   ```
   svn checkout https://dist.apache.org/repos/dist/dev/flink --depth=immediates
   ```
2. Make a directory for the new release:

   ```
   mkdir flink/flink-${RELEASE_VERSION}-rc${RC_NUM}
   ```

   ```
   Copy Flink source/binary distributions, hashes, and GPG signature and the python subdirectory:
   ```

   ```
   mv <flink-dir>/tools/releasing/release/* flink/flink-${RELEASE_VERSION}-rc${RC_NUM}
   ```
3. Add and commit all the files.

   ```
   cd flink
   svn add flink-${RELEASE_VERSION}-rc${RC_NUM}
   svn commit -m "Add flink-${RELEASE_VERSION}-rc${RC_NUM}"
   ```
4. Verify that files are [present](https://dist.apache.org/repos/dist/dev/flink)

**(Push the release tag)**

If you haven't pushed the release tag yet, here's the command:

```
git push <remote> refs/tags/release-${RELEASE_VERSION}-rc${RC_NUM}
```

### Propose a pull request for website updates

The final step of building the candidate is to propose a website pull request containing the following changes:

* update docs/data/flink.yml
  + Add a new major version or update minor version as required
* update docs/data/release\_archive.yml
* update version references in quickstarts (`q/` directory) as required (outdated?)
* add a blog post announcing the release in `_posts`
* (major, or minor release of latest stable version) update FlinkStableVersion in docs/config.toml to point to release version.
* (major only) add a organized release notes page under docs/content/release-notes and docs/content.zh/release-notes (like <https://nightlies.apache.org/flink/flink-docs-release-1.15/release-notes/flink-1.15/>). The page is based on the non-empty release notes collected from the issues, and only the issues that affect existing users should be included (e.g., instead of new functionality). It should be in a separate PR since it would be merged to the flink project.

Don’t merge the PRs before finalizing the release.

### Checklist to proceed to the next step

1. Maven artifacts deployed to the staging repository of [repository.apache.org](https://repository.apache.org/content/repositories/)
2. Source distribution deployed to the dev repository of [dist.apache.org](https://dist.apache.org/repos/dist/dev/flink/)
3. Website pull request proposed to list the [release](http://flink.apache.org/downloads.html)
4. (major only) Check `docs/config.toml` to ensure that
   * the version constants refer to the new version
   * the `baseurl` does not point to `flink-docs-master`  but `flink-docs-release-X.Y` instead

You can (optionally) also do additional verification by:

1. ```
   Check hashes (e.g. shasum -c *.sha512)
   ```
2. Check signatures (e.g. `gpg --verify flink-1.2.3-source-release.tar.gz.asc flink-1.2.3-source-release.tar.gz`)
3. `grep` for legal headers in each file.
4. If time allows check the NOTICE files of the modules whose dependencies have been changed in this release in advance, since the license issues from time to time pop up during voting. See [Verifying a Flink Release](https://cwiki.apache.org/confluence/spaces/FLINK/pages/73631094/Verifying+a+Flink+Release) "Checking License" section.

## Vote on the release candidate

Once you have built and individually reviewed the release candidate, please share it for the community-wide review. Please review foundation-wide [voting guidelines](http://www.apache.org/foundation/voting.html) for more information.

Start the review-and-vote thread on the dev@ mailing list. Here’s an email template; please adjust as you see fit.

```
From: Release Manager
To: dev@flink.apache.org
Subject: [VOTE] Release 1.2.3, release candidate #3

Hi everyone,
Please review and vote on the release candidate #3 for the version 1.2.3, as follows:
[ ] +1, Approve the release
[ ] -1, Do not approve the release (please provide specific comments)


The complete staging area is available for your review, which includes:
* JIRA release notes [1],
* the official Apache source release and binary convenience releases to be deployed to dist.apache.org [2], which are signed with the key with fingerprint FFFFFFFF [3],
* all artifacts to be deployed to the Maven Central Repository [4],
* source code tag "release-1.2.3-rc3" [5],
* website pull request listing the new release and adding announcement blog post [6].

The vote will be open for at least 72 hours. It is adopted by majority approval, with at least 3 PMC affirmative votes.

Thanks,
Release Manager

[1] link
[2] link
[3] https://dist.apache.org/repos/dist/release/flink/KEYS
[4] link
[5] link
[6] link
```

**If there are any issues found in the release candidate, reply on the vote thread to cancel the vote.** There’s no need to wait 72 hours. Proceed to the `Fix Issues` step below and address the problem. However, some issues don’t require cancellation. For example, if an issue is found in the website pull request, just correct it on the spot and the vote can continue as-is.

For cancelling a release, the release manager needs to send an email to the release candidate thread, stating that the release candidate is officially cancelled. Next, all artifacts created specifically for the RC in the previous steps need to be removed:

* Delete the staging repository in Nexus
* Remove the source / binary RC files from dist.apache.org
* Delete the source code tag in git

**If there are no issues**, reply on the vote thread to close the voting. Then, tally the votes in a separate email. Here’s an email template; please adjust as you see fit.

```
From: Release Manager
To: dev@flink.apache.org
Subject: [RESULT] [VOTE] Release 1.2.3, release candidate #3

I'm happy to announce that we have unanimously approved this release.

There are XXX approving votes, XXX of which are binding:
* approver 1
* approver 2
* approver 3
* approver 4

There are no disapproving votes.

Thanks everyone!
```

### Checklist to proceed to the finalization step

1. Community votes to release the proposed candidate, with at least three approving PMC votes

Fix any issues

Any issues identified during the community review and vote should be fixed in this step.

Code changes should be proposed as standard pull requests to the `master` branch and reviewed using the normal contributing process. Then, relevant changes should be cherry-picked into the release branch. The cherry-pick commits should then be proposed as the pull requests against the release branch, again reviewed and merged using the normal contributing process.

Once all issues have been resolved, you should go back and build a new release candidate with these changes.

### Checklist to proceed to the next step

1. Issues identified during vote have been resolved, with fixes committed to the release branch.

## Finalize the release

Once the release candidate has been reviewed and approved by the community, the release should be finalized. This involves the final deployment of the release candidate to the release repositories, merging of the website changes, etc.

### Deploy Python artifacts to PyPI （Since 1.9）

Release manager should create a PyPI account and ask the PMC add this account to pyflink collaborator list with Maintainer role (~~The PyPI admin account info can be found [here](https://lists.apache.org/thread.html/8273a5e8834b788d8ae552a5e177b69e04e96c0446bb90979444deee@%3Cprivate.flink.apache.org%3E). NOTE, only visible to PMC members;~~) to deploy the Python artifacts to PyPI. The artifacts could be uploaded using twine(<https://pypi.org/project/twine/>). To install twine, just run:

```
pip install --upgrade twine==1.12.0
```

Note: Please ensure that the version of `urllib3`  is less than `2.0` in your python env, otherwise you may encounter some problem like `unexpected keyword argument method_whitelist`.

apitoken

Please note that Username/Password authentication is no longer supported. Please use API Tokens [https://pypi.org/help/#apitoken](https://pypi.org/help/#apitoken "Follow link").

Download the python artifacts from [dist.apache.org](http://dist.apache.org) and upload it to [pypi.org](http://pypi.org):

```
svn checkout https://dist.apache.org/repos/dist/dev/flink/flink-${RELEASE_VERSION}-rc${RC_NUM}
cd flink-${RELEASE_VERSION}-rc${RC_NUM}

cd python

#set credentials
export TWINE_USERNAME=__token__
export TWINE_PASSWORD=pypi-...

#uploads wheels
for f in *.whl; do twine upload -r pypi $f; done

#upload source packages
-- Since Flink 1.20.4 using the following commands
twine upload -r pypi apache_flink_libraries-${RELEASE_VERSION}.tar.gz
twine upload -r pypi apache_flink-${RELEASE_VERSION}.tar.gz

-- Before Flink 1.20.4 using the following commands
twine upload -r pypi apache-flink-libraries-${RELEASE_VERSION}.tar.gz
twine upload -r pypi apache-flink-${RELEASE_VERSION}.tar.gz
```

PyPI has removed GPG signatures support, so it is recommended to no longer upload signatures to PyPI.

If upload failed or incorrect for some reason(e.g. network transmission problem), you need to delete the uploaded release package of the same version(if exists) and rename the artifact to apache\_flink-${RELEASE\_VERSION}.post0.tar.gz, then re-upload.

Note: re-uploading to [pypi.org](http://pypi.org) must be avoided as much as possible because it will cause some irreparable problems. If that happens, users cannot install the apache-flink package by explicitly specifying the package version, i.e. the following command "pip install apache-flink==${RELEASE\_VERSION}" will fail. Instead they have to run "pip install apache-flink" or "pip install apache\_flink==${RELEASE\_VERSION}.post0" to install the apache-flink package.

### Deploy artifacts to Maven Central Repository

**Deploy artifacts to Maven Central Repository**

Use the [Apache Nexus](https://repository.apache.org) repository to release the staged binary artifacts to the Maven Central repository. In the `Staging Repositories` section, find the relevant release candidate `orgapacheflink-XXX` entry and click `Release`. Drop all other release candidates that are not being released.

#### Deploy source and binary releases to [dist.apache.org](http://dist.apache.org)

Copy the source and binary releases from the `dev` repository to the `release` repository at `dist.apache.org` using Subversion.

```
svn move -m "Release Flink ${RELEASE_VERSION}" https://dist.apache.org/repos/dist/dev/flink/flink-${RELEASE_VERSION}-rc${RC_NUM} https://dist.apache.org/repos/dist/release/flink/flink-${RELEASE_VERSION}
```

(Note: Only PMC members have access to the release repository. If you do not have access, ask on the mailing list for assistance.)

#### Remove old release candidates from [dist.apache.org](http://dist.apache.org)

Remove the old release candidates from <https://dist.apache.org/repos/dist/dev/flink> using Subversion.

**Remove old release candidates from dist.apache.org**

```
svn checkout https://dist.apache.org/repos/dist/dev/flink --depth=immediates
cd flink
svn remove flink-${RELEASE_VERSION}-rc*
svn commit -m "Remove old release candidates for Apache Flink ${RELEASE_VERSION}"
```

### Git tag

Create and push a new Git tag for the released version by copying the tag for the final release candidate, as follows:

```
git tag -s "release-${RELEASE_VERSION}" refs/tags/${TAG}^{} -m "Release Flink ${RELEASE_VERSION}"
git push <remote> refs/tags/release-${RELEASE_VERSION}
```

### Mark the version as released in JIRA

In JIRA, inside [version management](https://issues.apache.org/jira/plugins/servlet/project-config/FLINK/versions), hover over the current release and a settings menu will appear. Click `Release`, and select today’s date.

(Note: Only PMC members have access to the project administration. If you do not have access, ask on the mailing list for assistance.)

If PRs have been merged to the release branch after the the last release candidate was tagged, make sure that the corresponding Jira tickets have the correct Fix Version set.

### Publish the Dockerfiles for the new release

**Note:** the official Dockerfiles fetch the binary distribution of the target Flink version from an Apache mirror. After publishing the binary release artifacts, mirrors can take some hours to start serving the new artifacts, so you may want to wait to do this step until you are ready to continue with the "Promote the release" steps below.

Follow the instructions in the [flink-docker](https://github.com/apache/flink-docker) repo to build the new Dockerfiles and send an updated manifest to Docker Hub so the new images are built and published.

For major version, please update .github/workflows/docker\_push.yml as this [PR](https://github.com/apache/flink-docker/pull/246/files).

publishing to DockerHub: apache/flink

Please make sure "**[publishing to DockerHub: apache/flink](https://github.com/apache/flink-docker)**" is finished before the announce mail or announcement blog post is sent.

### Checklist to proceed to the next step

* Python artifacts released and indexed in the [PyPI](https://pypi.org/project/apache-flink/) Repository <https://pypi.org/project/apache-flink/#history>
* Maven artifacts released and indexed in the [Maven Central Repository](https://search.maven.org/#search%7Cga%7C1%7Cg%3A%22org.apache.flink%22) (usually takes about a day to show up)
* Source & binary distributions available in the release repository of <https://dist.apache.org/repos/dist/release/flink/>
* Dev repository <https://dist.apache.org/repos/dist/dev/flink/> is empty
* Release tagged in the source code repository
* Release version finalized in JIRA. (Note: Not all committers have administrator access to JIRA. If you end up getting permissions errors ask on the mailing list for assistance)
* Website contains links to new release binaries and sources in download page
* For major releases, the front page references the correct new major release version and directs to the correct link
* Dockerfiles in [flink-docker](https://github.com/apache/flink-docker) updated for the new Flink release and pull request opened on the Docker official-images with an updated manifest

## Promote the release

Once the release has been finalized, the last step of the process is to promote the release within the project and beyond. Please wait for 24h after finalizing the release in accordance with the [ASF release policy](http://www.apache.org/legal/release-policy.html#release-announcements).

### Update japicmp configuration

Update the japicmp reference version and wipe exclusions / enable API compatibility checks for `@PublicEvolving` APIs on the corresponding SNAPSHOT branch with the `update_japicmp_configuration.sh` script (see below).

For a new major release (x.y.0), run the same command also on the master branch for updating the japicmp reference version and removing out-dated exclusions in the japicmp configuration.

Make sure that all Maven artifacts are already pushed to Maven Central. Otherwise, there's a risk that CI fails due to missing reference artifacts.

```
tools $ NEW_VERSION=$RELEASE_VERSION releasing/update_japicmp_configuration.sh
tools $ cd ..
$ git add *
$ git commit -m "Update japicmp configuration for $RELEASE_VERSION"
```

### Merge website pull request

Merge the website pull request to [list the release](http://flink.apache.org/downloads.html). Make sure to regenerate the website as well, as it isn't build automatically.

### Remove outdated versions

#### dist.apache.org

For a new major release remove all release files older than 2 versions, e.g., when releasing 1.7, remove all releases <= 1.5.

For a new bugfix version remove all release files for previous bugfix releases in the same series, e.g., when releasing 1.7.1, remove the 1.7.0 release.

1. If you have not already, check out the Flink section of the `release` repository on `dist.apache.org` via Subversion. In a fresh directory:

   ```
    svn checkout https://dist.apache.org/repos/dist/release/flink --depth=immediates
    cd flink
   ```
2. Remove files for outdated releases and commit the changes.

   ```
    svn remove flink-<version_to_remove>
    svn commit
   ```
3. Verify that files  are [removed](https://dist.apache.org/repos/dist/release/flink)

   Remember to remove the corresponding download links from the website.

#### Mark deprecated version documentation as outdated

When releasing a new version (e.g., `1.17` ), the previous version (e.g., `1.15` ) becomes unsupported. Update `docs/config.toml`  in that branch (so in this example, in the `release-1.15`  branch) to show a warning banner to users:

```
  ShowOutDatedWarning = true
```

After a documentation rebuild, this displays a banner at the top of all documentation pages: "This documentation is for an out-of-date version of Apache Flink. We recommend you use the latest stable version."

##### Flink CI runs

1. In `master`, update the branch list of the GitHub Actions nightly workflow (see [apache/flink:.github/workflows/nightly-trigger.yml#L31ff](https://github.com/apache/flink/blob/master/.github/workflows/nightly-trigger.yml#L31)): Disable the cron job for the now-unsupported version.
2. In Azure DevOps for flink-master-mirror (see <https://dev.azure.com/apache-flink/apache-flink/_build?definitionId=1>), you need to go to Edit → Click on the 3 dots under each other → Triggers → Go to scheduled → make sure that you remove the now-unsupported version from included branch filters → Click on `Save & Queue` → Click on `Save`

### Apache mailing lists

Announce on the dev@ mailing list that the release has been finished.

Announce on the release on the user@ mailing list, listing major improvements and contributions.

Announce the release on the [announce@apache.org](mailto:announce@apache.org) mailing list.

```
From: Release Manager
To: dev@flink.apache.org, user@flink.apache.org, user-zh@flink.apache.org, announce@apache.org
Subject: [ANNOUNCE] Apache Flink 1.2.3 released

The Apache Flink community is very happy to announce the release of Apache Flink 1.2.3, which is the third bugfix release for the Apache Flink 1.2 series.

Apache Flink® is an open-source stream processing framework for distributed, high-performing, always-available, and accurate data streaming applications.

The release is available for download at:
https://flink.apache.org/downloads.html

Please check out the release blog post for an overview of the improvements for this bugfix release:
<blob post link>

The full release notes are available in Jira:
<jira release notes link>

We would like to thank all contributors of the Apache Flink community who made this release possible!

Feel free to reach out to the release managers (or respond to this thread) with feedback on the release process. Our goal is to constantly improve the release process. Feedback on what could be improved or things that didn't go so well are appreciated.

Regards,
Release Manager
```

### Recordkeeping

Use [reporter.apache.org](https://reporter.apache.org/addrelease.html?flink) to seed the information about the release into future project reports.

(Note: Only PMC members have access report releases. If you do not have access, ask on the mailing list for assistance.)

### Flink blog

Major or otherwise important releases should have a blog post. Write one if needed for this particular release. Minor releases that don’t introduce new major functionality don’t necessarily need to be blogged (see [flink-web PR #581 for Flink 1.15.3](https://github.com/apache/flink-web/pull/581) as an example for a minor release blog post).

Please make sure that the release notes of the documentation (see section "Review and update documentation") are linked from the blog post of a major release.
We usually include the names of all contributors in the announcement blog post. Use the following command to get the list of contributors:

```
# first line is required to make sort first with uppercase and then lower
export LC_ALL=C
export FLINK_PREVIOUS_RELEASE_BRANCH=<previousReleaseBranch>
export FLINK_CURRENT_RELEASE_BRANCH=<currentReleaseBranch>
# e.g.
# export FLINK_PREVIOUS_RELEASE_BRANCH=release-1.17
# export FLINK_CURRENT_RELEASE_BRANCH=release-1.18
git log $(git merge-base master $FLINK_PREVIOUS_RELEASE_BRANCH)..$(git show-ref --hash ${FLINK_CURRENT_RELEASE_BRANCH}) --pretty=format:"%an%n%cn" | sort  -u | paste -sd, | sed "s/\,/\, /g"
```

### Social media

Tweet, post on Facebook, LinkedIn, and other platforms. Ask other contributors to do the same.

### Flink Release Wiki page

Add a summary of things that went well or that went not so well during the release process. This can include feedback from contributors but also more generic things like the release have taken longer than initially anticipated (and why) to give a bit of context to the release process.

### End of Life for Unsupported versions

For major versions only. As per our [support policy for old Flink versions](https://flink.apache.org/downloads/#update-policy-for-old-releases) when we release a new 1.x version we should start a discussion thread to end support for old versions.

1. Check if there are any resolved critical/blocker issues in the version exiting support. For example if you have released 1.17.0 then 1.15 is now end of life.
2. Open a discussion thread to either 1/ start the final bugfix release or 2/ close the support window (example <https://lists.apache.org/thread/csm81mlcktobl00p37x9t2jkpwmj9m58>)

### Checklist to declare the process completed

1. Website pull request to [list the release](http://flink.apache.org/downloads.html) merged
2. Release announced on the user@ mailing list.
3. Blog post published, if applicable.
4. Release recorded in [reporter.apache.org](https://reporter.apache.org/addrelease.html?flink).
5. Release announced on social media.
6. Completion declared on the dev@ mailing list.
7. Update Homebrew: <https://docs.brew.sh/How-To-Open-a-Homebrew-Pull-Request> (seems to be done automatically - ~~at least for minor releases~~  for both minor and major releases)
8. Updated the japicmp configuration
   * corresponding SNAPSHOT branch japicmp reference version set to the just released version, and API compatibiltity checks for `@PublicEvolving`  was enabled
   * (major only) master branch japicmp reference version set to the just released version
   * (major only) master branch japicmp exclusions have been cleared
9. (major only) Update the list of previous version in `docs/config.toml` on the master branch.
10. Set ShowOutDatedWarning`: true` in `docs/config.toml` in the release branch of the *now deprecated* Flink version (i.e. for 1.15 if 1.17.0 is released, update the docs/config.toml in the release-1.15 branch)
11. (major only) Update stable and master alias in <https://github.com/apache/flink/blob/master/.github/workflows/docs.yml>

    ```
    if [ "${currentBranch}" = "master" ]; then
      echo "flink_alias=release-1.16" >> ${GITHUB_ENV}
    elif [ "${currentBranch}" = "release-1.14" ]; then
      echo "flink_alias=stable" >> ${GITHUB_ENV}
    fi
    ->
    if [ "${currentBranch}" = "master" ]; then
      echo "flink_alias=release-1.16" >> ${GITHUB_ENV}
    elif [ "${currentBranch}" = "release-1.15" ]; then
      echo "flink_alias=stable" >> ${GITHUB_ENV}
    fi
    ```
12. Update docs to "stable" in `docs/config.toml` in the branch of the *just-released* version:
    * `major`:
      + Change V`ersion` from `x.y-SNAPSHOT` to `x.y.z`, i.e. `1.6-SNAPSHOT` to `1.6.0`
      + Change V`ersionTitle` from `x.y-SNAPSHOT` to `x.y`, i.e. `1.6-SNAPSHOT` to `1.6`
      + Change Branch from `master` to `release-x.y`, i.e. `master` to `release-1.6`
      + Change `baseURL` from `//nightlies.apache.org/projects/flink/flink-docs-master` to `//nightlies.apache.org/projects/flink/flink-docs-release-x.y`
      + Change `javadocs_baseurl` from `//nightlies.apache.org/projects/flink/flink-docs-master` to `//nightlies.apache.org/projects/flink/flink-docs-release-x.y`
      + Change `IsStable` to `true`
    * `minor:`
      + Change V`ersion` to latest `x.y.z`
13. (major only) Update migration tests in master to cover migration from new version. Since 1.18, this step could be done automatically with the following steps. For more information please refer to [this page.](https://github.com/apache/flink/blob/master/flink-test-utils-parent/flink-migration-test-utils/README.md)
    1. **On the published release tag (e.g., release-1.16.0)**,

       1. Modify the content of the file [apache/flink:flink-test-utils-parent/flink-migration-test-utils/src/main/resources/most\_recently\_published\_version](https://github.com/apache/flink/blob/master/flink-test-utils-parent/flink-migration-test-utils/src/main/resources/most_recently_published_version) to the latest version (it would be "v1\_16" if sticking to the example where 1.16.0 was released).
       2. Re-install the module `flink-test-utils-parent` locally
       3. run the following command. The version (1.16 in the command above) should be replaced with the target one.

       ```
       $ mvn clean package -Pgenerate-migration-test-data -Dgenerate.version=1.16 -nsu -Dfast -DskipTests
       ```
    2. Commit the modification in step a and b with "*[release] Generate reference data for state migration tests based on release-1.xx.0*" to the corresponding release branch (e.g. `release-1.16` in our example), replace "xx" with the actual version (in this example "16"). You should use the Jira issue ID in case of [release]  as the commit message's prefix if you have a dedicated Jira issue for this task.
    3. Cherry-pick the commit to the master branch.
14. `(major only) Disable CI for no-longer supported version`
    1. The cron job for the now-unsupported version has been updated.
15. `(major only) Opened discussion thread for End of Life for Unsupported versions`

Here's good example for the [checklist for version 1.17](https://issues.apache.org/jira/browse/FLINK-31567?filter=12353073&jql=project%20%3D%20flink%20AND%20summary%20~%20%27Promote%20release%201.17%27)

## Improve the process

It is important that we improve the release processes over time. Once you’ve finished the release, please take a step back and look what areas of this process and be improved. Perhaps some part of the process can be simplified. Perhaps parts of this guide can be clarified.

If we have specific ideas, please start a discussion on the dev@ mailing list and/or propose a pull request to update this guide. Thanks!
