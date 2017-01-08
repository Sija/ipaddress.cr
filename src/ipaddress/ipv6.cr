
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

    # Returns `true` if the given string is a valid IPv6 address.
    #
    # ```
    # IPAddress::IPv6.valid? "2002::1"          # => true
    # IPAddress::IPv6.valid? "2002::DEAD::BEEF" # => false
    # ```
    def self.valid?(addr : String)
      !!(REGEXP =~ addr)
    end

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

      # ...
    end
  end
end
