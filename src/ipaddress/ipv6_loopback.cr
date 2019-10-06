require "./ipv6"

module IPAddress
  # The loopback address is a unicast localhost address. If an
  # application in a host sends packets to this address, the IPv6 stack
  # will loop these packets back on the same virtual interface.
  #
  # Loopback addresses are expressed in the following form:
  #
  #     ::1
  #
  # or, with their appropriate prefix,
  #
  #     ::1/128
  #
  # As for the unspecified addresses, IPv6 loopbacks can be created with
  # `IPAddress` calling their own class:
  #
  # ```
  # ip6 = IPAddress::IPv6::Loopback.new
  # ip6.to_string # => "::1/128"
  # ```
  #
  # or by using the wrapper:
  #
  # ```
  # ip6 = IPAddress.new "::1"
  # ip6.to_string # => "::1/128"
  # ```
  #
  # Checking if an address is loopback is easy with the `IPv6#loopback?`
  # method:
  #
  # ```
  # ip6.loopback? # => true
  # ```
  #
  # The IPv6 loopback address corresponds to `127.0.0.1` in IPv4.
  class IPv6::Loopback < IPv6
    protected def self.new(addr : String, netmask = nil)
      super
    end

    # Creates a new `IPv6` unspecified address.
    #
    # ```
    # ip6 = IPAddress::IPv6::Loopback.new
    # ip6.to_string # => "::1/128"
    # ```
    def self.new
      address = ("0000:" * 7) + "0001"
      new address, 128
    end
  end
end
