---
abstract: |
    [Scrit](https://scrit.cash) (secure, confidential, reliable, instant
    transactions) is a federated Chaumian e-cash [see @Chaum1990]. Coins in
    Scrit are so-called *digital bearer certificates* (DBCs) issued by
    mints. Scrit mitigates the issuer risk common in other DBC systems by
    employing $n$ mints in parallel. It has the maximally achievable
    transaction anonymity (the anonymity set of a DBC equals or is bigger
    than all DBCs ever issued in that denomination during the defined epoch)
    and transactions are extremly cheap and fast (settlement is network
    latency bound leadings to sub-second confirmation times).
author: Jonathan Logan and Frank Braun
date: '2019-10-26'
title: 'Scrit: A distributed untraceable electronic cash system'
---

Introduction
============

The problem of previous Chaumiam e-cash systems has been their
centralization in both a technical and a governance sense, caused by
employing a single mint. This has exposed these systems to technical and
legal risks and presented a single point of failure.

Furthermore, Chaumian e-cash systems focus on the model of withdrawing
e-cash from *accounts* and depositing it into other accounts. This
requires an unnecessary setup phase for users.

Scrit removes the notion of accounts, it only has direct DBC-to-DBC
transactions. Users do not have any standing relationship with the
operators nor do they possess any identifying authentication
credentials. This both simplifies the system and remove a potential
level for censorship.

A classical Chaumian e-cash system encodes the attributes of a DBC (for
example, amount, denomination, and expiry) in the signed message of the
DBCs. Since the client controls the message, this poses a fraud risk
that requires complex mitigation, which usually involved using either
the user's identity or the user's holdings in his account as a
collateral. In Scrit this fraud risk is removed by using the mint
signing key as the signifier of certificate attributes. That is, each
DBC signing key (from the mint) is associated to a unique tuple
comprised of amount, denomination, and expiry. A successful verfication
of a signature yields this tuple, the message contents are not
authoratitive concerning the value of a DBC. Since this removes the
fraud risk in Scrit, no identification or account is necessary.

Scrit enables technical and legal distribution of DBC operations by
parallel execution of transactions distributed over many separate mints.
To accomplish this, we modify the classical construction of a DBC which
consists of message and signature and replace it with the definition of
a DBC as consisting of a *unique* message and a *set* of signatures.
Instead of relying on a unique value certified by a single mint, Scrit
defines certification a as consensus between mints expressed by
independent mint signatures. The consensus is reached, if a DBC carries
enough signatures by different mints to reach a predefined *quorum*.
That is, a DBC is valid, if it has at least $m$-of-$n$ signatures, where
$m$ is the quorum and $n$ is the number of mints (as described in detail
further below).

