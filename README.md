# ipaddress.cr [![Build Status](https://travis-ci.org/Sija/ipaddress.cr.svg?branch=master)](https://travis-ci.org/Sija/ipaddress.cr)
[![FOSSA Status](https://app.fossa.io/api/projects/git%2Bgithub.com%2FSija%2Fipaddress.cr.svg?type=shield)](https://app.fossa.io/projects/git%2Bgithub.com%2FSija%2Fipaddress.cr?ref=badge_shield)

IPAddress is a Crystal library designed to make the use of IPv4 and IPv6
addresses simple, powerful and enjoyable. It provides a complete set of
methods to handle IP addresses for any need, from simple scripting to
full network design.

IPAddress is written with a full OO interface, and its code is easy to
read, maintain and extend. The documentation is full of examples, to
let you start being productive immediately.

This document provides a brief introduction to the library and
examples of typical usage.

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  ipaddress:
    github: sija/ipaddress.cr
```

## Usage

You can then use it in your programs with:

```crystal
require "ipaddress"
```

### IPv4

Class `IPAddress::IPv4` is used to handle IPv4 type addresses.

#### Create a new IPv4 address

The usual way to express an IP Address is using its dotted decimal
form, such as `172.16.10.1`, and a prefix, such as `24`, separated by a
slash:

    172.16.10.1/24

To create a new IPv4 object, you can use IPv4 own class:

```crystal
ip = IPAddress::IPv4.new "172.16.10.1/24"
```

or, in a easier way, using the `IPAddress.parse` method:

```crystal
ip = IPAddress.parse "172.16.10.1/24"
```

which accepts and parses any kind of IP (UInt32, IPv4, IPV6 and
IPv4-IPv6 mapped addresses).

If you like syntactic sugar, you can use the wrapper method
`IPAddress.new`, which is built around `IPAddress.parse`:

```crystal
ip = IPAddress.new "172.16.10.1/24"
```

You can specify an IPv4 address in any of two ways:

```crystal
IPAddress.new "172.16.10.1/24"
IPAddress.new "172.16.10.1/255.255.255.0"
```

In this example, prefix `/24` and netmask `255.255.255.0` are the same and
you have the flexibility to use either one of them.

If you don't explicitly specify the prefix (or the subnet mask),
IPAddress thinks you're dealing with host addresses and not with
networks. Therefore, the default prefix will be `/32`, or
`255.255.255.255`. For example:

```crystal
# Let's declare an host address
host = IPAddress::IPv4.new "10.1.1.1"

puts host.to_string
  # => "10.1.1.1/32"
```

The new created object has prefix `/32`, which is the same
as we created the following:

```crystal
host = IPAddress::IPv4.new "10.1.1.1/32"
```

You can also pass an `UInt32` to obtain an `IPv4` object:

```crystal
# Create host object
ip = IPAddress.new 167837953

puts ip.to_string
  # => "10.1.1.1/32"
```

#### Handling the IPv4 address

Once created, you can obtain the attributes for an IPv4 object:

```crystal
ip = IPAddress.new "172.16.10.1/24"

ip.address
  # => "172.16.10.1"
ip.prefix
  # => 24
```

In case you need to retrieve the netmask in IPv4 format, you can use
the `IPv4#netmask` method:

```crystal
ip.netmask
  # => "255.255.255.0"
```

A special attribute, `IPv4#octets`, is available to get the four
decimal octets from the IP address:

```crystal
ip.octets
  # => [172, 16, 10, 1]
```

Shortcut method `IPv4#[]`, provides access to a given octet within the
range:

```crystal
ip[1]
  # => 16
```

If you need to print out the IPv4 address in a canonical form, you can
use `IPv4#to_string`:

```crystal
ip.to_string
  # => "172.16.10.l/24"
```

#### Changing netmask

You can set a new prefix (netmask) after creating an IPv4
object. For example:

```crystal
ip.prefix = 25

ip.to_string
  # => "172.16.10.l/25"
```

If you need to use a netmask in IPv4 format, you can achieve so by
using the `IPv4#netmask=` method:

```crystal
ip.netmask = "255.255.255.252"

ip.to_string
  # => "172.16.10.1/30"
```

#### Working with networks, broadcasts and addresses

Some very important topics in dealing with IP addresses are the
concepts of *network* and *broadcast*, as well as the addresses
included in a range.

When you specify an IPv4 address such as `172.16.10.1/24`, you are
actually handling two different information:

* The IP address itself, `172.16.10.1`
* The subnet mask which indicates the network

The network number is the IP which has all zeroes in the host
portion. In our example, because the prefix is 24, we identify our
network number to have the last 8 (32-24) bits all zeroes.  Thus, IP
address `172.16.10.1/24` belongs to network `172.16.10.0/24`.

This is very important because, for instance, IP `172.16.10.1/16` is
very different to the previous one, belonging to the very different
network `172.16.0.0/16`.

##### Networks

With IPAddress it's very easy to calculate the network for an IP
address:

```crystal
ip = IPAddress.new "172.16.10.1/24"

net = ip.network
  # => #<IPAddress::IPv4:0xb7a5ab24 @octets=[172, 16, 10, 0],
                                   @prefix=24,
                                   @address="172.16.10.0">
net.to_string
  # => "172.16.10.0/24"
```

Method `IPv4#network` creates a new IPv4 object from the network
number, calculated after the original object. We want to outline here
that the network address is a perfect legitimate IPv4 address, which
just happen to have all zeroes in the host portion.

You can use method `IPv4#network?` to check whether an IP address is a
network or not:

```crystal
ip1 = IPAddress.new "172.16.10.1/24"
ip2 = IPAddress.new "172.16.10.4/30"

ip1.network?
  # => false
ip2.network?
  # => true
```

##### Broadcast

The broadcast address is the contrary than the network number: where
the network number has all zeroes in the host portion, the broadcast
address has all one's. For example, ip `172.16.10.1/24` has broadcast
`172.16.10.255/24`, where ip `172.16.10.1/16` has broadcast
`172.16.255.255/16`.

Method `IPv4#broadcast` has the same behavior as is `#network`
counterpart: it creates a new IPv4 object to handle the broadcast
address:

```crystal
ip = IPAddress.new "172.16.10.1/24"

bcast = ip.broadcast
  # => #<IPAddress::IPv4:0xb7a406fc @octets=[172, 16, 10, 255],
                                   @prefix=24,
                                   @address="172.16.10.255">
bcast.to_string
  # => "172.16.10.255/24"
```

##### Addresses, ranges and iterators

So we see that the netmask essentially specifies a range for IP
addresses that are included in a network: all the addresses between
the network number and the broadcast. IPAddress has many methods to
iterate between those addresses. Let's start with `IPv4#each`, which
iterates over all addresses in a range:

```crystal
ip = IPAddress.new "172.16.10.1/24"

ip.each do |addr|
  puts addr
end
```

It is important to note that it doesn't matter if the original IP is a
host IP or a network number (or a broadcast address): the `#each` method
only considers the range that the original IP specifies.

If you only want to iterate over hosts IP, use the `IPv4#each_host`
method:

```crystal
ip = IPAddress.new "172.16.10.1/24"

ip.each_host do |host|
  puts host
end
```

Methods `IPv4#first` and `IPv4#last` return a new object containing
respectively the first and the last host address in the range:

```crystal
ip = IPAddress.new "172.16.10.100/24"

ip.first.to_string
  # => "172.16.10.1/24"

ip.last.to_string
  # => "172.16.10.254/24"
```

Checking if an address is loopback is easy with the `IPv4#loopback?`
method:

```crystal
ip = IPAddress.new "127.0.0.1"

ip.loopback?
  # => true
```

Checking if an address is in the multicast range can be done using the `IPv4#multicast?`
method:

```crystal
ip = IPAddress.new "224.0.0.1/32"

ip.multicast?
  # => true
```

The ability to generate a range also exists by using the `IPv4#upto` method.
This allows you to create a subnet agnostic range based off a fixed amount:

```crystal
ip = IPAddress.new "172.16.10.100/24"

ip.upto("172.16.10.110")
  # => ["172.16.10.100", ..., "172.16.10.110"]
```

#### IP special formats

The IPAddress library provides a complete set of methods to access an
IPv4 address in special formats, such as binary, 32 bits unsigned int
and hexadecimal.

Let's take the following IPv4 as an example:

```crystal
ip = IPAddress.new "172.16.10.1/24"

ip.address
  # => "172.16.10.1"
```

The first thing to highlight here is that all these conversion methods
only take into consideration the address portion of an IPv4 object and
not the prefix (netmask).

So, to express the address in binary format, use the `IPv4#bits` method:

```crystal
ip.bits
  # => "10101100000100000000101000000001"
```

To calculate the 32 bits unsigned int format of the ip address, use
the `IPv4#to_u32` method:

```crystal
ip.to_u32
  # => 2886732289
```

Also, you can transform an IPv4 address into a format which is
suitable to use in IPv4-IPv6 mapped addresses:

```crystal
ip.to_ipv6
  # => "ac10:0a01"
```

Finally, much like `IPv4#to_ipv6` you can use to `IPv4#to_hex` method to return
a non-semicolon delineated string (useful with pcap/byte level usage):

```crystal
ip.to_hex
  # => "ac100a01"
```

#### Classful networks

IPAddress allows you to create and manipulate objects using the old
and deprecated (but apparently still popular) classful networks concept.

Classful networks and addresses don't have a prefix: their subnet mask
is univocally identified by their address, and therefore divided in classes.
As per [RFC 791](https://tools.ietf.org/html/rfc791), these classes are:

* Class A, from `0.0.0.0` to `127.255.255.255`
* Class B, from `128.0.0.0` to `191.255.255.255`
* Class C, from `192.0.0.0` to `255.255.255.255`

Since classful networks here are only considered to calculate the default
prefix number, classes D and E are not considered.

To create a classful IP and prefix from an IP address, use the
`IPv4.parse_classful` method:

```crystal
# Classful ip
ip = IPAddress::IPv4.parse_classful "10.1.1.1"

ip.prefix
  # => 8
```

The method automatically created a new IPv4 object and assigned it
the correct prefix.

You can easily check which CLASSFUL network an IPv4 object belongs:

```crystal
ip = IPAddress.new "10.0.0.1/24"
ip.a?
  # => true

ip = IPAddress.new "172.16.10.1/24"
ip.b?
  # => true

ip = IPAddress.new "192.168.1.1/30"
ip.c?
  # => true
```

Remember that these methods are only checking the address portion of an IP, and are
independent from its prefix, as classful networks have no concept of prefix.

For more information on CLASSFUL networks visit the
[Wikipedia page](http://en.wikipedia.org/wiki/Classful_network).

#### Network design with IPAddress

IPAddress includes a lot of useful methods to manipulate IPv4 and IPv6
networks and do some basic network design.

##### Subnetting

The process of subnetting is the division of a network into smaller
(in terms of hosts capacity) networks, called subnets, so that they
all share a common root, which is the starting network.

For example, if you have network `172.16.10.0/24`, we can subnet it
into 4 smaller subnets. The new prefix will be `/26`, because 4 is 2^2
and therefore we add 2 bits to the network prefix (24 + 2 = 26).

Subnetting is easy with IPAddress. You actually have two options:

* `IPv4#subnets`: specify a new prefix
* `IPv4#split`: tell IPAddress how many subnets you want to create

Let's examine `IPv4#subnets` first. Say you have network `172.16.10.0/24`
and you want to subnet it into `/26` networks. With IPAddress it's very
easy:

```crystal
network = IPAddress.new "172.16.10.0/24"

subnets = network.subnet26)

subnets.map(&.to_string)
  # => ["172.16.10.0/26",
       "172.16.10.64/26",
       "172.16.10.128/26",
       "172.16.10.192/26"]
```

As you can see, an Array has been created, containing 4 new IPv4 objects
representing the new subnets.

Another way to create subnets is to tell IPAddress how many subnets you'd
like to have, and letting the library calculate the new prefix for you.

Let's see how it works, using `IPv4#split` method. Say you want 4 new subnets:

```crystal
network = IPAddress.new "172.16.10.0/24"

subnets = network.split(4)

subnets.map(&.to_string)
  # => ["172.16.10.0/26",
       "172.16.10.64/26",
       "172.16.10.128/26",
       "172.16.10.192/26"]
```

Hey, that's the same result as before! This actually makes sense, as the
two operations are complementary. When you use `IPv4#subnets` with the new
prefix, IPAddress will always create a number of subnets that is a power
of two. This is equivalent to use `IPv4#split` with a power of 2.

Where `IPv4#split` really shines is with the so called "uneven subnetting".
You are not limited to split a network into a power-of-two numbers of
subnets: IPAddress lets you create any number of subnets, and it will
try to organize the new created network in the best possible way, making
an efficient allocation of the space.

An example here is worth a thousand words. Let's use the same network
as the previous examples:

```crystal
network = IPAddress.new "172.16.10.0/24"
```

How do we split this network into 3 subnets? Very easy:

```crystal
subnets = network.split(3)

subnets.map(&.to_string)
  # => ["172.16.10.0/26",
       "172.16.10.64/26",
       "172.16.10.128/25"]
```

As you can see, IPAddress tried to perform a good allocation by filling up
all the address space from the original network. There is no point in splitting
a network into 3 subnets like `172.16.10.0/26`, `172.16.10.64/26` and
`172.16.10.128/26`, as you would end up having `172.16.10.192/26` wasted (plus,
I suppose I wouldn't need a Crystal library to perform un-efficient IP
allocation, as I do that myself very well ;) ).

We can go even further and split into 11 subnets:

```crystal
network.split(11)
  # => ["172.16.10.0/28", "172.16.10.16/28", "172.16.10.32/28",
       "172.16.10.48/28", "172.16.10.64/28", "172.16.10.80/28",
       "172.16.10.96/28", "172.16.10.112/28", "172.16.10.128/27",
       "172.16.10.160/27", "172.16.10.192/26"]
```

As you can see, most of the networks are `/28`, with a few `/27` and one
`/26` to fill up the remaining space.

##### Summarization

Summarization (or aggregation) is the process when two or more
networks are taken together to check if a supernet, including
all and only these networks, exists. If it exists then this supernet
is called the summarized (or aggregated) network.
It is very important to understand that summarization can only
occur if there are no holes in the aggregated network, or, in
other words, if the given networks fill completely the address space
of the supernet. So the two rules are:

  1. The aggregate network must contain *all* the IP addresses of the
original networks;
  2. The aggregate network must contain *only* the IP addresses of the
original networks;

A few examples will help clarify the above. Let's consider for
instance the following two networks:

```crystal
ip1 = IPAddress.new "172.16.10.0/24"
ip2 = IPAddress.new "172.16.11.0/24"
```

These two networks can be expressed using only one IP address
network if we change the prefix:

```crystal
IPAddress::IPv4.summarize(ip1, ip2).map(&.to_string)
  # => ["172.16.10.0/23"]
```

We note how the network `172.16.10.0/23` includes all the
addresses specified in the above networks, and (more important) includes
ONLY those addresses.

If we summarized *ip1* and *ip2* with the following network:

    172.16.0.0/16

we would have satisfied rule #1 above, but not rule #2. So

    172.16.0.0/16

is not an aggregate network for *ip1* and *ip2*.

If it's not possible to compute a single aggregated network for
all the original networks, the method returns an array with all the
aggregate networks found. For example, the following four networks can be
aggregated in a single `/22`:

```crystal
ip1 = IPAddress.new "10.0.0.1/24"
ip2 = IPAddress.new "10.0.1.1/24"
ip3 = IPAddress.new "10.0.2.1/24"
ip4 = IPAddress.new "10.0.3.1/24"

IPAddress::IPv4.summarize(ip1, ip2, ip3, ip4).map(&.to_string)
  # => ["10.0.0.0/22"]
```

But the following networks can't be summarized in a single
network:

```crystal
ip1 = IPAddress.new "10.0.1.1/24"
ip2 = IPAddress.new "10.0.2.1/24"
ip3 = IPAddress.new "10.0.3.1/24"
ip4 = IPAddress.new "10.0.4.1/24"

IPAddress::IPv4.summarize(ip1, ip2, ip3, ip4).map(&.to_string)
  # => ["10.0.1.0/24", "10.0.2.0/23", "10.0.4.0/24"]
```

In this case, the two summarizable networks have been aggregated into
a single `/23`, while the other two networks have been left untouched.

##### Supernetting

Supernetting is a different operation than aggregation, as it only
works on a single network and returns a new single IPv4 object,
representing the supernet.

Supernetting is similar to subnetting, except that you getting as a
result a network with a smaller prefix (bigger host space). For
example, given the network:

```crystal
ip = IPAddress.new "172.16.10.0/24"
```

you can supernet it with a new `/23` prefix:

```crystal
ip.supernet(23).to_string
  # => "172.16.10.0/23"
```

However if you supernet it with a `/22` prefix, the network address will
change:

```crystal
ip.supernet(22).to_string
  # => "172.16.8.0/22"
```

This is because `172.16.10.0/22` is not a network anymore, but an host
address.

### IPv6

IPAddress is not only fantastic for IPv4 addresses, it's also great to
handle IPv6 addresses family! Let's discover together how to use it in
our projects.

#### IPv6 addresses

IPv6 addresses are 128 bits long, in contrast with IPv4 addresses
which are only 32 bits long. An IPv6 address is generally written as
eight groups of four hexadecimal digits, each group representing 16
bits or two octet. For example, the following is a valid IPv6
address:

    2001:0db8:0000:0000:0008:0800:200c:417a

Letters in an IPv6 address are usually written downcased, as per
RFC. You can create a new IPv6 object using uppercase letters, but
they will be converted.

##### Compression

Since IPv6 addresses are very long to write, there are some
simplifications and compressions that you can use to shorten them.

* Leading zeroes: all the leading zeroes within a group can be
  omitted: `0008` would become `8`
* A string of consecutive zeroes can be replaced by the string
  `::`. This can be only applied once.

Using compression, the IPv6 address written above can be shorten into
the following, equivalent, address:

    2001:db8::8:800:200c:417a

This short version is often used in human representation.

##### Network Mask

As we used to do with IPv4 addresses, an IPv6 address can be written
using the prefix notation to specify the subnet mask:

    2001:db8::8:800:200c:417a/64

The `/64` part means that the first 64 bits of the address are
representing the network portion, and the last 64 bits are the host
portion.

#### Using IPAddress with IPv6 addresses

All the IPv6 representations we've just seen are perfectly fine when
you want to create a new IPv6 address:

```crystal
ip6 = IPAddress.new "2001:0db8:0000:0000:0008:0800:200C:417A"
ip6 = IPAddress.new "2001:db8:0:0:8:800:200C:417A"
ip6 = IPAddress.new "2001:db8:8:800:200C:417A"
```

All three are giving out the same IPv6 object. The default subnet mask
for an IPv6 is 128, as IPv6 addresses don't have classes like IPv4
addresses. If you want a different mask, you can go ahead and explicit
it:

```crystal
ip6 = IPAddress.new "2001:db8::8:800:200c:417a/64"
```

Access the address portion and the prefix by using the respective
methods:

```crystal
ip6 = IPAddress.new "2001:db8::8:800:200c:417a/64"

ip6.address
  # => "2001:0db8:0000:0000:0008:0800:200c:417a"

ip6.prefix
  # => 64
```

A compressed version of the IPv6 address can be obtained with the
`IPv6#compressed` method:

```crystal
ip6 = IPAddress.new "2001:0db8:0000:0000:0008:200c:417a:00ab/64"

ip6.compressed
  # => "2001:db8::8:800:200c:417a"
```

#### Handling the IPv6 address

Accessing the groups that form an IPv6 address is very easy with the
`IPv6#groups` method:

```crystal
ip6 = IPAddress.new "2001:db8::8:800:200c:417a/64"

ip6.groups
  # => [8193, 3512, 0, 0, 8, 2048, 8204, 16762]
```

As with IPv4 addresses, each individual group can be accessed using
the `IPv6#[]` shortcut method:

```crystal
ip6[0]
  # => 8193
ip6[1]
  # => 3512
ip6[2]
  # => 0
ip6[3]
  # => 0
```

Note that each 16 bits group is expressed in its decimal form. You can
also obtain the groups into hexadecimal format using the `IPv6#hexs`
method:

```crystal
ip6.hexs
  # => => ["2001", "0db8", "0000", "0000", "0008", "0800", "200c", "417a"]
```

A few other methods are available to transform an IPv6 address into
decimal representation, with `IPv6#to_`:

```crystal
ip6.to_u128
  # => 42540766411282592856906245548098208122
```

or to hexadecimal representation:

```crystal
ip6.to_hex
  # => "20010db80000000000080800200c417a"
```

To print out an IPv6 address in human readable form, use the `IPv6#to_s`, `IPv6#to_string`
and `IPv6#to_string_uncompressed` methods:

```crystal
ip6 = IPAddress.new "2001:db8::8:800:200c:417a/64"

ip6.to_string
  # => "2001:db8::8:800:200c:417a/96"

ip6.to_string_uncompressed
  # => "2001:0db8:0000:0000:0008:0800:200c:417a/96"
```

As you can see, `IPv6#to_string` prints out the compressed form, while
`IPv6#to_string_uncompressed` uses the expanded version.

##### Compressing and uncompressing

If you have a string representing an IPv6 address, you can easily
compress it and uncompress it using the two class methods `IPv6.expand`
and `IPv6.compress`.

For example, let's say you have the following uncompressed IPv6
address:

```crystal
ip6str = "2001:0DB8:0000:CD30:0000:0000:0000:0000"
```

Here is the compressed version:

```crystal
IPAddress::IPv6.compress ip6str
  # => "2001:db8:0:cd30::"
```

The other way works as well:

```crystal
ip6str = "2001:db8:0:cd30::"

IPAddress::IPv6.expand ip6str
  # => "2001:0db8:0000:cd30:0000:0000:0000:0000"
```

These methods can be used when you don't want to create a new object
just for expanding or compressing an address (although a new object is
actually created internally).

#### New IPv6 address from other formats

You can create a new IPv6 address from different formats than just a
string representing the colon-hex groups.

A new IPv6 address can also be created from an unsigned 128 bits
integer:

```crystal
u128 = "42540766411282592856906245548098208122".to_big_i

ip6 = IPAddress::IPv6.parse_u128 u128
ip6.prefix = 64

ip6.to_string
  # => "2001:db8::8:800:200c:417a/64"
```

Finally, a new IPv6 address can be created from an hex string:

```crystal
hex = "20010db80000000000080800200c417a"

ip6 = IPAddress::IPv6.parse_hex hex
ip6.prefix = 64

ip6.to_string
  # => "2001:db8::8:800:200c:417a/64"
```

#### Special IPv6 addresses

Some IPv6 have a special meaning and are expressed in a special form,
quite different than an usual IPv6 address. IPAddress has built-in
support for unspecified, loopback and mapped IPv6 addresses.

##### Unspecified address

The address with all zero bits is called the *unspecified* address
(corresponding to `0.0.0.0` in IPv4). It should be something like this:

    0000:0000:0000:0000:0000:0000:0000:0000

but, with the use of compression, it is usually written as just two
colons:

    ::

or, specifying the netmask:

    ::/128

With IPAddress, create a new unspecified IPv6 address using its own
subclass:

```crystal
ip = IPAddress::IPv6::Unspecified.new

ip.to_string
  # => "::/128"
```

You can easily check if an IPv6 object is an unspecified address by
using the `IPv6#unspecified?` method:

```crystal
ip.unspecified?
  # => true
```

An unspecified IPv6 address can also be created with the wrapper
method, like we've seen before:

```crystal
ip = IPAddress.new "::"

ip.unspecified?
  # => true
```

This address must never be assigned to an interface and is to be used
only in software before the application has learned its host's source
address appropriate for a pending connection. Routers must not forward
packets with the unspecified address.

##### Loopback address

The loopback address is a unicast localhost address. If an
application in a host sends packets to this address, the IPv6 stack
will loop these packets back on the same virtual interface.

Loopback addresses are expressed in the following form:

    ::1

or, with their appropriate prefix,

    ::1/128

As for the unspecified addresses, IPv6 loopbacks can be created with
IPAddress calling their own class:

```crystal
ip = IPAddress::IPv6::Loopback.new

ip.to_string
  # => "::1/128"
```

or by using the wrapper:

```crystal
ip = IPAddress.new "::1"

ip.to_string
  # => "::1/128"
```

Checking if an address is loopback is easy with the `IPv6#loopback?` method:

```crystal
ip.loopback?
  # => true
```

The IPv6 loopback address corresponds to `127.0.0.1` in IPv4.

##### Mapped address

It is usually identified as a IPv4 mapped IPv6 address, a particular
IPv6 address which aids the transition from IPv4 to IPv6. The
structure of the address is:

    ::ffff:w.y.x.z

where `w.x.y.z` is a normal IPv4 address. For example, the following is
a mapped IPv6 address:

    ::ffff:192.168.100.1

IPAddress is very powerful in handling mapped IPv6 addresses, as the
IPv4 portion is stored internally as a normal IPv4 object. Let's have
a look at some examples. To create a new mapped address, just use the
class builder itself:

```crystal
ip6 = IPAddress::IPv6::Mapped.new "::ffff:172.16.10.1/128"
```

or just use the wrapper method:

```crystal
ip6 = IPAddress.new "::ffff:172.16.10.1/128"
```

Let's check it's really a mapped address:

```crystal
ip6.mapped?
  # => true

ip6.to_string
  # => "::ffff:172.16.10.1/128"
```

Now with the `#ipv4` attribute, we can easily access the IPv4 portion
of the mapped IPv6 address:

```crystal
ip6.ipv4.address
  # => "172.16.10.1"
```

Internally, the IPv4 address is stored as two 16 bits
groups. Therefore all the usual methods for an IPv6 address are
working perfectly fine:

```crystal
ip6.to_hex
  # => "00000000000000000000ffffac100a01"

ip6.address
  # => "0000:0000:0000:0000:0000:ffff:ac10:0a01"
```

A mapped IPv6 can also be created just by specify the address in the
following format:

```crystal
ip6 = IPAddress.new "::172.16.10.1"
```

That is, two colons and the IPv4 address. However, as by RFC, the `ffff`
group will be automatically added at the beginning:

```crystal
ip6.to_string
  # => "::ffff:172.16.10.1/128"
```

making it a mapped IPv6 compatible address.

## Documentation

The code is fully documented. You can generate the documentation with:

```
crystal doc
```

The latest documentation can also be
[browsed online](https://sija.github.io/ipaddress.cr).

## Development

Run specs with:

```
crystal spec
```

## Contributing

1. Fork it ([https://github.com/sija/ipaddress.cr/fork](https://github.com/sija/ipaddress.cr/fork))
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Thanks to

- All of the contributors of [ipaddress](https://github.com/ipaddress-gem/ipaddress) gem,
from which this shard was ported.

Thanks to Luca Russo (vargolo) and Simone Carletti
(weppos) for all the support and technical review. Thanks to Marco Beri,
Bryan T. Richardson, Nicolas Fevrier, jdpace, Daniele Alessandri, jrdioko,
Ghislain Charrier, Pawel Krzesniak, Mark Sullivan, Leif Gensert,
Erik Ahlström, Peter Vandenberk and Steve Rawlinson for their support,
feedback and bug reports.

## Copyright

Copyright © 2009-2015 Marco Ceresa, Mike Mackintosh.  
Copyright © 2017 Sijawusz Pur Rahnama.

See [LICENSE](https://github.com/Sija/ipaddress.cr/blob/master/LICENSE) for details.


## License
[![FOSSA Status](https://app.fossa.io/api/projects/git%2Bgithub.com%2FSija%2Fipaddress.cr.svg?type=large)](https://app.fossa.io/projects/git%2Bgithub.com%2FSija%2Fipaddress.cr?ref=badge_large)