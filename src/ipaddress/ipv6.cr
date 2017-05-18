require "./prefix"

module IPAddress
  # Class `IPAddress::IPv6` is used to handle IPv6 type addresses.
  #
  # ## IPv6 addresses
  #
  # IPv6 addresses are 128 bits long, in contrast with IPv4 addresses
  # which are only 32 bits long. An IPv6 address is generally written as
  # eight groups of four hexadecimal digits, each group representing 16
  # bits or two octect. For example, the following is a valid IPv6
  # address:
  #
  #     2001:0db8:0000:0000:0008:0800:200c:417a
  #
  # Letters in an IPv6 address are usually written downcase, as per
  # RFC. You can create a new IPv6 object using uppercase letters, but
  # they will be converted.
  #
  # ### Compression
  #
  # Since IPv6 addresses are very long to write, there are some
  # semplifications and compressions that you can use to shorten them.
  #
  # * Leading zeroes: all the leading zeroes within a group can be
  #   omitted: "`0008`" would become "`8`"
  #
  # * A string of consecutive zeroes can be replaced by the string
  #   "`::`". This can be only applied once.
  #
  # Using compression, the IPv6 address written above can be shorten into
  # the following, equivalent, address:
  #
  #     2001:db8::8:800:200c:417a
  #
  # This short version is often used in human representation.
  #
  # ### Network Mask
  #
  # As we used to do with IPv4 addresses, an IPv6 address can be written
  # using the prefix notation to specify the subnet mask:
  #
  #     2001:db8::8:800:200c:417a/64
  #
  # The `/64` part means that the first 64 bits of the address are
  # representing the network portion, and the last 64 bits are the host
  # portion.
  class IPv6
    include IPAddress
    include Enumerable(IPv6)
    include Comparable(IPv6)

    # Inspired by [https://gist.github.com/cpetschnig/294476](https://gist.github.com/cpetschnig/294476)
    REGEXP = /^\s*((([0-9A-Fa-f]{1,4}:){7}([0-9A-Fa-f]{1,4}|:))|(([0-9A-Fa-f]{1,4}:){6}(:[0-9A-Fa-f]{1,4}|((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3})|:))|(([0-9A-Fa-f]{1,4}:){5}(((:[0-9A-Fa-f]{1,4}){1,2})|:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3})|:))|(([0-9A-Fa-f]{1,4}:){4}(((:[0-9A-Fa-f]{1,4}){1,3})|((:[0-9A-Fa-f]{1,4})?:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){3}(((:[0-9A-Fa-f]{1,4}){1,4})|((:[0-9A-Fa-f]{1,4}){0,2}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){2}(((:[0-9A-Fa-f]{1,4}){1,5})|((:[0-9A-Fa-f]{1,4}){0,3}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){1}(((:[0-9A-Fa-f]{1,4}){1,6})|((:[0-9A-Fa-f]{1,4}){0,4}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(:(((:[0-9A-Fa-f]{1,4}){1,7})|((:[0-9A-Fa-f]{1,4}){0,5}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:)))(%.+)?\s*$/

    # Format string to pretty print IPv6 addresses.
    IN6FORMAT = ("%04x:" * 8).rchop

    # Returns `true` if the given string is a valid IPv6 address.
    #
    # ```
    # IPAddress::IPv6.valid? "2002::1"          # => true
    # IPAddress::IPv6.valid? "2002::DEAD::BEEF" # => false
    # ```
    def self.valid?(addr : String)
      !!(REGEXP =~ addr)
    end

    # Extract 16 bit groups from a string.
    def self.groups(addr : String) : Array(Int32)
      if addr =~ /^(.*)::(.*)$/
        l, r = [$1, $2].map &.split(':')
      else
        l, r = addr.split(':'), [] of String
      end
      {l, r}.each &.reject! &.empty?
      groups = l + Array.new(8 - l.size - r.size, '0') + r
      groups.map &.to_i(16)
    end

    # Creates a new `IPv6` object from an unsigned 128 bits integer.
    #
    # ```
    # ip6 = IPAddress::IPv6.parse_u128 "42540766411282592856906245548098208122".to_big_i
    # ip6.prefix = 64
    #
    # ip6.to_string # => "2001:db8::8:800:200c:417a/64"
    # ```
    #
    # The *prefix* parameter is optional:
    #
    # ```
    # ip6 = IPAddress::IPv6.parse_u128 "42540766411282592856906245548098208122".to_big_i, 64
    # ip6.to_string # => "2001:db8::8:800:200c:417a/64"
    # ```
    def self.parse_u128(u128 : BigInt, prefix = 128) : IPv6
      str = IN6FORMAT % (0..7).map { |i| (u128 >> (112 - 16 * i)) & 0xffff }
      new str + "/#{prefix}"
    end

    # Creates a new `IPv6` object from binary data,
    # like the one you get from a network stream.
    #
    # For example, on a network stream the IP
    #
    #     "2001:db8::8:800:200c:417a"
    #
    # is represented with the binary data
    #
    #     Bytes[32, 1, 13, 184, 0, 0, 0, 0, 0, 8, 8, 0, 32, 12, 65, 122]
    #
    # With that data you can create a new `IPv6` object:
    #
    # ```
    # ip6 = IPAddress::IPv6.parse_data Bytes[32, 1, 13, 184, 0, 0, 0, 0, 0, 8, 8, 0, 32, 12, 65, 122]
    # ip6.prefix = 64
    #
    # ip6.to_s # => "2001:db8::8:800:200c:417a/64"
    # ```
    def self.parse_data(data : Bytes, prefix = 128) : IPv6
      io = IO::Memory.new(data)
      groups = [] of UInt16
      8.times do
        groups << io.read_bytes(UInt16, IO::ByteFormat::NetworkEndian)
      end
      new "#{IN6FORMAT % groups}/#{prefix}"
    end

    # Creates a new `IPv6` object from a number expressed in
    # hexadecimal format.
    #
    # ```
    # ip6 = IPAddress::IPv6.parse_hex "20010db80000000000080800200c417a"
    # ip6.prefix = 64
    #
    # ip6.to_string # => "2001:db8::8:800:200c:417a/64"
    # ```
    #
    # The *prefix* parameter is optional:
    #
    # ```
    # ip6 = IPAddress::IPv6.parse_hex "20010db80000000000080800200c417a", 64
    # ip6.to_string # => "2001:db8::8:800:200c:417a/64"
    # ```
    def self.parse_hex(hex : String, prefix = 128) : IPv6
      parse_u128 hex.to_big_i(16), prefix
    end

    # Expands an IPv6 address in the canocical form.
    #
    # ```
    # IPAddress::IPv6.expand "2001:0DB8:0:CD30::"
    # # => "2001:0DB8:0000:CD30:0000:0000:0000:0000"
    # ```
    def self.expand(addr : String) : String
      new(addr).address
    end

    # Compress an IPv6 address in its compressed form.
    #
    # ```
    # IPAddress::IPv6.compress "2001:0DB8:0000:CD30:0000:0000:0000:0000"
    # # => "2001:db8:0:cd30::"
    # ```
    def self.compress(addr : String) : String
      new(addr).compressed
    end

    # Returns the IPv6 address in uncompressed form.
    #
    # ```
    # ip6 = IPAddress.new "2001:db8::8:800:200c:417a/64"
    # ip6.address # => "2001:0db8:0000:0000:0008:0800:200c:417a"
    # ```
    getter address : String

    # Returns an array with the 16 bit groups in decimal format.
    #
    # ```
    # ip6 = IPAddress.new "2001:db8::8:800:200c:417a/64"
    # ip6.groups # => [8193, 3512, 0, 0, 8, 2048, 8204, 16762]
    # ```
    getter groups : Array(Int32)

    # Returns an instance of the prefix object.
    #
    # ```
    # ip6 = IPAddress.new "2001:db8::8:800:200c:417a/64"
    # ip6.prefix # => 64
    # ```
    getter prefix : Prefix128

    # Set a new prefix number for the object.
    #
    # This is useful if you want to change the prefix
    # to an object created with `IPv6.parse_u128` or
    # if the object was created using the default prefix
    # of 128 bits.
    #
    # ```
    # ip6 = IPAddress.new "2001:db8::8:800:200c:417a"
    # ip6.to_string # => "2001:db8::8:800:200c:417a/128"
    #
    # ip6.prefix = 64
    # ip6.to_string # => "2001:db8::8:800:200c:417a/64"
    # ```
    def prefix=(prefix : Int32) : Prefix128
      @prefix = Prefix128.new(prefix)
    end

    # Compressed form of the IPv6 address.
    #
    # ```
    # ip6 = IPAddress.new "2001:db8::8:800:200c:417a/64"
    # ip6.compressed # => "2001:db8::8:800:200c:417a"
    # ```
    getter compressed : String

    # Creates a new `IPv6` address object.
    #
    # An IPv6 address can be expressed in any of the following forms:
    #
    # * `2001:0db8:0000:0000:0008:0800:200C:417A`: IPv6 address with no compression
    # * `2001:db8:0:0:8:800:200C:417A`: IPv6 address with leading zeros compression
    # * `2001:db8::8:800:200C:417A`: IPv6 address with full compression
    #
    # In all these 3 cases, a new IPv6 address object will be created, using the default
    # subnet mask `/128`
    #
    # You can also specify the subnet mask as with IPv4 addresses:
    #
    # ```
    # # These two are the same:
    # ip6 = IPAddress::IPv6.new "2001:db8::8:800:200c:417a/64"
    # ip6 = IPAddress.new "2001:db8::8:800:200c:417a/64"
    # ```
    def initialize(addr : String)
      if addr["/"]?
        ip, netmask = addr.split('/')
      else
        ip, netmask = addr, 128
      end

      if ip =~ /:.+\./
        raise ArgumentError.new "Please use #{self.class}::Mapped for IPv6 mapped addresses"
      end

      unless self.class.valid? ip
        raise ArgumentError.new "Invalid IP: #{ip}"
      end

      @prefix = Prefix128.new netmask.to_i
      @groups = self.class.groups ip
      @address = IN6FORMAT % @groups
      @compressed = compress_address
    end

    # Unlike its counterpart `#to_string` method, `#to_string_uncompressed`
    # returns the whole IPv6 address and prefix in an uncompressed form.
    #
    # ```
    # ip6 = IPAddress.new "2001:db8::8:800:200c:417a/64"
    # ip6.to_string_uncompressed # => "2001:0db8:0000:0000:0008:0800:200c:417a/64"
    # ```
    def to_string_uncompressed : String
      "#{@address}/#{@prefix}"
    end

    # Returns the IPv6 address in a human readable form,
    # using the compressed address.
    #
    # ```
    # ip6 = IPAddress.new "2001:0db8:0000:0000:0008:0800:200c:417a/64"
    # ip6.to_string # => "2001:db8::8:800:200c:417a/64"
    # ```
    def to_string : String
      "#{@compressed}/#{@prefix}"
    end

    # Appends to the given `IO` the IPv6 address in a human readable form,
    # using the compressed address.
    #
    # ```
    # ip6 = IPAddress.new "2001:db8::8:800:200c:417a/64"
    # ip6.to_s # => "2001:db8::8:800:200c:417a"
    # ```
    def to_s(io : IO)
      io << @compressed
    end

    # Returns a decimal format (unsigned 128 bit) of the IPv6 address.
    #
    # ```
    # ip6 = IPAddress.new "2001:db8::8:800:200c:417a/64"
    # ip6.to_u128 # => 42540766411282592856906245548098208122
    # ```
    def to_u128 : BigInt
      to_hex.to_big_i(16)
    end

    # Returns `true` if the IPv6 address is a network.
    #
    # ```
    # ip6 = IPAddress.new "2001:db8::8:800:200c:417a/64"
    # ip6.network? # => false
    #
    # ip6 = IPAddress.new "2001:db8:8:800::/64"
    # ip6.network? # => true
    # ```
    def network?
      to_u128 | @prefix.to_u128 == @prefix.to_u128
    end

    # Returns the 16-bits value specified by *index*.
    #
    # ```
    # ip6 = IPAddress.new "2001:db8::8:800:200c:417a/64"
    #
    # ip6[0] # => 8193
    # ip6[1] # => 3512
    # ip6[2] # => 0
    # ip6[3] # => 0
    # ```
    #
    # See also: `#groups`
    def [](index : Int32) : Int32
      @groups[index]
    end

    # Updates the 16-bits value specified at *index*.
    #
    # See also: `#groups`
    def []=(index : Int32, value : Int32) : Void
      @groups[index] = value
      initialize "#{IN6FORMAT % @groups}/#{@prefix}"
    end

    # Returns a base16 number representing the IPv6 address.
    #
    # ```
    # ip6 = IPAddress.new "2001:db8::8:800:200c:417a/64"
    # ip6.to_hex # => "20010db80000000000080800200c417a"
    # ```
    def to_hex : String
      hexs.join
    end

    # Returns an array of the 16 bits groups in hexadecimal format.
    #
    # ```
    # ip6 = IPAddress.new "2001:db8::8:800:200c:417a/64"
    # ip6.hexs # => ["2001", "0db8", "0000", "0000", "0008", "0800", "200c", "417a"]
    # ```
    #
    # Not to be confused with the similar `#to_hex` method.
    def hexs : Array(String)
      @address.split(':')
    end

    # Returns the IPv6 address in a DNS reverse lookup
    # string, as per [RFC3172](https://tools.ietf.org/html/rfc3172) and
    # [RFC2874](https://tools.ietf.org/html/rfc2874).
    #
    # ```
    # ip6 = IPAddress.new "3ffe:505:2::f"
    # ip6.reverse # => "f.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.2.0.0.0.5.0.5.0.e.f.f.3.ip6.arpa"
    # ```
    def reverse : String
      to_hex.reverse.gsub(/./, &.+('.')) + "ip6.arpa"
    end

    # Returns the network number in unsigned 128 bits format.
    #
    # ```
    # ip6 = IPAddress.new "2001:db8::8:800:200c:417a/64"
    # ip6.network_u128 # => 42540766411282592856903984951653826560
    # ```
    def network_u128 : BigInt
      to_u128 & @prefix.to_u128
    end

    # Returns the broadcast address in unsigned 128 bits format.
    #
    # ```
    # ip6 = IPAddress.new "2001:db8::8:800:200c:417a/64"
    # ip6.broadcast_u128 # => 42540766411282592875350729025363378175
    # ```
    #
    # NOTE: Please note that there is no broadcast concept in IPv6
    # addresses as in IPv4 addresses, and this method is just
    # a helper to other functions.
    def broadcast_u128 : BigInt
      network_u128 + size - 1
    end

    # Returns the number of IP addresses included
    # in the network. It also counts the network
    # address and the broadcast address.
    #
    # ```
    # ip6 = IPAddress.new "2001:db8::8:800:200c:417a/64"
    # ip6.size # => 18446744073709551616
    # ```
    def size : BigInt
      2.to_big_i ** @prefix.host_prefix
    end

    # Checks whether a subnet includes the given IP address.
    #
    # ```
    # ip6 = IPAddress.new "2001:db8::8:800:200c:417a/64"
    #
    # addr1 = IPAddress.new "2001:db8::8:800:200c:1/128"
    # addr2 = IPAddress.new "2001:db8:1::8:800:200c:417a/76"
    #
    # ip6.includes? addr1 # => true
    # ip6.includes? addr2 # => false
    # ```
    def includes?(other : IPv6)
      @prefix <= other.prefix && network_u128 == self.class.new(other.address + "/#{@prefix}").network_u128
    end

    # Checks whether a subnet includes all the given `IPv6` objects.
    #
    # ```
    # ip6 = IPAddress.new "2001:db8::4/125"
    #
    # addr1 = IPAddress.new "2001:db8::2/125"
    # addr2 = IPAddress.new "2001:db8::7/125"
    #
    # ip6.includes? addr1, addr2 # => true
    # ```
    def includes?(*others : IPv6)
      includes? others.to_a
    end

    # ditto
    def includes?(others : Array(IPv6))
      others.all? &->includes?(IPv6)
    end

    private def includes_self?(*ips : String)
      ips = ips.map &->IPv6.new(String)
      ips.any? &.includes?(self)
    end

    # Returns `true` if the address is an unspecified address.
    #
    # See `IPv6::Unspecified` for more information.
    def unspecified?
      @prefix == 128 && @compressed == "::"
    end

    # Returns `true` if the address is a loopback address.
    #
    # See `IPv6::Loopback` for more information.
    def loopback?
      @prefix == 128 && @compressed == "::1"
    end

    # Returns `true` if the address is a mapped address.
    #
    # See `IPv6::Mapped` for more information.
    def mapped?
      to_u128 >> 32 == 0xffff
    end

    # Checks if an `IPv6` address objects belongs
    # to a link-local network [RFC4291](https://tools.ietf.org/html/rfc4291).
    #
    # ```
    # ip = IPAddress.new "fe80::1"
    # ip.link_local? # => true
    # ```
    def link_local?
      includes_self? "fe80::/64"
    end

    # Checks if an `IPv6` address objects belongs
    # to a unique-local network [RFC4193](https://tools.ietf.org/html/rfc4193).
    #
    # ```
    # ip = IPAddress.new "fc00::1"
    # ip.unique_local? # => true
    # ```
    def unique_local?
      includes_self? "fc00::/7"
    end

    # Iterates over all the IP addresses for the given
    # network (or IP address).
    #
    # The object yielded is a new `IPv6` object created
    # from the iteration.
    #
    # ```
    # ip6 = IPAddress.new "2001:db8::4/125"
    #
    # ip6.each do |i|
    #   p i.compressed
    # end
    # # => "2001:db8::"
    # # => "2001:db8::1"
    # # => "2001:db8::2"
    # # => "2001:db8::3"
    # # => "2001:db8::4"
    # # => "2001:db8::5"
    # # => "2001:db8::6"
    # # => "2001:db8::7"
    # ```
    #
    # NOTE: If the host portion is very large, this method
    # can be very slow and possibly hang your system!
    def each : Void
      (network_u128..broadcast_u128).each do |i|
        yield self.class.parse_u128 i, @prefix
      end
    end

    # Spaceship operator to compare `IPv6` objects.
    #
    # Comparing `IPv6` addresses is useful to ordinate
    # them into lists that match our intuitive
    # perception of ordered IP addresses.
    #
    # The first comparison criteria is the u128 value.
    # For example, `2001:db8:1::1` will be considered
    # to be less than `2001:db8:2::1`, because, in a ordered list,
    # we expect `2001:db8:1::1` to come before `2001:db8:2::1`.
    #
    # The second criteria, in case two `IPv6` objects
    # have identical addresses, is the prefix. An higher
    # prefix will be considered greater than a lower
    # prefix. This is because we expect to see
    # `2001:db8:1::1/64` come before `2001:db8:1::1/65`.
    #
    # ```
    # ip1 = IPAddress.new "2001:db8:1::1/64"
    # ip2 = IPAddress.new "2001:db8:2::1/64"
    # ip3 = IPAddress.new "2001:db8:1::1/65"
    #
    # ip1 < ip2 # => true
    # ip1 < ip3 # => false
    #
    # [ip1, ip2, ip3].sort.map &.to_string
    # # => ["2001:db8:1::1/64", "2001:db8:1::1/65", "2001:db8:2::1/64"]
    # ```
    def <=>(other : IPv6)
      if to_u128 == other.to_u128
        @prefix <=> other.prefix
      else
        to_u128 <=> other.to_u128
      end
    end

    def_equals_and_hash @address, @prefix

    # Returns the successor to the IP address.
    #
    # ```
    # ip6 = IPAddress.new "2001:db8::8:800:200c:417a/64"
    # ip6.succ.to_string # => "2001:db8::8:800:200c:417b/64"
    # ```
    def succ : IPv6
      self.class.parse_u128(to_u128.succ, @prefix)
    end

    # Returns the predecessor to the IP address.
    #
    # ```
    # ip6 = IPAddress.new "2001:db8::8:800:200c:417a/64"
    # ip6.pred.to_string # => "2001:db8::8:800:200c:4179/64"
    # ```
    def pred : IPv6
      self.class.parse_u128(to_u128.pred, @prefix)
    end

    # Returns the address portion of an IP in binary format,
    # as a string containing a sequence of `0` and `1`.
    #
    # ```
    # ip6 = IPAddress.new "2001:db8::8:800:200c:417a"
    # ip6.bits # => "0010000000000001000011011011100000 [...]"
    # ```
    def bits : String
      @groups.map { |i| "%016b" % i }.join
    end

    # Returns the address portion of an `IPv6` object
    # in a network byte order format (`IO::ByteFormat::NetworkEndian`).
    #
    # ```
    # ip6 = IPAddress.new "2001:db8::8:800:200c:417a/64"
    # ip6.data # => Bytes[172, 16, 10, 1]
    # ```
    #
    # It is usually used to include an IP address
    # in a data packet to be sent over a socket
    #
    # ```
    # ip6 = IPAddress.new "2001:db8::8:800:200c:417a/64"
    # socket = Socket.new(params) # socket details here
    #
    # # Send binary data
    # socket.send "Address: "
    # socket.send ip6.data
    # ```
    def data : Bytes
      io = IO::Memory.new
      @groups.each do |group|
        io.write_bytes group.to_u16, IO::ByteFormat::NetworkEndian
      end
      io.to_slice
    end

    # Literal version of the IPv6 address.
    #
    # ```
    # ip6 = IPAddress.new "2001:db8::8:800:200c:417a/64"
    # ip6.literal # => "2001-0db8-0000-0000-0008-0800-200c-417a.ipv6-literal.net"
    # ```
    def literal : String
      @address.gsub(':', '-') + ".ipv6-literal.net"
    end

    # Returns a new `IPv6` object with the network number for the given IP.
    #
    # ```
    # ip6 = IPAddress.new "2001:db8:1:1:1:1:1:1/32"
    # ip6.network.to_string # => "2001:db8::/32"
    # ```
    def network : IPv6
      self.class.parse_u128 network_u128, @prefix
    end

    private def compress_address
      str = @groups.join ':', &.to_s(16)
      replacements = {
        /\A0:0:0:0:0:0:0:0\Z/ => "::",
        /\b0:0:0:0:0:0:0\b/   => ":",
        /\b0:0:0:0:0:0\b/     => ":",
        /\b0:0:0:0:0\b/       => ":",
        /\b0:0:0:0\b/         => ":",
        /\b0:0:0\b/           => ":",
        /\b0:0\b/             => ":",
      }
      replacements.each do |pattern, replacement|
        if str[pattern]?
          str = str.sub pattern, replacement
          break
        end
      end
      str = str.sub /:{3,}/, "::"
    end
  end
end
