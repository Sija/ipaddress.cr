require "big"

module IPAddress
  # Parent class for `Prefix32` and `Prefix128`.
  #
  # `IPAddress::Prefix` is the parent class for `IPAddress::Prefix32`
  # and `IPAddress::Prefix128`, defining some modules in common for
  # both the subclasses.
  #
  # `IPAddress::Prefix` shouldn't be accessed directly, unless
  # for particular need.
  abstract struct Prefix
    include Comparable(Prefix)
    include Comparable(Int)

    # IP prefix value
    getter prefix : Int32

    # Creates a new general prefix.
    def initialize(num)
      @prefix = num.to_i
    end

    # Appends a string representation of the prefix to the given `IO` object.
    def to_s(io : IO)
      io << prefix
    end

    # Returns the prefix.
    def to_i : Int32
      prefix
    end

    # Compare the prefix.
    def <=>(other : Prefix)
      prefix <=> other.prefix
    end

    # Compare the prefix.
    def <=>(other : Int)
      prefix <=> other
    end

    # Sums two prefixes or a prefix to a number.
    def +(other : Prefix | Int)
      case other
      when Prefix
        prefix + other.prefix
      when Int
        prefix + other
      end
    end

    # Returns the difference between two prefixes,
    # or a prefix and a number.
    def -(other : Prefix | Int)
      case other
      when Prefix
        (prefix - other.prefix).abs
      when Int
        prefix - other
      end
    end
  end

  struct Prefix32 < Prefix
    # 32 bit mask for IPv4
    IN4MASK = 0xffffffff.to_u32

    # Creates a new prefix by parsing a netmask in
    # dotted decimal form.
    #
    # ```
    # prefix = IPAddress::Prefix32.parse_netmask "255.255.255.0" # => 24
    # ```
    def self.parse_netmask(netmask) : Prefix
      octets = netmask.split('.')
      num = octets.join { |i| "%08b" % i.to_u8 }.count '1'
      new(num)
    end

    # Creates a new prefix object for 32 bits IPv4 addresses.
    #
    # ```
    # prefix = IPAddress::Prefix32.new 24 # => 24
    # ```
    def initialize(num)
      unless (0..32).includes? num
        raise ArgumentError.new "Prefix must be in range 0..32, got: #{num}"
      end
      super(num)
    end

    # Returns the length of the host portion
    # of a netmask.
    #
    # ```
    # prefix = IPAddress::Prefix32.new 24
    # prefix.host_prefix # => 8
    # ```
    def host_prefix : Int32
      32 - prefix
    end

    # Transforms the prefix into a string of bits
    # representing the netmask.
    #
    # ```
    # prefix = IPAddress::Prefix32.new 24
    # prefix.bits # => "11111111111111111111111100000000"
    # ```
    def bits : String
      "%.32b" % to_u32
    end

    # Gives the prefix in IPv4 dotted decimal format,
    # i.e. the canonical netmask we're all used to.
    #
    # ```
    # prefix = IPAddress::Prefix32.new 24
    # prefix.to_ip # => "255.255.255.0"
    # ```
    def to_ip : String
      IPAddress.ntoa to_u32
    end

    # An array of octets of the IPv4 dotted decimal
    # format.
    #
    # ```
    # prefix = IPAddress::Prefix32.new 24
    # prefix.octets # => [255, 255, 255, 0]
    # ```
    #
    # See also `#to_ip`
    def octets : Array(Int32)
      to_ip.split('.').map &.to_i
    end

    # Unsigned 32 bits decimal number representing
    # the prefix.
    #
    # ```
    # prefix = IPAddress::Prefix32.new 24
    # prefix.to_u32 # => 4294967040
    # ```
    def to_u32 : UInt32
      (IN4MASK >> host_prefix) << host_prefix
    end

    # Shortcut for the octecs in the dotted decimal
    # representation.
    #
    # ```
    # prefix = IPAddress::Prefix32.new 24
    # prefix[2] # => 255
    # ```
    #
    # See also `#octets`
    def [](index) : Int32
      octets[index]
    end

    # The hostmask is the contrary of the subnet mask,
    # as it shows the bits that can change within the
    # hosts.
    #
    # ```
    # prefix = IPAddress::Prefix32.new 24
    # prefix.hostmask # => "0.0.0.255"
    # ```
    def hostmask : String
      octets.join '.' { |i| ~i.to_u8 }
    end
  end

  struct Prefix128 < Prefix
    # Creates a new prefix object for 128 bits IPv6 addresses.
    #
    # ```
    # prefix = IPAddress::Prefix128.new 64 # => 64
    # ```
    def initialize(num = 128)
      unless (0..128).includes? num.to_i
        raise ArgumentError.new "Prefix must be in range 0..128, got: #{num}"
      end
      super(num.to_i)
    end

    # Transforms the prefix into a string of bits
    # representing the netmask.
    #
    #     prefix = IPAddress::Prefix128.new 64
    #     prefix.bits
    #       #=> "1111111111111111111111111111111111111111111111111111111111111111"
    #           "0000000000000000000000000000000000000000000000000000000000000000"
    def bits : String
      "1" * @prefix + "0" * (128 - @prefix)
    end

    # Returns unsigned 128 bits decimal number representing
    # the prefix as `BigInt`.
    #
    # ```
    # prefix = IPAddress::Prefix128.new 64
    # prefix.to_u128 # => 340282366920938463444927863358058659840
    # ```
    def to_u128 : BigInt
      bits.to_big_i(2)
    end

    # Returns the length of the host portion
    # of a netmask.
    #
    # ```
    # prefix = IPAddress::Prefix128.new 96
    # prefix.host_prefix # => 32
    # ```
    def host_prefix : Int32
      128 - @prefix
    end
  end
end
