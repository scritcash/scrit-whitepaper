---
abstract: |
    [Scrit](https://scrit.cash) (secure, confidential, reliable, instant
    transactions) is a federated Chaumian e-cash [see @Chaum1990]. Coins in
    Scrit are so-called *digital bearer certificates* (DBCs) issued by
    mints. Scrit mitigates the issuer risk common in other DBC systems by
    employing $n$ mints in parallel. It has the maximally achievable
    transaction anonymity (the anonymity set of a DBCs equals all DBCs ever
    issued in that denomination) and transactions are extremly cheap and
    fast (settlement is network latency bound leadings to sub-second
    confirmation times).
author: Jonathan Logan and Frank Braun
date: '2019-10-14'
title: 'Scrit: A distributed untraceable electronic cash system'
---

DBCs
====

DBCs are single-use digital coins in predifined denominations. The
denomination, expiry, and currency of these coins are encoded by public
signing keys employed by *mints* (the issuers of DBCs in Scrit). A
signature done by a mint guarantuees the authenticity of DBCs. The
*spendbook* of mint guarantees uniqueness (and thereby prevents double
spends).

DBCs have the following format:

-   L-Value:
    -   Amount (4 byte)
    -   Currency (2 byte)
    -   Expiry (8 byte)
    -   Hash(ACS) (32 byte)
    -   Randome bytes (16 byte)
    -   Signature algorithm (1 byte)
-   Signatures:
    -   Mint ID $1$ (4 byte)
    -   Signature $1$ (at least 32 byte)
    -   ...
    -   Mint ID $n$
    -   Signature $n$ (at least 32 byte)

That total size of a DBC is $65 + n * 36$ byte (or more for different
signature algorithms).

To search for public keys the *key list* of a mint ID (which is given in
the signature) is searched for the currency, expiry, and amount
combination given in the DBC.

A key list contains the following data:

-   Signature keys:
    -   Amount, currency, expiry
    -   Public key
-   Signatures:
    -   Mint (**TODO**: sig of identity key of mint?)
    -   Signature keys

Transactions
============

Scrit mints offer only two APIs to the Scrit clients: Perform a
*transaction* (also called a *reissue*) and a lookup in the spendbook
(which records all spent DBCs).

The spendbook writes entries in the order given below and breaks on
failure. A transactions works as follows:

1.  Verify transaction.
2.  Write transaction hash, if know return success.
3.  Write server parameters, if any is known return failing parameters.
4.  Write DBCs, if any is known return failing DBCs.
5.  On success proceed with signing.

A double spend can lead to loss of coins (**TODO**: explain in more
detail and maybe move somewhere else).

Transaction format
------------------

-   In DBCs
-   Out DBCs: $\mbox{Type(sig)} || \mbox{L-Value (possibly blind)}$
-   Root of parameter tree (optional, depends on signature algorithm)
-   List of AC scripts in order of In DBCs
    ($\mbox{length(In DBCs)} == \mbox{length(AC scripts)}$)
-   Signatures list (signing the above):
    -   Type
    -   Public key
    -   Signature
-   Parameters (verify against parameter tree)
-   Mint signatures (in order of In DBCs)

Scrit uses a ECC based blind signature scheme published by
@SinghDas2014.

Parameter tree
--------------

-   Merkle tree of parameters.
-   One leaf per mint, leaf is list of parameters in order of out DBCs.
-   Path included when revealed to mint.
-   Transaction contains signed root.
-   Minimizes signatures in transaction creation.

Spendbook entries
-----------------

-   Transaction: $T||\mbox{Hash(Tx)}||\mbox{OOB} \rightarrow E$
-   Parameters: $P||\mbox{Hash(Param)}||\mbox{Hash(Tx)} \rightarrow E$
-   DBC: $D||\mbox{Hash(DBC L-Value)}||\mbox{Hash(Tx)} \rightarrow E$

$\mbox{OOB}$: Data that resulted from AC script.

Hash chain: $$CE_{n+1} = \mbox{Counter}||\mbox{Date}||Hash(CE_n)||E$$

-   $E$ can be looked up by API, returns hash chain line.
-   Last hash chain line returned, if looking up empty $E$.
-   Allows... **TODO ?**

Signing rules:

-   AC script verify.
-   Transaction is known or all elements are unique.
-   Signed by self or signed by quorum.

Quorum must be $>51\%$, should be $>75\%$. Quorum for signing can be
smaller than quorum for membership.

Access control script (AC script)
---------------------------------

The access control script (AC script) of Scrit determines who can spend
a DBC, similar to the script in Bitcoin transactions.

-   Registers:
    -   Instructions can have return value written into register $R_0$.
    -   Registers $R_1$ to $R_7$ can be set.
    -   Registers are untyped and 32 byte wide.
    -   Instructions are 2 bytes plus 32 bytes parameters.
-   Alignment (**TODO ?**)

Instructions:

-   SKIP $<$instructions$>$: Skip instructions forward without
    execution.
-   NOP $<$nopdata$>$: No operation.
-   BEFORE $<$date$>$: Writes $1$ or $0$ into $R_0$.
-   AFTER $<$date$>$: Writes $1$ or $0$ into $R_0$.
-   SIGNEDBY $<$pubkey$>$: Writes $1$ or $0$ into $R_0$.
-   HASHBY $<$hashresult$>$: Writes $1$ or $0$ into $R_0$. **TODO ?**
-   HASHBYOOB $<$hashresult$>$: Writes $1$ or $0$ into $R_0$, adds
    hashkey into $OOB$.
-   DBCSPENT $<$hash of DBC L-Value$>$: Check spendboo, set $R_0$.
-   SETREG1...7 $<$var$>$: Set register to value.

**TODO**: finish section

Distribution
============

![Scrit client talk to all mints in parallel.](image/distributed.pdf)

Governance
==========

-   Codechain
-   new money is also part of Codechain

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
gives the sender cryptographic proof of payment. **TODO**: How does the
proof work?

In scenario 2. (only sender online) the sender scans a QR code from the
recipient containing the payment sum, the DBC public key of the
recipient, and configuration data for a local Bluetooth or WiFi
connection to the recipient. The sender reissues the necessary DBC to
reach the payment sum for the recipient's public key, creating assigned
DBCs. He then opens up a local Bluetooth or WiFi connection to transfer
them to the recipient. The recipient checks locally that he hasn't seen
these DBCs before (to prevent double spends) and later reissues them.
This gives the sender cryptographic proof of payment. **TODO**: How does
the proof work?

In scenario 3. (only recipient online) the sender scans a QR code from
the recipient containing the payment sum, the DBC public key of the
recipient, and configuration data for a local Bluetooth or WiFi
connection to the recipient. The sender opens up a local Bluetooth or
WiFi connection to transfer unassigned DBCs to the recipient. The
recipient immediately reissues them to prevent double spends. The
recipient confirms the payment, however this does **not** give the
sender cryptographic proof of payment.

In scenario 4. (both offline) the sender scans a QR code from the
recipient containing the payment sum, the DBC public key of the
recipient, and configuration data for a local Bluetooth or WiFi
connection to the recipient. The sender opens up a local Bluetooh or
WiFi connection to transfer **previously assigned** DBCs to the
recipient. The recipient checks locally that he hasn't seen these DBCs
before (to prevent a double spends) and confirms the payments. **TODO**:
What kind of payment proofs do we get here?

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

References
==========
