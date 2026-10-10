> Source: https://infra.apache.org/release-signing.html
> Snapshot: retrieved 2026-10-10

# Signing Releases

## Introduction

The first part of this document gives release managers a basic introduction to release signing. See under [Further reading](#reading) for links to authoritative sources of deeper information.

The second part answers some frequently-asked questions from people who download releases from Apache projects.

This document is informative and does not constitute policy.


## For release managers

### Important notes

All new **RSA** keys generated should be at least **4096** bits. **Do not** generate new **DSA** keys.

Recent research has revealed weaknesses in SHA-1, and thus in the DSA and 1024 bit RSA OpenPGP keys which must use this algorithm. Though no realistic attacks have been made public, experience with similar weaknesses in MD5 suggests that further advances may well lead to practical attacks within the next few years. This accords with current NIST guidance on DSA.

The impact of this weakness on Apache can be mitigated by action now. What needs to be done is a little involved, so we have provided complete instructions.

* Committers without a code signing key should read this document and follow these [instructions](https://infra.apache.org/openpgp.html#generate-key).
* Committers with a DSA key or an RSA key of length less than 2048 bits should generate a new key for signing releases. The original key does not need to be revoked yet. Follow this [guide](https://infra.apache.org/key-transition.html).
* Committers with RSA keys of length 2048 or more do not need to generate a new key yet. They should reconfigure their client to avoid the weakness by following these [instructions](https://infra.apache.org/openpgp.html#sha1) and wait for the next major OpenPGP revision.

How to find the length of your key is described [here](#key-length-how-to).

### The basics

Every artifact distributed by the Apache Software Foundation **must** be accompanied by one file containing an [OpenPGP-compatible ASCII armored detached signature](#openpgp-ascii-detach-sig) and another file containing a [SHA](https://infra.apache.org/release-signing#sha-checksum) or [MD5](https://infra.apache.org/release-signing#md5)) checksum.

* MD5 hashes are **deprecated**; please use SHA for new releases.
* **Avoid** further use of `SHA-1`.

Form the names of these files by adding to the name of the artifact the following suffixes:

* the signature by suffixing `.asc`
* the checksum by suffixing `.md5` or `.sha[1|256|512]` (as appropriate)

Release managers **must not** store private keys used to sign Apache releases on ASF hardware.

See the [release distribution policy](https://infra.apache.org/release-distribution.html#sigs-and-sums) for details.

### Why we sign releases

A signature allows anyone to verify that a file is identical to the one your project's release manager created. Since your project's release has a signature:

* users can make sure that what they received has not been modified in any way, either accidentally via a faulty transmission channel, or intentionally (with or without malicious intent).
* the Apache infrastructure team can verify the identity of a file.

[OpenPGP](#openpgp) [signatures](#verifying-signature) confer the usual advantages of digital signatures: authentication, integrity and non-repudiation. [MD5](#md5) and [SHA](#sha-checksum) checksums only provide the integrity part as they are not encrypted.

### Security checklist

* [Protect](#private-key-protection) your [private key](#public-private)
* Choose a [good passphrase](#passphrase)
* Opt for a reasonably [long key length](#key-length)

### Signing basics

* Signatures should be [ASCII armored and detached](#openpgp-ascii-detach-sig).
* You should [export](#export) your [public key](#public-private) and append the result to the appropriate [KEYS](#keys-policy) file(s).

### How do I sign a release?

Create a [OpenPGP compatible ASCII armored detached signature](#openpgp-ascii-detach-sig) for the released artifact. Upload the signature with the released artifact. See [here](#basics) for a basic overview.

### What Is an OpenPGP compatible ASCII armored detached signature?

It is

* an [OpenPGP](#openpgp) compatible
* [ASCII armored](#ascii)
* [detached signature](#detach-sig)

To create one using [GNU Privacy Guard](https://www.gnupg.org) for file
`foo.tar.gz`, type:

```
$ gpg --armor --output foo.tar.gz.asc --detach-sig foo.tar.gz
```

### What is an MD5 checksum?

MD5 is a [well known](http://www.faqs.org/rfcs/rfc1321.html) [message
digest algorithm](#message-digest). Many tools are available to calculate these sums. For example, you can use [OpenSSL](https://www.openssl.org/):

```
$ openssl md5 < file
```

Platform-specific applications are also common, such as `md5sum` on linux:

```
$ md5sum file
```

With GnuPG:

```
$ gpg --print-md MD5 [fileName] > [fileName].md5
```

Run the command in the same directory as the file so the output only contains the file name with no directory prefixes.

**Note** that the security of MD5 is now [questionable](#md5-security) and is only useful as part of a defense in depth.

### What is an SHA checksum?

Like [MD5](#md5), [SHA](http://www.ietf.org/rfc/rfc3174.txt) is a [message digest](#message-digest) algorithm. Using GnuPG, you can create a SHA1 signature as follows:

```
  $ gpg --print-md SHA1 [fileName] > [fileName].sha1
```

**Avoid** further use of [SHA-1](#sha1). `SHA256` and `SHA512` use the same `SHA` algorithm family with longer hash
lengths (256 and 512 bits respectively). These longer variations are less vulnerable to the weaknesses found in the algorithm family than `SHA1`. Apache recommends using [SHA512](#sha1).

To create a `SHA512` checksum use:

```
  $ sha512sum [fileName] > [fileName].sha512
```

Run the command in the same directory as the file so the output only contains the file name with no directory prefixes.

There are other members of the `SHA` family that are rarely used.

### Message digest algorithms

A message digest algorithm takes a document and produces a much smaller hash of that document. A good algorithm will produce different digests for very similar documents. A good algorithm makes it [infeasible](#infeasible) to create a message matching a given hash.

You can use a trusted digest for a document can be used to verify the contents of an untrusted file. You can deliver the digest, which has a small size over a secure but expensive channel while delivering the untrusted file over an insecure but inexpensive one. This is useful when distributing releases.

### Why infeasible and not impossible?

Responsible cryptography talks about infeasible cracks (rather than impossible ones) since this is more accurate. All current practical methods can be subjected to brute force attacks and so can be cracked. So a better question is whether attacks are feasible *given the current state of the art*.

### Applications that create OpenPGP-compatible signatures

Many applications are available (some commercial, some freeware, some software libre) to help you sign releases. Whichever one you choose, please subscribe to the appropriate security lists and keep the application fully patched.

Apache recommends that ASF release managers use [GNU Privacy Guard](https://www.gnupg.org).

### Where should I create the signatures?

Creating signatures requires the private key. Keep limited copies of the private key securely and confidentially. Though the file used
to store the private key is typically protected by encryption, it is vulnerable to dictionary attacks on the [passphrase](#passphrase). So keep this file secret.

Create signatures on the machine where you store the private key, on secure hardware with limited read permissions, protected by a good
[passphrase](#passphrase). Consider using removable media or an [isolated
installation](#isolated-installation).

A master private key used to sign Apache artifacts (or to secure communications with the ASF) is particularly valuable. If you want or need to be able to create signatures for other purposes (for example, signing email messages) in other, less secure, locations, create multiple [sub keys](#email-subkey) for these purposes.

Do **not** store your private key on any ASF machine. Do **not** create signatures on ASF machines.

### What is 'insecure memory'?

When you use [GNU Privacy Guard](http://www.gnupg.org) you may see a warning similar to:

```
gpg: WARNING: using insecure memory!
gpg: please see http://www.gnupg.org/faq.html for more information
```

If you are using GnuPG on Apache hardware, please read [this](#where). Do **not** carry out sensitive operations using a private key on ASF hardware.

If you encounter this issue elsewhere, it indicates that GnuPG cannot lock memory pages, so they may be swapped out to disc. It would
then be feasible for an attacker who had gained access to the machine to read the private key from the swap file. For more details, read the [FAQ](https://www.gnupg.org/faq.html).

### How secure does the machine I use to sign releases need to be?

If the code signing machine is [owned](http://www.catb.org/~esr/jargon/html/O/owned.html), it is only a matter of time before the key is compromised.

At a minimum, the machine should well maintained: kept up to date with security patches and with appropriate anti-virus and firewall software. The ideal is an isolated, well-maintained installation that you only use for creating releases. You can achieve this with a little effort by creating an [isolated installation](#isolated-installation) on a separate hard disc (which is physically disconnected when not in use signing releases) or a live CD.

### Is MD5 still secure?

Though [feasible](#infeasible) collision attacks that can defeat MD5 are known, they are still computationally expensive. MD5 may still be useful as an additional layer in a defense in depth, but Apache does **not recommend** it as your single security option.

### Is SHA-1 still secure?

Research has revealed weaknesses in this algorithm. Though there are no practical attacks known at the time of writing, experience with similar weaknesses in [MD5](#md5-security) suggest that code signers should move away from this algorithm.

Breaking the longest members of this family (`SHA512` and `SHA256`) is still considered [infeasible](#infeasible). Until [SHA-3](#sha3) is available, avoid new uses of `SHA-1` and use `SHA512` or `SHA256` instead.

#### What is SHA-3?

SHA-3 is the designation for a new [cryptographic hash algorithm](#message-digest) to replace the SHA family. The full standard was issued in 2015, but it hasn't yet been officially introduced into the OpenPGP standard. For that reason GnuPG doesn't support it yet.

### Which standard cryptographic hash algorithms are secure?

[Feasible](#infeasible) - though expensive - attacks on MD5 have been made public. Similar weaknesses have been found in the SHA family of hashes, though practical attacks are not yet publicly known. However, longer hash sizes offer considerable protection, so larger members of the SHA family still look likely to be secure enough for a number of years.

SHA512 is the strongest well-studied, widely-used cryptographic hash. It is therefore the best recommendation until [SHA3](#sha3) is available.

### How to generate a code signing key

The exact mechanics are [application](#openpgp-applications)-dependent. For GnuPG (recommended):

* Follow the [strong key generation instructions](https://infra.apache.org/openpgp.html#generate-key)
* Decide on the [right key length](#key-length)
* Configure the tool to [avoid SHA-1](#sha1)
* Choose a good [passphrase](#passphrase)
* Use the recommended [id](#user-id) and [comment](#key-comment)

### The OpenPGP User-ID to use for your code-signing key

We recommend that you use your Apache email address as the primary `User-ID` for the code signing key. For example, `rdonkin@apache.org`.

### The OpenPGP comment to choose for your code-signing key

The comment should include *CODE SIGNING KEY*. This makes clear the primary use for this key. This can be helpful if you later
generate keys for other uses.

Include the comment *NOT FOR CODE SIGNING* for keys you generate for other purposes.

### What is a public key server?

A public key server manages [public keys](#public-private). Available functions may vary but typically include [upload](#keyserver-upload), search, and download.

Public key servers exist to distribute public keys. They do not vouch for the actual identity of the owner of each key. You must establish this either directly or through a [web of trust](#web-of-trust). Do not trust a key just because it has been downloaded from a key server.

The major public key servers synchronize their records regularly so you only need to upload a key to one and rely on that server to disseminate it to the other key servers. We recommend using [OpenPGP Public Key Server](https://keys.openpgp.org/).

### How to upload a key to a public key server

There are two common ways to upload a key to a [public key server](#keyserver):

* Most key servers let you upload [exports](#export) through their websites
* Use automatic facilities built into most [OpenPGP](#openpgp) [implementations](#openpgp-applications)

For example, using [GNU Privacy Guard](https://www.gnupg.org), send the key with [ID](#key-id) B1313DE2 to the default public key server by:

```
$ gpg --send-key B13131DE2
```

You must export each changed key separately.

### How to make sure your local web of trust is up-to-date

The public web of trust grows constantly as people sign new keys and upload the new signatures onto the network of [public key servers](#keyserver). You should refresh public keys periodically to make sure that your local web of trust is as full as possible. Many [OpenPGP](#openpgp) [clients](#openpgp-applications) make it easy to refresh keys by
querying a public key server. For example, to refresh all keys using [GNU Privacy Guard](https://www.gnupg.org), use:

```
$ gpg --refresh-keys
```

### How to export a key

You can export a public key through [OpenPGP](https://www.gnupg.org) by using
`--export`. Typically, the export should be ASCII armored.

To export all public keys to the command line use:

```
gpg --export --armor
```

In most cases, it is better to export all keys - this ensures that signatures made on other keys will be exported. However, it is possible to export just one key by specifying it on the command line.

You can export secret keys. However, this poses a security risk and there are better solutions for most common use cases. For
example, copying the `GNUPGHOME` directory (typically `~/.gnupg`) is a better way to transfer an [OpenPGP](https://www.gnupg.org) keyring from one machine to another.

### What a key ID is

A key ID is similar to a [fingerprint](#fingerprint) but is much smaller in length. There is no guarantee that key IDs are unique. Consequently, we strongly recommend that you check the key's fingerprint before signing with it. People us key IDs for locating keys and identifying keys already contained within the keyring.

A short guide to discovering the key ID for a key is [available](https://infra.apache.org/openpgp.html#find-key-id).

### What a sub key is

Each [OpenPGP](#openpgp) keyring has a single master key. This key is for signing only. It may also optionally have a number of sub keys for encryption and signing.

If you want to sign emails using a key related to one you use to sign code, we recommend that you use a signing [sub key](#email-subkey).

### How to use a sub key to sign emails

To keep a code signing key [safe and secure](#safe-and-secure) we recommend that you don't keep the key on a drive on a regular development machine. This means that you should not use the master key directly to sign emails. However, there are occasions when digitally signed emails are desirable.

To do that, create a sub key for email signing and export it to your regular machine. You can then keep the master key safely
offline. For more details, read [Subkey cross
certification](https://www.gnupg.org/(en)/faq/subkey-cross-certify.html).

**Note** that some [public key servers](#keyserver) do not handle sub keys correctly. It may be necessary to use one on the
[SKS](https://bitbucket.org/skskeyserver/sks-keyserver/wiki/Home) network.

### A quick way to sign several distributions

The private `https://svn.apache.org/repos/private/committers` repository contains scripts that assist with batch signing several distributions at one time.

### How to transfer a secret key

The way to transfer secret keys depends on the application you are using. Instructions for GnuPG are [available](https://infra.apache.org/openpgp.html#secret-key-transfer).

### Why some people have two keys

When you switch from an uncompromised key to another, usually stronger, one, it is convenient to use a [transition period](#transition). During a transition, both keys are trustworthy but you only use the newer one to sign documents and certify links in the [web of trust](#web-of-trust).

### What a transition period for keys is

When you replace one uncompromised key with a newer and usually larger one, a transition period during which both keys are trustworthy and participate in the [web of trust](#web-of-trust) allows - by [trust transitivity](#web-of-trust) - links to the old key to be used to trust signatures and links created by the new key. During a transition, both keys are trustworthy but you only use the newer oneto sign documents and certify links in the [web of trust](#web-of-trust).

### How to transition from a short to a longer key

If you have a short but uncompromised key and would like to [transition](#transition) to a longer one, follow these
[instructions](https://infra.apache.org/key-transition.html).

If your key has been compromised then you **must not** transition. [Revoke](#revoke-key) the old key and replace it with a new one immediately. **Do not** use a transition period.

### I have a new key. What Apache documents do I have to update?

There are several Apache documents you have to update when you have a new key. Follow these [instructions](https://infra.apache.org/openpgp.html#update).

### What RSA is

RSA is a well known public key cryptography algorithm which supports signing and encryption. See [further reading](#reading) for more details.

### How to find the length of a key

The easiest way to discover the length of a key with id `KEYID` is to use `gpg --list-keys KEYID`. This prints basic information about the key. The first line includes the size in the second column, just before the id.
For example:

```
$ gpg --list-keys B1313DE2
pub   1024D/B1313DE2 2003-01-15
uid                  Robert Burrell Donkin (CODE SIGNING KEY) <rdonkin@apache.org>
uid                  Robert Burrell Donkin <robertburrelldonkin@gmail.com>
uid                  Robert Burrell Donkin <robertburrelldonkin@blueyonder.co.uk>
sub   4096R/40A882CB 2009-06-18 [expires: 2010-06-18]

$ gpg --list-keys A6EE6908
pub   8192R/A6EE6908 2009-08-07
uid                  Robert Burrell Donkin (CODE SIGNING KEY) <rdonkin@apache.org>
sub   8192R/B800EFC1 2009-08-07
```

shows that key `B1313DE2` has length 1024 and `A6EE6908` length 8192.

## Key basics

To sign releases, you need to [generate](#generate) a new master key-pair for code signing. Follow these [instructions](https://infra.apache.org/openpgp.html#generate-key).

### The KEYS File

The KEYS file is a plain-text file containing the public key signatures of the release managers (and optionally other committers) for the project. A good example is the [Apache Ant KEYS file](https://downloads.apache.org/ant/KEYS).

It is traditional to include the following header to explain how to use the file. These commands generate a descriptive comment describing the key, followed by the key itself. Key handling software ignores the comments when importing a key file:

```
This file contains the PGP keys of various developers.
Users: pgp < KEYS
or
       gpg --import KEYS

Developers:
    pgp -kxa <your name> and append it to this file.
or
    (pgpk -ll <your name> && pgpk -xa <your name>) >> this file.
or
    (gpg --list-sigs <your name> && gpg --armor --export <your name>) >> this file.
```

Store the KEYS file with the release archives to which it applies at the top level of the ASF mirror area for the project. This makes it available for users to download, and for automatic archiving with its release. For example, the Ant KEYS file is in the directory `https://downloads.apache.org/ant`. The corresponding SVN area is at `https://dist.apache.org/repos/dist/release/ant`.

Since users may need the KEYS file to check signatures for archived releases, it is important to retain in the file all keys that have ever been used to sign releases. Add entries with eadch new key the project uses, but do not remove entries.

[Applied cryptography](#pke) is a subject that has considerable depth. Luckily, it's possible to get started signing releases without being an expert. Just remember that you will encounter some situations that require research and learning. We hope the
[FAQ](#faq) will be a reasonable first port of call.

You need an [application](#openpgp-applications) to manage keys and create signatures. We recommend [GNU Privacy Guard](http://www.gnupg.org/), and the Apache documentation generally assumes that's what
you're using. (We welcome contributions that document use of other tools.) Read the [Apache PGP user guide](https://infra.apache.org/openpgp.html#gnupg) and keep the [manual](https://www.gnupg.org/gph/en/manual.html) handy.

GnuPG can handle MD5 and SHA checksums as well as PGP signatures. It is your all-in-one cross-platform tool for release signing and verification.

**Note:** It can be hard for newbies to be confident that they have executed operations correctly. Consider doing some [practice](#safe-practice) before you try to sign an actual release.

### What is OpenPGP?

[OpenPGP](https://infra.apache.org/openpgp.html) is an [RFC](http://www.ietf.org/rfc/rfc2440.txt) describing a system for interoperable [public key cryptography](#pke). Various implementations exist. Apache recommends [GNU Privacy Guard](https://www.gnupg.org/) (GnuPG), an open-source, OpenPGP compatible implementation. It comes with [good documentation](https://www.gnupg.org/(en)/documentation/guides.html) that describes GnuPG and gives a good general introduction to public key cryptography.

### What is public key cryptography?

Public key cryptography is asymmetric. You use one key to encrypt a message which only the other key can decrypt. You can share the first key publicly without compromising the security of the second key. One key is therefore called the \_public key\_ and one the \_private key\_.

When you use public key cryptography, you can freely distribute the public key, but you must keep the private key secret. It is vital to [protect](#private-key-protection) private key files.. Private keys are typically stored in files protected by symmetric encryption. Choose a strong [passphrase](#passphrase) to protect the file.

### What is a detached signature?

You create a digital signature from an original document using a [private key](#pke). Possession of the corresponding public key allows verification that a given file is identical to the original document. An *attached signature* is attached to the document whereas a *detached signature* is contained in a separate file.

### What is ASCII armoring?

ASCII armoring is an encoding format that converts a binary file into a string of ASCII characters. This format is more human readable and more portable than other formats.

## How can I safely practice using OpenPGP?

To practice using OpenPGP, use separate environments. each with a different practice keyring.

For example, using [GNU Privacy Guard](http://www.gnupg.org):

* (First time only)Create a directory to contain the keyring
* Open the shell to be configured to use this keyring
* Change to the directory
* (First time only) `$ mkdir -m 700 .gnupg`
* Set up the environment: `export GNUPGHOME=.gnupg`

## What is a Web Of Trust?

It is difficult to personally verify the identity of all useful [public keys](#pke). However, having verified the identity of only a small number of public keys it is possible to deduce the identity of public keys trusted by the owners of these keys. This process can be repeated. This extended graph of trusted identities is termed a [>web of trust](http://en.wikipedia.org/wiki/Web_of_trust).

You can use webs of trust to solve the problem of verifying the identity of public keys.

**Note:** to take full advantage of a web of trust, it is important to actively build your personal web of trust into the major public webs of trust. Conferences are an ideal opportunity for exchanging key information, but you must come [prepared](#link-into-wot).

For more information read the [GNU Privacy Handbook](https://www.gnupg.org/(en)/documentation/guides.html).

### How do I link into a public web of trust?

You join a web of trust when an existing member of that web signs your public key to verify your identity. See [a short explanation](https://infra.apache.org/openpgp.html#wot).

### What is a key-signing party?

A key signing party is a meeting organised to allow the exchange of public keys to extend the [web of trust](#web-of-trust). See the [Keysigning Party HOWTO](https://www.cryptnet.net/fdp/crypto/keysigning_party/en/keysigning_party.html).

### How can I link my key into the Apache Web of Trust?

You can link into the Apache web of trust by meeting other Apache committers face-to-face and [exchanging public
keys](#link-into-wot):

* Apache committers organizes [key signing parties](#key-signing-party) at each [ApacheCon](https://www.apachecon.com).
* If you are not able to attend ApacheCon, or it will not happen for several months, consider organising a face-to-face meeting of [local committers](https://people.apache.org/map.html).

Subscribe to the `party` list and when you visit a new city, see if committers want to meet up.

### The difference between a public and a private key

A public key is for verifying signatures and encrypting messages; a private key is for generating signatures and decrypting messages. You can freely distribute public keys safely , but you must keep private keys [protected](#safe-and-secure). More details [here](#pke).

### How to protect your code signing private key

Anyone who possesses a copy of a [private key](#public-private) used to [sign](#sign-release) releases can create doctored releases with valid signatures. If this person intends harm then the consequences could be serious indeed. It is therefore very important to keep the private key secret.

* Only sign releases on a [secure machine](#secure-machine).
* Keep your [signing application](#openpgp-applications) fully patched.
* Keep the key file [safe and secret](#safe-and-secure).
* Choose a good [passphrase](#passphrase).

### How safe does the private key need to be?

It is vital that the private key is kept safe and secure. Though the file is encrypted using a [passphrase](#passphrase) , given enough time any determined cracker will be able to break that encryption. Basic precautions should include ensuring that only the user can read the directories.

However, for code signing keys we recommend taking additional measures. Reduce the window of vulnerability by using an
[isolated installation](#isolated-installation) or by storing the private key on removable media (which you should remove and store securely when not actually signing a release.).

### The meaning of 'isolated installation'

An isolated installation is inaccessible when you are not using it to sign releases. For example, create an installation on a separate hard disc or use a live CD.

### Recommended key length

The number of operations required to break a key by brute force increases with key size. However, the cost of using the key also rises. You must take into account the planned use of the key. You will use keys for code signing rarely and in situations where performance is not the main concern, so you can use long keys.

Over time, the cost of attacking a key of a given length by brute force falls as computing power increases. So a key whose length
seems adequate today may be seem too short in a few years time. This is a significant issue for long-lived keys such as those used to sign ASF releases, and another reason to use longer keys with releases.

Now that there is doubt about the medium term security of [SHA-1](#sha1), avoid the DSA keys and 1024 bit RSA keys which depend on this algorithm. We recommended that new keys be at least 4096 bit RSA (the longest widely supported key length).

## What is a Passphrase?

In cryptography *passphrase* is often used for what might be known as a password in other contexts. For example, an
[OpenPGP](#openpgp) private key is typically stored to disc in a file encrypted by a symmetric cypher keyed by a passphrase. This passphrase is one of the weakest elements in the system: should anyone else gain access to the file then a dictionary attack will be feasible on a weak passphrase. So choosing a strong passphrase is very important.

Passphrases, unlike passwords, are typically unlimited in length. We recommend using long passphrases. You can use sequences of (at least seven) unrelated words or more conventional mixtures of symbols and alphanumerics.

Even a good passphrase offers only limited protection. Given the encrypted file and enough time, a determined cracker will be able to
break any passphrase. A good passphrase will buy important time in the event of a compromise, but is no substitute for keeping the private key [safe and secure](#safe-and-secure) in the first place.

## Revocation Certificate basics

[OpenPGP](#openpgp) defines a special type of signed message called a **revocation certificate**. This message indicates that the signer believes that the key is no longer trustworthy. Typically, the revocation certificate will be signed by the key to be revoked (though the key may specify that other keys should be trusted for revocation). Use the type of revocation and the comment included to judge how much trust to place in a good signature by a revoked key.

You should generate a revocation certificate for each public key you use. Store the revocation certificates safely, securely and separately from their public keys.

Each revocation certificate has a type specifying a general (machine readable) reason for the revocation:

* No reason specified
* Key has been compromised
* Key is superseded
* Key is no longer used

Create certificates to cover the first two cases. Note that if a key is lost or can no longer be accessed (due to
media failure or some other reason), assume that the key has been potentially compromised. Print copies of the revocation certificates and store them safely to guard against media failure.

You can generate an [ASCII armored](#ascii) revocation certificate for key `bob` and save it to `revoke.asc` using [GNU Privacy Guard](https://www.gnupg.org):

```
$ gpg --output revoke.asc --armor --gen-revoke bob
```

[Securely store](#revocation-certificate-storage) the certificate.

If you are preparing a revocation certificate for future use, you should test it before storing it. See [safe practice.](#safe-practice)

### Revoking a key

To revoke a key with a [revocation certificate](#revocation-cert) using [GNU Privacy Guard](https://www.gnupg.org), import the certificate:

```
$ gpg --import revoke.asc
gpg: key 4A03679A: "Some User<someuser@example.org>" revocation
certificate imported
gpg: Total number processed: 1
gpg:    new key revocations: 1
```

### Where to store revocation certificates

Store each revocation certificate securely and separately from the key it revokes. Burning the certificate onto a CDROM or printing it out as a hard copy are good solutions.

### Distributing a revocation certificate

If a key has been compromised, distribute its [revocation certificate](#revocation-cert) to those using the key. This process is a mirror of the process by which you distributred the original key.

* Inform the Apache infrastructure team by a post containing the revocation certificate.
* Update the KEYS files containing the original key with the revocation certificate.
* Upload the revocation certificate to the major keyserver networks.
* Post an announcement to the appropriate lists with the revocation certificate attached.

### The difference between deleting and revoking a key

When you *delete* a key from a keyring, it is simply removed. You can add it again later.

When you *revoke* a key, it is marked in the key ring. Whenever a message signed by this key is verified in the future, the user will get a warning that the key has been revoked.

For example, when you verify a revoked key, [GNU Privacy Guard](https://www.gnupg.org) issues the following comment:

```
$ gpg --verify message.asc.message
gpg: Signature made Sat Apr  8 09:28:31 2006 BST using DSA key ID 4A03679A
gpg: Good signature from "Some User <someuser@example.org>"
gpg: checking the trustdb
gpg: checking at depth 0 signed=0 ot(-/q/n/m/f/u)=0/0/0/0/0/1
gpg: WARNING: This key has been revoked by its owner!
gpg:          This could mean that the signature is forgery.
gpg: reason for revocation: Key has been compromised
gpg: revocation comment:
gpg: WARNING: This key is not certified with a trusted signature!
gpg:          There is no indication that the signature belongs to the
owner.
Primary key fingerprint: 82D1 169B E6F1 9D14 DA76  A5DD 968E 66E4 4A03 679A
```

## FAQs from those downloading releases

### What does verifying a signature mean?

You can use [public key cryptography](#pke) to test whether a particular file is identical in content to an original by verifying a [signature](#detach-sig). The signature file is a [digest](#message-digest) of the original file signed by a private key which attests to the digest's authenticity.

For example, when using [GNU Privacy Guard](https://www.gnupg.org/) you verify the signature `foo-1.0.tar.gz.asc` for release `foo-1.0.tar.gz` using the following command:

```
$ gpg --verify foo-1.0.tar.gz.asc foo-1.0.tar.gz
```

A signature is valid, if `gpg` verifies the `.asc` as a *good signature*, and doesn't complain about expired
or revoked keys. Technically :

```
$ gpg --verify --status-fd 1 foo-1.0.tar.gz.asc foo-1.0.tar.gz
```

should classify the `.asc` as a `GOODSIG`.

Trust is required in the identity of the public key that made the signature and that the signature is for the original file and not some other file. When verifying a release from an untrusted source (for example, over P2P file sharing or from a mirror) it is important to download the signature from a trusted source. Signatures for all Apache releases are available directly for download from `www.apache.org`.

### How can I check the integrity of a release?

[MD5](#md5) and [SHA](#sha-checksum) checksums provide a simple way to verify the integrity of a download. You can simply create a checksum (in the same way as the release manager) after download, and compare the result to the checksum downloaded from the main Apache site. However, this process does not provide for authentication and non-repudiation as anybody can create the same checksum.

You can also check the integrity of a release by [verifying the signature](#verifying-signature). You need more knowledge to correctly interpret the result, but it does provide authentication and non-repudiation. If you are connected to the Apache [web of trust](#web-of-trust), this also offers superior security.

### What does 'Public key not found' mean when I try to verify a signature?

To verify a signature, you need the release's public key. For example, when using [GNU Privacy Guard](https://www.gnupg.org/), if you have never imported the appropriate public key, you will see a message like this:

```
$ gpg --verify foo-1.0.tar.gz.asc foo-1.0.tar.gz
gpg: Signature made Mon Sep 26 22:26:18 2005 BST using RSA key ID 00000000
gpg: Can't check signature: public key not found
```

You can often download unknown keys from a [public key servers](#keyserver). However, only rely on these if you can confirm them through your [web of trust](#web-of-trust).

Apache projects normally keep the developers' public keys in a file called `KEYS`. You may be able to find that file on the project's website, or in their code repository. Use

```
  $ gpg --import KEYS
```

to import the public keys.

### What is the difference between secure hardware and trusted hardware?

**Secure hardware**: your personal laptop would quality as "secure" provided that only you have root/admin access to it, so only you can access private keys stored on it.

**Trusted hardware** is secure hardware under the direct control of the release manager, with limited release permissions, and protected by a passphrase and possibly other security measures.

### What is a trusted key?

[OpenPGP](#openpgp) uses a [web of trust](#web-of-trust). The owner of a public key who trusts the identity of a second key may mark this key as trusted by signing it. This has several major effects:

* In future, no [untrusted key warning](#valid-untrusted-vs-invalid-trusted) appears when a valid signature for
  this key is verified.
* Keys the owner of the key trusts may also become trusted. In other words, if the owner of a key whose identity you trust confirms the identity of a key, that key may be automatically trusted. This behavior is typically configurable.
* The next time you export your key, those who trust your key may start to trust the identity of the trusted key.

The transitive nature of the web of trust places a responsibility on the owner to verify the identity of the owner of those keys marked as trusted.

For more information read the [GNU Privacy Guard User
Guide](https://www.gnupg.org/(en)/documentation/guides.html).

### What is the difference between a valid signature from an untrusted key an invalid signature from a trusted key?

Trustfulness and validity are different concepts. You may elect to trust the identity of a key to various degrees (or not at all). For a particular key, a particular signature for a particular file may be valid (created by the private key from an identical file) or invalid
(either corrupt or created from a different file).

Do not trust a file with an invalid signature. You can trust a file with a valid signature as much as you trust the identity of the key that was used to verify the signature.

For example, when you use [GNU Privacy Guard](https://www.gnupg.org/), a message similar to the following indicates that the signature is invalid:

```
$ gpg --verify foo-1.0.tar.gz.asc foo-1.0.tar.gz
gpg: Signature made Mon Sep 26 22:26:18 2005 BST using RSA key ID 00000000
gpg: BAD signature from "someone@example.org"
```

A message similar to the following indicates that the signature is valid but for an untrusted key:

```
$ gpg --verify foo-1.0.tar.gz.asc foo-1.0.tar.gz
gpg: Signature made Mon Sep 26 22:05:28 2005 BST using RSA key ID 00000000
gpg: Good signature from "someone@example.org"
gpg:                 aka "someone@anotherdomain.org"
gpg: checking the trustdb
gpg: checking at depth 0 signed=1 ot(-/q/n/m/f/u)=0/0/0/0/0/1
gpg: checking at depth 1 signed=0 ot(-/q/n/m/f/u)=1/0/0/0/0/0
gpg: WARNING: This key is not certified with a trusted signature!
gpg:          There is no indication that the signature belongs to the
owner.
Primary key fingerprint: 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00
```

You can use the [fingerprint](#fingerprint) to decide how much trust to assign to the key.

### What is a public key fingerprint?

Public keys are long and even when [ASCII armored](#ascii) are not very easy for humans to understand or compare. A fingerprint is a short [digest](#message-digest) of the key formatted in a way that makes it easier for humans to read and compare.

### Can I mark a key as locally trusted?

On occasion, the user (who understands the risks) may trust a key but not consider it trustworthy enough to exported to the [web of trust](#web-of-trust). [OpenPGP](#openpgp) lets you sign keys as local only. These trust relationships will not be exported to the public web of trust but are treated as trusted when you use the key ring locally.

For example, with [GNU Privacy Guard](https://www.gnupg.org) use:

```
$ gpg --lsign-key someuser
```

### Automated Release Signing

Projects may make use of automated signing for artifacts built by a CI system such as GitHub Actions, provided that:

* All artifacts being signed can be built [reproducibly](https://reproducible-builds.org)
* CI deploys the artifacts to a staging environment
* The release process contains a validation step where all artifacts are reproduced and validated on [trusted hardware](https://www.apache.org/legal/release-policy.html#owned-controlled-hardware) (i.e. not GitHub Actions) before publication to pages intended for end users. This means rebuilding the artifacts from source and validating the resulting artifacts are bit-by-bit identical to those staged for release.

The Apache Security Team should be notified of any pending requests for CI signing keys, and should approve the workflow before it is being put into use. In this request, please highlight the intended change to your release process where you make sure artifacts are validated on trusted hardware before release.
See [INFRA-23996](https://issues.apache.org/jira/browse/INFRA-23996) for background on this.

The project must request a signing key through an Infra Jira ticket, and Infra will provide a signing key for the project:

* The key will be 4096 bit RSA
* It will be a signing-only key
* Infra will put a PGP-encrypted revocation key in the project's private svn/git dir
* The private key will never be shared with the project or anyone outside of the infra-root team, but will be available to the chosen CI system
* The public key will be sent to the project or added to their KEYS file

## Further reading

There are many other excellent resources on signing releases, but these make a good start:

* The [Guide to using GnuPG](https://infra.apache.org/openpgp.html#gnupg) at Apache
* The [Apache Key Transition Guide](https://infra.apache.org/key-transition.html)
* RFC [1321](http://www.ietf.org/rfc/rfc1321.txt) MD5 message-digest algorithm
* RFC [2440](http://www.ietf.org/rfc/rfc2440.txt) OpenPGP message format
* The GNU Privacy Guard project [documentation](https://www.gnupg.org/documentation/)
* An introduction to [PGP public key cryptography](https://www.pgpi.org/doc/pgpintro/)
* [Applied Cryptography](https://www.schneier.com/book-applied.html) by Bruce Schneier
* Windows-centric [PGP FAQ](http://www.mccune.cc/PGPpage2.htm) by Tom McCune