Since Scrit operations are distributed over a set of mints, the question
of governance arises. Technically, the solution of the governance
question is outside the scope of the payment system Scrit itself, but we
propose a simple governance solution based on Codechain, a system for
secure multiparty code reviews, which is described in detail in the
section on [Governance](#governance).

Transactions in Scrit are extremly cheap and fast, especially compared
to blockchain based systems. Mints do not have to synchronize at all to
process transactions, which means the communication to all mints can be
performed in parallel. This leads to network latency bound settlement
times with sub-second confirmations. See the section on
[Performance](#performance) for details.

DBCs
====

DBCs are single-use digital coins in predifined denominations. The
denomination, expiry, and currency of these coins are encoded by public
signing keys employed by *mints* (the issuers of DBCs in Scrit). A
signature done by a mint guarantuees the authenticity of a DBC. The
*spendbook* of a mint guarantees uniqueness (and thereby prevents double
spends).

DBCs consist of a message and a list of signatures. The message contains
information for looking up signature public keys as well as information
to enforce ownership and uniqueness. Values for key lookup are amount,
currency, and expiry, as well as signature algorithm. They refer to an
entry in the *key list* (see [Key list](#key-list) below). Furthermore,
the ownership is encoded by a hash of an *access control script* (ACS)
with which the mint verifies the user's authority to execute a
transaction. The message also contains a random value for uniqueness.
The list of signatures consists of at most one signature per mint in the
network. Signatures contain the mint ID in addition to the cryptographic
values of the signature itself.

Given the fields contained in the DBC (amount, currency, expiry,
signature algorithm, and mint ID) the signing public key can be looked
up from the system-wide published key list. Given the retrieved public
key, the signature can be verified. This ensures that the values set in
the message of the DBC match the signing key of the mint (otherwise the
signature would be invalid).

Key list
--------

Each mint publishes a list of its DBC signing keys. Per signing key the
list contains the following information: amount, currency, signature
algorithm, beginning and end of the signing epoch, the end of the
validation epoch, and the corresponding unique public key. All entries
are together signed by both the long-term identity signature key and
each unique DBC signing key contained in the list. This ensures that the
private key corresponding to each public key contained in the list is
actually controlled by the mint identified by the long-term identity
signature key, which prevents the creation of forged DBCs. The
association between certification values and the DBC signing key must be
globally unique (which has to be verified by all clients and mints in
the system).

Transactions
============

Scrit mints offer only two APIs to the Scrit clients: Perform a
*transaction* (also called a *reissue*) and a lookup in the spendbook
(which records all spent DBCs).

The spendbook writes entries in the order given below and breaks on
failure. All writes are successful if the value was not contained in the
spendbook before and fail if the value is already known. A transactions
works as follows:

1.  Verify transaction: Verify ACS, verify mint signatures on input
    DBCs.
2.  Write transaction hash to spendbook. If transaction hash was known
    return success and sign output DBCs.
3.  Write server parameters to spendbook in the order contained in the
    transaction (if required for signature algorithm). If any parameter
    is known return failure and abort transaction (on first known
    parameter).
4.  Write input DBCs to spendbook in the order contained in the
    transaction. If any input DBC is known return failure and abort
    transaction (on first known input DBC).
5.  Signing output DBCs and return signature.

If a transaction contains any spent input DBCs after unspent input DBCs,
the unspent DBCs will be recorded as spent and the transaction will
abort without returning DBC signatures. This can only happen, if the
client attempts to defraud the mint (or the implementer screwed up).

Transaction format
------------------

All transactions in Scrit are *reissue*-transactions. They take input
DBCs and output DBC templates as well as parameters as input, and return
output DBC signatures. Furthermore, transactions must fulfill conditions
defined in the ACS referenced by the input DBCs.

Transactions consist of two blocks: A global set of input parameters and
a mint local set of input parameters.

The global set of input parameters is sent to all mints and contains the
following:

-   Start of the signing epoch, which refers to start of the key
    rotation epoch and must be globally coordinated between mints.
-   Input DBCs: List of unblinded DBC messages, not including mint
    signatures.
-   Root of parameter tree (see [Parameter tree](#parameter-tree)
    below).
-   List of signatures to fulfill ACS that sign all of the above fields.
-   List of access control scripts in the order of input DBCs.

The mint local set of input parameters that is sent to a single mint
contains only a list of lists of mint signatures and the corresponding
path of the parameter tree (including the leaf). The list of lists has
the same order as the input DBCs and contains the lists of the input DBC
mint signatures. Usually such a list contains only the mint's own
signature. Except in cases of mint recovery, see the section on
[Distribution](#distribution) below.

This transaction format limits the amount of signatures a client has to
make, so that it does not depend on the number $n$ of mints in the
system. Furthermore, it simplifies the implementation of verification
functions, because it only requires the parallel verification of list
elements while limiting the impact of $n$ on the required memory.

![Transaction format (global set).](image/transaction-format.pdf)

Parameter tree
--------------

The parameter tree contains per mint specific definitions of output.
Each leaf is assigned to one mint and contains the mint ID and a list of
tuples. A tuple contains a potentially blinded output DBC message,
encrypted server blinding parameters (see section on
[Signatures](#signatures) below), and the signing algorithm to use.
Furthermore, it contains values required for DBC signing key lookup
(amount and denomination).

For unblind signing algorithms the server blinding parameters are empty.
If only unblind signing algorithms are used in the outputs, the same
leaf is revealed to all mints and the mint ID is set to a global
constant referring to all mints.

The tree is encoded as a Merkle tree. During transactions leaf and path
are revealed to the corresponding mint and are verified by it.

Spendbook entries
-----------------

To enforce the uniqueness of DBCs (preventing double spend) each mint
records the message of every spent DBC within one key verification epoch
(that is, signing plus validation epoch). Furthermore, server blinding
parameters have to be unique as well, which requires them to be recorded
in the spendbook. In addition, recording the transaction itself allows
idempotent operations.

For the spendbook Scrit uses a key-value store in which the following is
recorded:

-   Transaction: $T||\mbox{Hash(Tx)} \rightarrow \mbox{Tx}$
-   Parameters: $P||\mbox{Hash(Param)}\rightarrow \mbox{Hash(Tx)}$
-   DBC: $D||\mbox{Hash(DBC message)} \rightarrow \mbox{Hash(Tx)}$
-   OOB: $O||\mbox{Hash(DBC message)} \rightarrow \mbox{OOB}$

OOB refers to *out-of-band* data that can be generated by an [Access
Control Script (ACS)](#access-control-script-acs).

The spendbook also records transactions in a hash chain for
cryptographically secure ordering. The hash chain consists of:

$$CE_{n+1} = \mbox{Counter}||\mbox{Date}||Hash(CE_n)||\mbox{Hash(Tx)}$$

Clients can access all of these records through an open API.

Access Control Script (ACS)
---------------------------

Scrit mints enforce access control for DBCs through a paramter encoded
in the DBCs which is called the *access control script* (ACS). Such an
ACS can enforce that transactions using a certain DBC have to be signed
by a user-controlled key. We define multiple access control languages
which can be extended in the future to incorporate additional features.

Herein we define just two access control functions:

-   $0x00$: No access control.
-   $0x01||\mbox{Date}||\mbox{PubKey}_a||\mbox{PubKey}_b$: This ACS
    enforces that **before** $\mbox{Date}$ the transaction must be
    signed by $\mbox{PubKey}_a$ and **after and including**
    $\mbox{Date}$ the transaction must be signed by $\mbox{PubKey}_b$.
    The special value $0$ for $\mbox{Date}$ enforces that
    $\mbox{PubKey}_a$ must always sign the transaction.
-   $0x02$--$0x\mbox{ff}$: Reserved for future use.

The standard transaction from recipient to sender constructs the ACS as
follows:

1.  Given: Elliptic curve, generator $G$.
2.  Sender knows from recipient: $$\mbox{PubKey}_r: aG$$
3.  Recipient knows corresponding: $$\mbox{PrivKey}_r: a$$
4.  Sender generates temporary key pair:
    $$b=\mbox{random}, \mbox{PubKey}_b=bG$$
5.  Sender calculates shared secret: $$s=\mbox{Hash(scalarMult(b,aG))}$$
6.  Sender calculates transaction signing key:
    $$\mbox{PubKey}_a=\mbox{scalarMult(s,aG)}$$
7.  Sender constructs ACS as:
    $$0x01||\mbox{Date}||\mbox{PubKey}_a||\mbox{PubKey}_b$$
8.  Recipient calculates shared secred:
    $$s=\mbox{Hash(scalarMult(a,bG))}$$
9.  Recipient calculates signing key: $$\mbox{PrivKey}_a=as$$
10. Recipient signs transaction.

If the recipient doesn't sign a valid transaction before $\mbox{Date}$
expires, the sender can recover the DBC by signing a transaction with
$b$ (which he has to record).

The above construction prevents the mints from recognizing the recipient
over multiple transactions and thus preserves the anonymity of both
sender and recipient. That is, the recipient $\mbox{PubKey}_r$ can be a
published constant without sacrificing anonymity.

Referenced state in an ACS refers to the mint's local state. In the case
of $\mbox{Date}$ this is the system time of the mint in UTC.

Evidence of payment
-------------------

The combination of a publicly accessible spendbook that contains the
transactions and the access control script allows for a sender to
publicly demonstrate that he made a payment that was accepted by the
recipient. The transaction bears the signatures of the recipient as
defined by the ACS. Neither the sender nor the mint are able to forge
this signature. This also allows the owner of a DBC to demonstrate if a
mint has falsely claimed a DBC to be spent.

Protocol flow
-------------

Let's assume the sender has a DBC A for a given recipient constructed
according to an ACS $0x01$ as described above.

In order to perform a payment the protocol flow is as follows. The
sender gives the DBC A to the recipient. The recipient *reissues* the
DBC A to a DBC B, either immediately or before the ACS $\mbox{Date}$
expires:

1.  The recipient constructs a *transaction* with DBC A as input DBC,
    DBC B as output DBC, and signs it with the derived
    $\mbox{PrivKey}_a$.
2.  The recipient talks to all $n$ mints **in parallel**, sending
    **each** mint the same global set of input parameters of the
    constructed transaction, but sending each mint a **different** mint
    local set of input parameters (as described in the \[Transaction\]
    section above).
3.  Each mint verifies the transaction independently of all other mints,
    signs the output DBC, and returns its signature.
4.  The recipient collects all the mint's signatures over the output DBC
    B, combines them into a validly signed DBC B (given he received at
    least $m$ valid signatures), and saves it in his wallet.

Before starting the transaction the sender might have to reissue a DBC
to create a suitable DBC A intended for the recipient. This is achieved
with an analog flow.

The protocol protocol flow for an ACS $0x00$ is similar, but simpler, as
shown in Figure 2.

![Protocol flow of a Scrit transaction. Scrit clients talk to all mints
in parallel (see [Distribution](#distribution)
section).](image/transaction.pdf)

Signatures
==========

Scrit employs both blind and unlinkable as well as non-blind signature
schemes.

The non-blind signature schemes are used for user signatures to fullfil
access control scripts as well as for DBC signatures in scenarios where
unlinkability of transactions is not a requirement.

-   explain the anonymity claims from the abstract
-   Scrit uses a ECC based blind signature scheme published by
    1.  

-   Server blinding parameter scheme.

Key rotation
============

To be able to prune the spendbook and not having to keep signing keys
secret forever, Scrit employs *key rotation* with disjunct signing
epochs. The signing epochs determines which signing key is used at a
certain point in time. After the end of a signing epoch follows a
validation epoch in which DBCs can still be spend. The signing and
validation epoch together comprise the verification epoch. Figure 3.
visualizes the key rotation process.

All mints have their own singing keys, but the epochs are the same for
all of them and have to be synchronized (see section on
[Governance](#governance)).

Employing key rotation has two important implication:

1.  Clients must go online before the verification epoch of the DBCs
    they hold ends and reissue them. Otherwise they will loose these
    DBCs.
2.  After a validation epoch ended the total number of DBCs in
    circulation can be calculated with a spendbook audit.

![Key rotation with disjunct signing epochs.](image/key-rotation.pdf)

**TODO**

Distribution
============

Signing rules:

-   AC script verify.
-   Transaction is known or all elements are unique.
-   Signed by self or signed by quorum.

Quorum must be $>51\%$, should be $>75\%$. Quorum for signing can be
smaller than quorum for membership.

-   rules (single mint, recovery)
-   epoch synchronization
-   mint recovery
-   changes of $m$ and $n$ must happen at signing epoch borders. That
    is, changes to $m$ and $n$ only activate at the *next* signing
    epoch.
-   signing epoch lengths can be change, but must stay disjunct

Quorum
------

**TODO**

-   rules for quorum

Governance
==========

(**TODO**: make sure this section describes the global coordination of
key lists (also see [Key list](#key-list), including epoch
synchronization.)

As mentioned before, the mints do not have to talk to each other to
perform normal transactions (which are *reissue* = *spend* + *issue*
operations). Either an unspent in DBC is presented to them with their
**own** signature or an in DBC with enough signatures of **other**
mints, such that the signatures reach quorum. The former is the normal
case. The latter can happen when a mint wasn't reachable during an
earlier reissue operation or simply didn't exist yet.

However, this still leaves a few questions open: How is new money
introduced into the system and the (optional) backing (a pure *issue*
operation of new DBCs)? How is money removed from the system and the
(optional) backing a (pure *spend* operation of DBCs)? How are new mints
introduced into the system or existing ones removed from it? Under what
rules do the mints operate? How does a client get to know which mints
belong to the system and which changes are made, ideally in an automatic
and cryptographically secure fashion? In short: How do we solve the
problem of *governance*?

Scrit uses [Codechain](https://github.com/frankbraun/codechain) as its
governance layer. Codechain is a system for secure multiparty code
reviews which establishes code trust via multi-party reviews recorded
unmodifiable hash chains. This makes it impossible for a single
developer to add changes to the Scrit code base. It should be obvious
why using Codechain is a good idea for sensitive code like the Scrit
client or the Scrit mint, but it is probably less obvious how it could
solve the governance problem. For the client and the mint the signers of
the Scrit Codechain are the trusted Scrit developers.

To understand how Codechain can solve the governance problem three
points are important:

1.  A Codechain "repository" doesn't have to contain source code,
    although that is the most common use case. It could also just
    contain configuration data and text files.

2.  The set of signers of a Codechain doesn't have to be the group of
    developers. It could also be another group, like all the mints.

3.  Codechain contains a mechanism called *secure dependencies* (see the
    [specification](https://godoc.org/github.com/frankbraun/codechain/secpkg)
    of *secure packages* for details) that allows to embed one Codechain
    into another, with potentially different sets of signers.

We can combine these three points into a governance solution for
Codechain:

-   We have a "normal" Codechain for the Scrit client and mint, signed
    by multiple Scrit developers.
-   We have a "governance" Codechain which contains configuration files
    and text files, comprising the governance layer of Codechain. The
    set of signers are all the mints (the number *n* of signers in
    Codechain) in the system and they "vote" on changes in the
    governance layer by signing changes to the "governance" Codechain.
    The necessary quorum (the minimum number of signatures *m* in
    Codechain) can be the same as the quorum for transactions or higher.
    Of course, the transcation quorum is also set in the governance
    Codechain. The configuration files contains all the mints which
    comprise the system, how they can be reached, what their signature
    keys are, and what the monetary supply is. Decisions to add miners,
    remove them, or change the monetary supply are recorded in the
    governance Codechain and are voted on by mints signing. The entire
    process is described in a "constitution" text file which is also
    part of the governance Codechain and is changed by the same
    mechanism.
-   The "normal" Codechain for the Scrit client and the mint contains
    the "governance" Codechain as a secure dependency. That way the
    client and the mint can automatically and securely update the mint
    configuration, allowing to transparently add and remove mints from
    the system.
-   Since Scrit is not only multi currency capable (multiple currencies
    in potentially different denominations issued by one set of mints),
    but also capable of dealing with **different** sets of mints, all
    these governance problems could easily be solved by each set of
    mints having their **own** governance Codechain (with their own
    rules etc.), and **all** governance Codechains added as secure
    dependencies to the Scrit client.

The whole design gives us a simple solution to the governance problem in
Scrit:

-   For normal operations (that is, transactions) the mints do not have
    to talk to each other at all, everything is done **automatically**
    by the clients talking to all mints separately (but in parallel).
-   Governance change are decided on **manually** by the mint operatore
    via signing changes to their governance Codechain, but are then
    **automatically** distributed to the corresponding Scrit clients and
    mints via secure dependency updates, as they are happening during
    regular secure package updates of the client or mint code.

Wallets
=======

Scrit wallets work differently than other cryptocurrency wallets,
because they mostly revolve around transfer and reissuing of DBCs, and
they don't necessarily have to sign anything. In the following we give
some details on how mobile and hardware wallets for Scrit could work.

There are four connectivity scenarios to consider:

1.  Sender and recipient are both online.
2.  Sender is online and recipient is offline.
3.  Sender is offline and recipient is online.
4.  Sender and recipient are both offline.

Mobile wallets
--------------

We consider having a mobile wallet as a sender and a mobile wallet or
POS terminal as recipient.

In scenario 1. (both online) the sender scans a QR code from the
recipient containing the payment sum, the DBC public key of the
recipient, and a URL where to upload the payment DBCs. The sender
reissues the necessary DBC to reach the payment sum for the recipient's
public key, creating assigned DBCs. He then posts it to the URL. The
recipient checks locally that he hasn't seen these DBCs before (to
prevent double spends) and reissues them again (possibly later). This
gives the sender [Evidence of payment](#evidence-of-payment), as
described above.

In scenario 2. (only sender online) the sender scans a QR code from the
recipient containing the payment sum, the DBC public key of the
recipient, and configuration data for a local Bluetooth or WiFi
connection to the recipient. The sender reissues the necessary DBC to
reach the payment sum for the recipient's public key, creating assigned
DBCs. He then opens up a local Bluetooth or WiFi connection to transfer
them to the recipient. The recipient checks locally that he hasn't seen
these DBCs before (to prevent double spends) and later reissues them.
This gives the sender [Evidence of payment](#evidence-of-payment), as
described above.

In scenario 3. (only recipient online) the sender scans a QR code from
the recipient containing the payment sum, the DBC public key of the
recipient, and configuration data for a local Bluetooth or WiFi
connection to the recipient. The sender opens up a local Bluetooth or
WiFi connection to transfer unassigned DBCs to the recipient. The
recipient immediately reissues them to prevent double spends. The
recipient confirms the payment, however this does **not** give the
sender [Evidence of payment](#evidence-of-payment).

In scenario 4. (both offline) the sender scans a QR code from the
recipient containing the payment sum, the DBC public key of the
recipient, and configuration data for a local Bluetooth or WiFi
connection to the recipient. The sender opens up a local Bluetooh or
WiFi connection to transfer **previously assigned** DBCs to the
recipient. The recipient checks locally that he hasn't seen these DBCs
before (to prevent a double spends) and confirms the payments. This
gives the sender evidence of payment, as described above, but only
**after** the recipient reissued the DBC at a later stage.

In theory the transfer from the sender to the recipient could also be
done via QR codes. But with a larger number of DBCs and/or mints this
quickly reaches the size limitations of QR codes and is therefore not
realistic in practice.

However, QR codes might be a good way to transfer a bunch of assigned
DBCs to a recipient on paper, with the recipient scanning one DBC QR
code after another. This gives us offline anonymous untraceable digital
cash in paper form (assigned to a single recipient).

Hardware wallets
----------------

A simple hardware wallet would consist of a mass storage device, a
display, and a single button. It basically handles scenario 3. (only
recipient online) or 4. above (both offline) above. The mass storage
device contains DBCs in different denominations. When connecting the
hardware wallet to the POS terminal (via USB, NFC, or other means) the
POS terminal requests a certain sum. The hardware wallet shows the
requested sum on the display and waits for confirmation via a button
press. Upon confirmation the hardware wallet would select the
corresponding DBCs, transfer them to the recipient, and delete them.
Depending on the scenario, the recipient would either reissue
immediately (for unassigned DBCs) or later (for assigned ones).

Since a very simple hardware wallet cannot check the validity of DBCs we
do not deal with change. When loading up hardware wallets the
denominations are selected in a way to err on the side of smaller
denominations and we can live with small overpayments in almost all real
world payment situations (consider it a tip).

Such simple hardware wallets would be loaded with a trusted device. For
example, an ATM that we trust (just as we trust cash ATMs) or with a
desktop client running on a trusted computer.

Communication
=============

**TODO**

Performance
===========

**TODO**

That total size of a DBC in the current implementation is $63 + n * 66$
byte (or more for different signature algorithms).

Backing
=======

**TODO**

While Scrit does not define a backing layer, one potential is a backing
of mint payment infrastructure by Bitcoin as soon as efficient multi
signature algorithms (for example, Schnorr signatures) are implemented.
This would allow to extend the control quorum from Scrit mints to their
backing.

References
==========
