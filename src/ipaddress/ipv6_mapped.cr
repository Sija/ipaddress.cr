require "./ipv6"
require "./ipv4"

module IPAddress
  # It is usually identified as a IPv4 mapped IPv6 address, a particular
  # IPv6 address which aids the transition from IPv4 to IPv6. The
  # structure of the address is
  #
  #     ::ffff:w.y.x.z
  #
  # where `w.x.y.z` is a normal IPv4 address. For example, the following is
  # a mapped IPv6 address:
  #
  #     ::ffff:192.168.100.1
  #
  # `IPAddress` is very powerful in handling mapped IPv6 addresses, as the
  # IPv4 portion is stored internally as a normal `IPv4` object. Let's have
  # a look at some examples. To create a new mapped address, just use the
  # class builder itself
  #
  # ```
  # ip6 = IPAddress::IPv6::Mapped.new "::ffff:172.16.10.1/128"
  # ```
  #
  # or just use the wrapper method
  #
  # ```
  # ip6 = IPAddress.new "::ffff:172.16.10.1/128"
  # ```
  #
  # Let's check it's really a mapped address:
  #
  # ```
  # ip6.mapped?   # => true
  # ip6.to_string # => "::ffff:172.16.10.1/128"
  # ```
  #
  # Now with the *ipv4* attribute, we can easily access the IPv4 portion
  # of the mapped IPv6 address:
  #
  # ```
  # ip6.ipv4.address # => "172.16.10.1"
  # ```
  #
  # Internally, the IPv4 address is stored as two 16 bits
  # groups. Therefore all the usual methods for an IPv6 address are
  # working perfectly fine:
  #
  # ```
  # ip6.to_hex  # => "00000000000000000000ffffac100a01"
  # ip6.address # => "0000:0000:0000:0000:0000:ffff:ac10:0a01"
  # ```
  #
  # A mapped IPv6 can also be created just by specify the address in the
  # following format:
  #
  # ```
  # ip6 = IPAddress.new "::172.16.10.1"
  # ```
  #
  # That is, two colons and the IPv4 address. However, as by RFC, the `ffff`
  # group will be automatically added at the beginning
  #
  # ```
  # ip6.to_string # => "::ffff:172.16.10.1/128"
  # ```
  #
  # making it a mapped IPv6 compatible address.
  class IPv6::Mapped < IPv6
    # Internal `IPv4` address.
    getter ipv4 : IPv4

    # Creates a new IPv6 IPv4-mapped address.
    #
    # ```
    # ip6 = IPAddress::IPv6::Mapped.new "::ffff:172.16.10.1/128"
    # ipv6.ipv4.class # => IPAddress::IPv4
    # ```
    #
    # An IPv6 IPv4-mapped address can also be created using the
    # IPv6 only format of the address:
    #
    # ```
    # ip6 = IPAddress::IPv6::Mapped.new "::0d01:4403"
    # ip6.to_string # => "::ffff:13.1.68.3"
    # ```
    def initialize(addr : String)
      if addr["/"]?
        string, netmask = addr.split('/')
      else
        string, netmask = addr, 128
      end

      if string["."]?
        # IPv4 in dotted decimal form
        @ipv4 = IPv4.extract(string)
      else
        # IPv4 in hex form
        groups = IPv6.groups(string)
        @ipv4 = IPv4.parse_u32 (groups[-2] << 16) + groups[-1]
      end

      super("::ffff:#{@ipv4.to_ipv6}/#{netmask}")
    end

    # Similar to `IPv6#to_s(io)`, but appends the IPv4 address
    # in dotted decimal format.
    #
    # ```
    # ip6 = IPAddress.new "::ffff:172.16.10.1/128"
    # ip6.to_s # => "::ffff:172.16.10.1"
    # ```
    def to_s(io : IO)
      io << "::ffff:"
      io << @ipv4.address
    end

    # Similar to `IPv6#to_string`, but prints out the IPv4 address
    # in dotted decimal format.
    #
    # ```
    # ip6 = IPAddress.new "::ffff:172.16.10.1/128"
    # ip6.to_string # => "::ffff:172.16.10.1/128"
    # ```
    def to_string : String
      "::ffff:#{@ipv4.address}/#{@prefix}"
    end

    # Returns `true` if the address is a mapped address.
    #
    # ```
    # ip6 = IPAddress.new "::ffff:172.16.10.1/128"
    # ip6.mapped? # => true
    # ```
    def mapped?
      true
    end
  end
end
