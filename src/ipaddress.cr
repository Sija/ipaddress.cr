require "./ipaddress/*"

# A Crystal library to manipulate IPv4 and IPv6 addresses.
#
# ```
# require "ipaddress"
# ```
module IPAddress
  # `IPAddress.new` is a wrapper method built around
  # IPAddress's library classes. Its purpose is to
  # make you indipendent from the type of IP address
  # you're going to use.
  #
  # For example, instead of creating the three types
  # of IP addresses using their own contructors:
  #
  # ```
  # ip = IPAddress::IPv4.new "172.16.10.1/24"
  # ip6 = IPAddress::IPv6.new "2001:db8::8:800:200c:417a/64"
  # ip6_mapped = IPAddress::IPv6::Mapped.new "::ffff:172.16.10.1/128"
  # ```
  #
  # you can just use the `IPAddress.new` wrapper:
  #
  # ```
  # ip = IPAddress.new "172.16.10.1/24"
  # ip6 = IPAddress.new "2001:db8::8:800:200c:417a/64"
  # ip6_mapped = IPAddress.new "::ffff:172.16.10.1/128"
  # ```
  #
  # All the object created will be instances of the
  # correct class:
  #
  # ```
  # ip.class         # => IPAddress::IPv4
  # ip6.class        # => IPAddress::IPv6
  # ip6_mapped.class # => IPAddress::IPv6::Mapped
  # ```
  #
  # See also `#parse`
  def self.new(addr : String | Int) : IPAddress
    parse addr
  end

  # Parse the argument string to create a new
  # `IPv4`, `IPv6` or mapped IP object.
  #
  # ```
  # ip = IPAddress.parse 167837953 # 10.1.1.1
  # ip = IPAddress.parse "172.16.10.1/24"
  # ip6 = IPAddress.parse "2001:db8::8:800:200c:417a/64"
  # ip6_mapped = IPAddress.parse "::ffff:172.16.10.1/128"
  # ```
  #
  # All the object created will be instances of the
  # correct class:
  #
  # ```
  # ip.class         # => IPAddress::IPv4
  # ip6.class        # => IPAddress::IPv6
  # ip6_mapped.class # => IPAddress::IPv6::Mapped
  # ```
  #
  # See also `#new`, `#ntoa`
  def self.parse(addr : String | Int) : IPAddress
    case addr
    when Int
      IPv4.new ntoa(addr)
    when /:.+\./
      IPv6::Mapped.new addr
    when /\./
      IPv4.new addr
    when /:/
      IPv6.new addr
    else
      raise ArgumentError.new "Unknown IP address: #{addr}"
    end
  end

  # Converts an `UInt32` to IPv4 string.
  #
  # ```
  # IPAddress.ntoa 167837953_u32 # => "10.1.1.1"
  # IPAddress.ntoa 0_u32         # => "0.0.0.0"
  # ```
  def self.ntoa(uint : UInt32) : String
    octets = [] of UInt32
    4.times do
      octets.unshift uint & 0xff
      uint >>= 8
    end
    octets.join '.'
  end

  # Converts an `Int` to IPv4 string, raises otherwise.
  #
  # ```
  # IPAddress.ntoa 167837953 # => "10.1.1.1"
  # IPAddress.ntoa 0         # => "0.0.0.0"
  # IPAddress.ntoa -1        # raises ArgumentError
  # ```
  def self.ntoa(int : Int) : String
    unless 0xffffffff >= int >= 0
      raise ArgumentError.new "Not a long integer: #{int}"
    end
    ntoa int.to_u32
  end

  # Converts an IPv4 string to `UInt32`.
  #
  # ```
  # IPAddress.aton "10.1.1.1" # => 167837953_u32
  # IPAddress.aton "0.0.0.0"  # => 0_u32
  # ```
  def self.aton(addr : String) : UInt32
    # Array formed with the IP octets
    octets = addr.split('.').map &.to_u32
    # 32 bits integer containing the address
    (octets[0] << 24) + (octets[1] << 16) + (octets[2] << 8) + (octets[3])
  end

  # Returns `true` if the given string is a valid IP address,
  # either IPv4 or IPv6.
  #
  # ```
  # IPAddress.valid? "10.0.0.256" # => false
  # IPAddress.valid? "2002::1"    # => true
  # ```
  #
  # See also `#valid_ipv4?`, `#valid_ipv6?`
  def self.valid?(addr : String)
    valid_ipv4?(addr) || valid_ipv6?(addr)
  end

  # Returns `true` if the given string is a valid IPv4 address.
  #
  # ```
  # IPAddress.valid_ipv4? "172.16.10.1" # => true
  # IPAddress.valid_ipv4? "2002::1"     # => false
  # ```
  #
  # NOTE: Alias for `IPAddress::IPv4.valid?`
  def self.valid_ipv4?(addr : String)
    IPv4.valid? addr
  end

  # Returns `true` if the argument is a valid IPv4 netmask
  # expressed in dotted decimal format.
  #
  # ```
  # IPAddress.valid_ipv4_netmask? "255.255.0.0" # => true
  # ```
  #
  # NOTE: Alias for `IPAddress::IPv4.valid_netmask?`
  def self.valid_ipv4_netmask?(addr : String)
    IPv4.valid_netmask? addr
  end

  # Returns `true` if the given string is a valid IPv6 address.
  #
  # ```
  # IPAddress.valid_ipv6? "2002::1"          # => true
  # IPAddress.valid_ipv6? "2002::DEAD::BEEF" # => false
  # ```
  #
  # NOTE: Alias for `IPAddress::IPv6.valid?`
  def self.valid_ipv6?(addr : String)
    IPv6.valid? addr
  end

  # Returns `true` if the object is an `IPv4` address.
  #
  # ```
  # ip = IPAddress.new "192.168.10.100/24"
  # ip.ipv4? # => true
  # ```
  def ipv4?
    self.is_a? IPv4
  end

  # Returns `true` if the object is an `IPv6` address.
  #
  # ```
  # ip = IPAddress.new "192.168.10.100/24"
  # ip.ipv6? # => false
  # ```
  def ipv6?
    self.is_a? IPv6
  end
end
