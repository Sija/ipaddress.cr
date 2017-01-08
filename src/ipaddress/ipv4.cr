module IPAddress
  # Class `IPAddress::IPv4` is used to handle IPv4 type addresses.
  class IPv4
    include IPAddress
    include Enumerable(IPv4)
    include Comparable(IPv4)

    # This Hash contains the prefix values for classful networks:
    #
    # * Class A, from `0.0.0.0` to `127.255.255.255`
    # * Class B, from `128.0.0.0` to `191.255.255.255`
    # * Class C, D and E, from `192.0.0.0` to `255.255.255.254`
    #
    # NOTE: Classes C, D and E will all have a default
    # prefix of `/24` or `255.255.255.0`.
    CLASSFUL = {
      /^0../ => 8,
      /^10./ => 16,
      /^110/ => 24,
    }

    # Regular expression to match an IPv4 address
    REGEXP = /(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})/

    # :nodoc:
    REGEXP_BONDED = /\A#{REGEXP}\Z/

    # Returns `true` if the given string is a valid IPv4 address.
    #
    # ```
    # IPAddress::IPv4.valid? "172.16.10.1" # => true
    # IPAddress::IPv4.valid? "2002::1"     # => false
    # ```
    def self.valid?(addr : String)
      if REGEXP_BONDED =~ addr
        return ($~.size == 4) && (1..4).all? { |i| $~[i].to_i < 256 }
      end
      false
    end

    # Returns `true` if the argument is a valid IPv4 netmask
    # expressed in dotted decimal format.
    #
    # ```
    # IPAddress::IPv4.valid_netmask? "255.255.0.0" # => true
    # ```
    def self.valid_netmask?(addr : String)
      valid_netmask = addr.split('.').map { |i| "%08b" % i.to_u8 }.none? &.[]?("01")
      valid_netmask && valid?(addr)
    rescue
      false
    end

    # Returns the address portion of the IPv4 object
    # as a string.
    #
    # ```
    # ip = IPAddress.new "172.16.100.4/22"
    # ip.address # => "172.16.100.4"
    # ```
    getter address : String

    # Creates a new `IPv4` address object.
    #
    # An IPv4 address can be expressed in any of the following forms:
    #
    # * `10.1.1.1/24`: ip *address* and *prefix*. This is the common and
    # suggested way to create an object
    # * `10.1.1.1/255.255.255.0`: ip *address* and *netmask*. Although
    # convenient sometimes, this format is less clear than the previous
    # one
    # * `10.1.1.1`: if the address alone is specified, the prefix will be
    # set as default 32, also known as the host prefix
    #
    # ```
    # # These two are the same:
    # ip = IPAddress::IPv4.new "10.0.0.1/24"
    # ip = IPAddress.new "10.0.0.1/24"
    #
    # # These two are the same
    # ip = IPAddress::IPv4.new "10.0.0.1/8"
    # ip = IPAddress::IPv4.new "10.0.0.1/255.0.0.0"
    # ```
    def initialize(addr : String)
      if addr["/"]?
        ip, netmask = addr.split('/')
      else
        ip = addr
      end

      unless IPv4.valid? ip
        raise ArgumentError.new "Invalid IP #{ip}"
      end

      @address = ip.strip
      # ...
    end
  end
end
