require "./prefix"

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
        return ($~.group_size == 4) && (1..4).all? { |i| $~[i].to_i < 256 }
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

    # Creates a new `IPv4` object from an unsigned 32 bits integer.
    #
    # ```
    # ip = IPAddress::IPv4.parse_u32 167772160
    #
    # ip.prefix = 8
    # ip.to_string # => "10.0.0.0/8"
    # ```
    #
    # The *prefix* parameter is optional:
    #
    # ```
    # ip = IPAddress::IPv4.parse_u32 167772160, 8
    # ip.to_string # => "10.0.0.0/8"
    # ```
    def self.parse_u32(u32, prefix = 32) : IPv4
      octets = [] of Int32
      4.times do
        octets.unshift u32.to_i & 0xff
        u32 >>= 8
      end
      address = octets.join '.'
      new "#{address}/#{prefix}"
    end

    # Creates a new `IPv4` object from binary data,
    # like the one you get from a network stream.
    #
    # For example, on a network stream the IP `172.16.0.1`
    # is represented with the binary `Bytes[172, 16, 0, 1]`.
    #
    # ```
    # ip = IPAddress::IPv4.parse_data Bytes[172, 16, 0, 1]
    # ip.prefix = 24
    #
    # ip.to_string # => "172.16.10.1/24"
    # ```
    def self.parse_data(data : Bytes, prefix = 32) : IPv4
      u32 = IO::ByteFormat::NetworkEndian.decode UInt32, data
      parse_u32 u32, prefix
    end

    # Creates a new `IPv4` address object by parsing the
    # address in a classful way.
    #
    # Classful addresses have a fixed netmask based on the
    # class they belong to:
    #
    # * Class A, from `0.0.0.0` to `127.255.255.255`
    # * Class B, from `128.0.0.0` to `191.255.255.255`
    # * Class C, D and E, from `192.0.0.0` to `255.255.255.254`
    #
    # ```
    # ip = IPAddress::IPv4.parse_classful "10.0.0.1"
    #
    # ip.netmask # => "255.0.0.0"
    # ip.a?      # => true
    # ```
    #
    # NOTE: Classes C, D and E will all have a default
    # prefix of `/24` or `255.255.255.0`.
    def self.parse_classful(ip : String) : IPv4
      unless valid? ip
        raise ArgumentError.new "Invalid IP: #{ip}"
      end
      first_octet_bits = "%08b" % ip.split('.').first.to_i
      prefix = CLASSFUL.find(&.first.===(first_octet_bits)).not_nil!.last
      new "#{ip}/#{prefix}"
    end

    # Extract an `IPv4` address from a string and
    # returns a new object.
    #
    # ```
    # ip = IPAddress::IPv4.extract "foobar172.16.10.1barbaz"
    # ip.to_s # => "172.16.10.1"
    # ```
    def self.extract(string : String) : IPv4
      if match = REGEXP.match(string)
        new match[0]
      else
        raise ArgumentError.new "IP address not found"
      end
    end

    # Summarization (or aggregation) is the process when two or more
    # networks are taken together to check if a supernet, including all
    # and only these networks, exists. If it exists then this supernet
    # is called the summarized (or aggregated) network.
    #
    # It is very important to understand that summarization can only
    # occur if there are no holes in the aggregated network, or, in other
    # words, if the given networks fill completely the address space
    # of the supernet. So the two rules are:
    #
    # 1. The aggregate network must contain *all* the IP addresses of the
    #    original networks;
    # 2. The aggregate network must contain *only* the IP addresses of the
    #    original networks;
    #
    # A few examples will help clarify the above. Let's consider for
    # instance the following two networks:
    #
    # ```
    # ip1 = IPAddress.new "172.16.10.0/24"
    # ip2 = IPAddress.new "172.16.11.0/24"
    # ```
    #
    # These two networks can be expressed using only one IP address
    # network if we change the prefix:
    #
    # ```
    # IPAddress::IPv4.summarize(ip1, ip2).map &.to_string
    # # => ["172.16.10.0/23"]
    # ```
    #
    # We note how the network "`172.16.10.0/23`" includes all the addresses
    # specified in the above networks, and (more important) includes
    # ONLY those addresses.
    #
    # If we summarized *ip1* and *ip2* with the following network:
    #
    #     "172.16.0.0/16"
    #
    # we would have satisfied rule #1 above, but not rule #2. So "`172.16.0.0/16`"
    # is not an aggregate network for *ip1* and *ip2*.
    #
    # If it's not possible to compute a single aggregated network for all the
    # original networks, the method returns an array with all the aggregate
    # networks found. For example, the following four networks can be
    # aggregated in a single `/22`:
    #
    # ```
    # ip1 = IPAddress.new "10.0.0.1/24"
    # ip2 = IPAddress.new "10.0.1.1/24"
    # ip3 = IPAddress.new "10.0.2.1/24"
    # ip4 = IPAddress.new "10.0.3.1/24"
    #
    # IPAddress::IPv4.summarize(ip1, ip2, ip3, ip4).map &.to_string
    # # => ["10.0.0.0/22"]
    # ```
    #
    # But the following networks can't be summarized in a single network:
    #
    # ```
    # ip1 = IPAddress.new "10.0.1.1/24"
    # ip2 = IPAddress.new "10.0.2.1/24"
    # ip3 = IPAddress.new "10.0.3.1/24"
    # ip4 = IPAddress.new "10.0.4.1/24"
    #
    # IPAddress::IPv4.summarize(ip1, ip2, ip3, ip4).map &.to_string
    # # => ["10.0.1.0/24", "10.0.2.0/23", "10.0.4.0/24"]
    # ```
    def self.summarize(ips : Array(IPv4)) : Array(IPv4)
      # one network? no need to summarize
      return [ips.first.network] if ips.size == 1

      result = ips.dup.sort.map &.network
      begin
        i = 0
        while i < result.size - 1
          sum = result[i] + result[i + 1]
          result[i..i + 1] = sum.first if sum.size == 1
          i += 1
        end
      end
      result = result.flatten
      if result.size == ips.size
        # nothing more to summarize
        result
      else
        # keep on summarizing
        summarize result
      end
    end

    # ditto
    def self.summarize(*ips : IPv4) : Array(IPv4)
      summarize ips.to_a
    end

    # Returns the address portion of the `IPv4` object as a string.
    #
    # ```
    # ip = IPAddress.new "172.16.100.4/22"
    # ip.address # => "172.16.100.4"
    # ```
    getter address : String

    # Returns the prefix portion of the `IPv4` object
    # as a `IPAddress::Prefix32` object.
    #
    # ```
    # ip = IPAddress.new "172.16.100.4/22"
    #
    # ip.prefix       # => 22
    # ip.prefix.class # => IPAddress::Prefix32
    # ```
    getter prefix : Prefix32

    # Set a new prefix number for the object.
    #
    # This is useful if you want to change the prefix
    # to an object created with `IPv4.parse_u32` or
    # if the object was created using the classful
    # mask.
    #
    # ```
    # ip = IPAddress.new "172.16.100.4"
    # ip.to_string # => 172.16.100.4/16
    #
    # ip.prefix = 22
    # ip.to_string # => 172.16.100.4/22
    # ```
    def prefix=(prefix : Int32) : Prefix32
      @prefix = Prefix32.new(prefix)
    end

    # Returns the address as an `Array` of decimal values.
    #
    # ```
    # ip = IPAddress.new "172.16.100.4"
    # ip.octets # => [172, 16, 100, 4]
    # ```
    getter octets : Array(Int32)

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
      if addr['/']?
        ip, netmask = addr.split('/')
      else
        ip = addr
      end

      unless self.class.valid? ip
        raise ArgumentError.new "Invalid IP: #{ip}"
      end

      @address = ip
      if netmask
        if netmask =~ /^\d{1,2}$/
          # netmask in CIDR format
          @prefix = Prefix32.new netmask.to_i
        elsif self.class.valid_netmask? netmask
          # netmask in IP format
          @prefix = Prefix32.parse_netmask netmask
        else
          # invalid netmask
          raise ArgumentError.new "Invalid netmask: #{netmask}"
        end
      else
        # netmask is `nil`, reverting to default classful mask
        @prefix = Prefix32.new 32
      end

      # Array formed with the IP octets
      @octets = @address.split('.').map &.to_i
      # 32 bits interger containing the address
      @u32 = IPAddress.aton address
    end

    # Returns the octet specified by *index*.
    #
    # ```
    # ip = IPAddress.new "172.16.100.50/24"
    #
    # ip[0] # => 172
    # ip[1] # => 16
    # ip[2] # => 100
    # ip[3] # => 50
    # ```
    #
    # See also: `#octets`
    def [](index : Int32) : Int32
      @octets[index]
    end

    # Updates the octet specified at *index*.
    #
    # ```
    # ip = IPAddress.new "172.16.100.50/24"
    # ip[2] = 200
    #
    # # => #<IPAddress::IPv4:0x00000000000000 @address="172.16.200.1",
    # # => @prefix=32, @octets=[172, 16, 200, 1], @u32=2886780929>
    # ```
    #
    # See also: `#octets`
    def []=(index : Int32, value : Int32) : Nil
      @octets[index] = value
      initialize "#{@octets.join('.')}/#{@prefix}"
    end

    # Appends a string with the address portion of the IPv4 object
    # to the given `IO` object.
    #
    # ```
    # ip = IPAddress.new "172.16.100.4/22"
    # ip.to_s # => "172.16.100.4"
    # ```
    def to_s(io : IO)
      io << @address
    end

    # Returns a string with the IP address in canonical form.
    #
    # ```
    # ip = IPAddress.new "172.16.100.4/22"
    # ip.to_string # => "172.16.100.4/22"
    # ```
    def to_string : String
      "#{@address}/#{@prefix}"
    end

    # Returns the prefix as a string in IP format.
    #
    # ```
    # ip = IPAddress.new "172.16.100.4/22"
    # ip.netmask # => "255.255.252.0"
    # ```
    def netmask : String
      @prefix.to_ip
    end

    # Like `IPv4#prefix=`, this method allow you to
    # change the prefix/netmask of an IP address object.
    #
    # ```
    # ip = IPAddress.new "172.16.100.4"
    # ip.to_string # => 172.16.100.4/16
    #
    # ip.netmask = "255.255.252.0"
    # ip.to_string # => 172.16.100.4/22
    # ```
    def netmask=(addr : String) : Nil
      @prefix = Prefix32.parse_netmask addr
    end

    # Returns the address portion in unsigned
    # 32 bits integer format.
    #
    # This method is identical to the C function
    # `inet_pton` to create a 32 bits address family
    # structure.
    #
    # ```
    # ip = IPAddress.new "10.0.0.0/8"
    # ip.to_u32 # => 167772160
    # ```
    def to_u32 : UInt32
      @u32
    end

    # Returns the address portion in hex.
    #
    # ```
    # ip = IPAddress.new "10.0.0.0"
    # ip.to_hex # => "0a000000"
    # ```
    def to_hex : String
      @octets.map { |i| "%02x" % i }.join
    end

    # Returns the address portion of an IP in binary format,
    # as a string containing a sequence of `0` and `1`.
    #
    # ```
    # ip = IPAddress.new "127.0.0.1"
    # ip.bits # => "01111111000000000000000000000001"
    # ```
    def bits : String
      @octets.map { |i| "%08b" % i }.join
    end

    # Returns the address portion of an `IPv4` object
    # in a network byte order format (`IO::ByteFormat::NetworkEndian`).
    #
    # ```
    # ip = IPAddress.new "172.16.10.1/24"
    # ip.data # => Bytes[172, 16, 10, 1]
    # ```
    #
    # It is usually used to include an IP address
    # in a data packet to be sent over a socket
    #
    # ```
    # ip = IPAddress.new "10.1.1.0/24"
    # socket = Socket.new(params) # socket details here
    #
    # # Send binary data
    # socket.send "Address: "
    # socket.send ip.data
    # ```
    def data : Bytes
      io = IO::Memory.new
      io.write_bytes to_u32, IO::ByteFormat::NetworkEndian
      io.to_slice
    end

    # Returns the broadcast address for the given IP.
    #
    # ```
    # ip = IPAddress.new "172.16.10.64/24"
    # ip.broadcast.to_s # => "172.16.10.255"
    # ```
    def broadcast : IPv4
      case
      when @prefix <= 30
        self.class.parse_u32 broadcast_u32, @prefix
      when @prefix == 31
        self.class.parse_u32 -1, @prefix
      when @prefix == 32
        self
      else
        # need it here to make compiler happy
        raise ArgumentError.new
      end
    end

    # Checks if the IP address is actually a network.
    #
    # ```
    # ip = IPAddress.new "172.16.10.64/24"
    # ip.network? # => false
    #
    # ip = IPAddress.new "172.16.10.64/26"
    # ip.network? # => true
    # ```
    def network?
      (@prefix < 32) && (@u32 | @prefix.to_u32 == @prefix.to_u32)
    end

    # Returns a new `IPv4` object with the network number
    # for the given IP.
    #
    # ```
    # ip = IPAddress.new "172.16.10.64/24"
    # ip.network.to_s # => "172.16.10.0"
    # ```
    def network : IPv4
      self.class.parse_u32 network_u32, @prefix
    end

    # Returns a new `IPv4` object with the
    # first host IP address in the range.
    #
    # Example: given the 192.168.100.0/24 network, the first
    # host IP address is 192.168.100.1.
    #
    # ```
    # ip = IPAddress.new "192.168.100.0/24"
    # ip.first.to_s # => "192.168.100.1"
    # ```
    #
    # The object IP doesn't need to be a network: the method
    # automatically gets the network number from it
    #
    # ```
    # ip = IPAddress.new "192.168.100.50/24"
    # ip.first.to_s # => "192.168.100.1"
    # ```
    def first : IPv4
      case
      when @prefix <= 30
        self.class.parse_u32 network_u32 + 1, @prefix
      when @prefix == 31
        self.class.parse_u32 network_u32, @prefix
      when @prefix == 32
        self
      else
        # need it here to make compiler happy
        raise ArgumentError.new
      end
    end

    # Like its sibling method `IPv4#first`, this method
    # returns a new `IPv4` object with the
    # last host IP address in the range.
    #
    # Example: given the `192.168.100.0/24` network, the last
    # host IP address is `192.168.100.254`.
    #
    # ```
    # ip = IPAddress.new "192.168.100.0/24"
    # ip.last.to_s # => "192.168.100.254"
    # ```
    #
    # The object IP doesn't need to be a network: the method
    # automatically gets the network number from it.
    #
    # ```
    # ip = IPAddress.new "192.168.100.50/24"
    # ip.last.to_s # => "192.168.100.254"
    # ```
    def last : IPv4
      case
      when @prefix <= 30
        self.class.parse_u32 broadcast_u32 - 1, @prefix
      when @prefix == 31
        self.class.parse_u32 broadcast_u32, @prefix
      when @prefix == 32
        self
      else
        # need it here to make compiler happy
        raise ArgumentError.new
      end
    end

    # Iterates over all the hosts IP addresses for the given
    # network (or IP address).
    #
    # ```
    # ip = IPAddress.new "10.0.0.1/29"
    # ip.each_host do |i|
    #   p i.to_s
    # end
    #
    # # => "10.0.0.1"
    # # => "10.0.0.2"
    # # => "10.0.0.3"
    # # => "10.0.0.4"
    # # => "10.0.0.5"
    # # => "10.0.0.6"
    # ```
    def each_host : Nil
      (network_u32 + 1..broadcast_u32 - 1).each do |i|
        yield self.class.parse_u32 i, @prefix
      end
    end

    # Iterates over all the IP addresses for the given
    # network (or IP address).
    #
    # The object yielded is a new IPv4 object created
    # from the iteration.
    #
    # ```
    # ip = IPAddress.new "10.0.0.1/29"
    # ip.each do |i|
    #   p i.address
    # end
    #
    # # => "10.0.0.0"
    # # => "10.0.0.1"
    # # => "10.0.0.2"
    # # => "10.0.0.3"
    # # => "10.0.0.4"
    # # => "10.0.0.5"
    # # => "10.0.0.6"
    # # => "10.0.0.7"
    # ```
    def each : Nil
      (network_u32..broadcast_u32).each do |i|
        yield self.class.parse_u32 i, @prefix
      end
    end

    # Spaceship operator to compare `IPv4` objects.
    #
    # Comparing `IPv4` addresses is useful to ordinate
    # them into lists that match our intuitive
    # perception of ordered IP addresses.
    #
    # The first comparison criteria is the `u32` value.
    # For example, `10.100.100.1` will be considered
    # to be less than `172.16.0.1`, because, in an ordered list,
    # we expect `10.100.100.1` to come before `172.16.0.1`.
    #
    # The second criteria, in case two `IPv4` objects
    # have identical addresses, is the prefix. An higher
    # prefix will be considered greater than a lower
    # prefix. This is because we expect to see
    # `10.100.100.0/24` come before `10.100.100.0/25`.
    #
    # ```
    # ip1 = IPAddress.new "10.100.100.1/8"
    # ip2 = IPAddress.new "172.16.0.1/16"
    # ip3 = IPAddress.new "10.100.100.1/16"
    #
    # ip1 < ip2 # => true
    # ip1 > ip3 # => false
    #
    # [ip1, ip2, ip3].sort.map &.to_string
    # # => ["10.100.100.1/8", "10.100.100.1/16", "172.16.0.1/16"]
    # ```
    def <=>(other : IPv4)
      if to_u32 == other.to_u32
        @prefix <=> other.prefix
      else
        to_u32 <=> other.to_u32
      end
    end

    def_equals_and_hash @address, @prefix

    # Returns the successor to the IP address.
    #
    # ```
    # ip = IPAddress.new "192.168.45.23/16"
    # ip.succ.to_string # => "192.168.45.24/16"
    # ```
    def succ : IPv4
      self.class.parse_u32(to_u32.succ, @prefix)
    end

    # Returns the predecessor to the IP address.
    #
    # ```
    # ip = IPAddress.new "192.168.45.23/16"
    # ip.pred.to_string # => "192.168.45.22/16"
    # ```
    def pred : IPv4
      self.class.parse_u32(to_u32.pred, @prefix)
    end

    # Returns the number of IP addresses included
    # in the network. It also counts the network
    # address and the broadcast address.
    #
    # ```
    # ip = IPAddress.new "10.0.0.1/29"
    # ip.size # => 8
    # ```
    def size : Int32
      2 ** @prefix.host_prefix
    end

    # Returns an array with the IP addresses of
    # all the hosts in the network.
    #
    # ```
    # ip = IPAddress.new "10.0.0.1/29"
    # ip.hosts.map &.address
    # # => ["10.0.0.1",
    # # => "10.0.0.2",
    # # => "10.0.0.3",
    # # => "10.0.0.4",
    # # => "10.0.0.5",
    # # => "10.0.0.6"]
    # ```
    def hosts : Array(IPv4)
      to_a[1..-2]
    end

    # Returns the network number in unsigned 32 bits format.
    #
    # ```
    # ip = IPAddress.new "10.0.0.1/29"
    # ip.network_u32 # => 167772160
    # ```
    def network_u32 : UInt32
      @u32 & @prefix.to_u32
    end

    # Returns the broadcast address in unsigned 32 bits format.
    #
    # ```
    # ip = IPaddress.new "10.0.0.1/29"
    # ip.broadcast_u32 # => 167772167
    # ```
    def broadcast_u32 : UInt32
      network_u32 + size - 1
    end

    # Checks whether a subnet includes the given IP address.
    #
    # Accepts an `IPAddress::IPv4` object.
    #
    # ```
    # ip = IPAddress.new "192.168.10.100/24"
    #
    # addr1 = IPAddress.new "192.168.10.102/24"
    # addr2 = IPAddress.new "172.16.0.48/16"
    #
    # ip.includes? addr1 # => true
    # ip.includes? addr2 # => false
    # ```
    def includes?(other : IPv4)
      @prefix <= other.prefix && network_u32 == (other.to_u32 & @prefix.to_u32)
    end

    # Checks whether a subnet includes all the given `IPv4` objects.
    #
    # ```
    # ip = IPAddress.new "192.168.10.100/24"
    #
    # addr1 = IPAddress.new "192.168.10.102/24"
    # addr2 = IPAddress.new "192.168.10.103/24"
    #
    # ip.includes? addr1, addr2 # => true
    # ```
    def includes?(*others : IPv4)
      includes? others.to_a
    end

    # ditto
    def includes?(others : Array(IPv4))
      others.all? &->includes?(IPv4)
    end

    private def includes_self?(*ips : String)
      ips = ips.map &->IPv4.new(String)
      ips.any? &.includes?(self)
    end

    # Checks if an `IPv4` address objects belongs
    # to a private network [RFC1918](https://tools.ietf.org/html/rfc1918).
    #
    # ```
    # ip = IPAddress.new "10.1.1.1/24"
    # ip.private? # => true
    # ```
    def private?
      includes_self? "10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"
    end

    # Checks if an `IPv4` address objects belongs
    # to a multicast network [RFC3171](https://tools.ietf.org/html/rfc3171).
    #
    # ```
    # ip = IPAddress.new "224.0.0.0/4"
    # ip.multicast? # => true
    # ```
    def multicast?
      includes_self? "224.0.0.0/4"
    end

    # Checks if an `IPv4` address objects belongs
    # to a loopback network [RFC1122](https://tools.ietf.org/html/rfc1122).
    #
    # ```
    # ip = IPAddress.new "127.0.0.1"
    # ip.loopback? # => true
    # ```
    def loopback?
      includes_self? "127.0.0.0/8"
    end

    # Checks if an `IPv4` address objects belongs
    # to a link-local network [RFC3927](https://tools.ietf.org/html/rfc3927).
    #
    # ```
    # ip = IPAddress.new "169.254.0.1"
    # ip.link_local? # => true
    # ```
    def link_local?
      includes_self? "169.254.0.0/16"
    end

    # Returns the IP address in `in-addr.arpa` format
    # for DNS lookups.
    #
    # ```
    # ip = IPAddress.new "172.16.100.50/24"
    # ip.reverse # => "50.100.16.172.in-addr.arpa"
    # ```
    def reverse : String
      @octets.reverse.join('.') + ".in-addr.arpa"
    end

    # Returns a list of IP's between `#address`
    # and the supplied IP.
    #
    # ```
    # ip = IPAddress.new "172.16.100.51/32"
    #
    # # implies .map &.to_s
    # ip.upto "172.16.100.100"
    # # => ["172.16.100.51",
    # # => "172.16.100.52",
    # # => ...
    # # => "172.16.100.99",
    # # => "172.16.100.100"]
    # ```
    def upto(limit : IPv4) : Array(IPv4)
      Range.new(@u32, limit.to_u32).map &->IPv4.parse_u32(UInt32)
    end

    # ditto
    def upto(limit : String) : Array(IPv4)
      upto self.class.new limit
    end

    # Tweaked to remove the #upto(32)
    private def newprefix(num)
      @prefix + Math.log2(num).ceil.to_i
    end

    private def sum_first_found(arr)
      dup = arr.dup.reverse
      dup.each_with_index do |obj, i|
        a = [self.class.summarize(obj, dup[i + 1])].flatten
        if a.size == 1
          dup[i..i + 1] = a
          return dup.reverse
        end
      end
      dup.reverse
    end

    # Splits a network into different subnets and returns
    # an array of `IPv4` objects.
    #
    # If the IP Address is a network, it can be divided into
    # multiple networks. If *self* is not a network, this
    # method will calculate the network from the IP and then
    # subnet it.
    #
    # If *subnets* is an power of two number, the resulting
    # networks will be divided evenly from the supernet.
    #
    # ```
    # network = IPAddress.new "172.16.10.0/24"
    #
    # # implies .map &.to_string
    # network / 4
    # # => ["172.16.10.0/26",
    # # => "172.16.10.64/26",
    # # => "172.16.10.128/26",
    # # => "172.16.10.192/26"]
    # ```
    #
    # If *num* is any other number, the supernet will be
    # divided into some networks with a even number of hosts and
    # other networks with the remaining addresses.
    #
    # ```
    # network = IPAddress.new "172.16.10.0/24"
    #
    # # implies .map &.to_string
    # network / 3
    # # => ["172.16.10.0/26",
    # # => "172.16.10.64/26",
    # # => "172.16.10.128/25"]
    # ```
    def split(subnets : Int32 = 2) : Array(IPv4)
      unless (1..(2 ** @prefix.host_prefix)).includes? subnets
        raise ArgumentError.new "Value out of range: #{subnets}"
      end
      networks = subnets newprefix(subnets)
      until networks.size == subnets
        networks = sum_first_found networks
      end
      networks
    end

    # ditto
    def /(subnets : Int32) : Array(IPv4)
      split subnets
    end

    # Returns a new `IPv4` object from the supernetting
    # of the instance network.
    #
    # Supernetting is similar to subnetting, except
    # that you getting as a result a network with a
    # smaller prefix (bigger host space). For example,
    # given the network:
    #
    # ```
    # ip = IPAddress.new "172.16.10.0/24"
    # ```
    #
    # you can supernet it with a new `/23` prefix
    #
    # ```
    # ip.supernet(23).to_string # => "172.16.10.0/23"
    # ```
    #
    # However if you supernet it with a `/22` prefix, the
    # network address will change:
    #
    # ```
    # ip.supernet(22).to_string # => "172.16.8.0/22"
    # ```
    #
    # NOTE: If *new_prefix* is less than 1, returns `0.0.0.0/0`.
    def supernet(new_prefix : Int32) : IPv4
      if new_prefix >= @prefix.to_i
        raise ArgumentError.new "New prefix must be smaller than existing prefix"
      end
      return self.class.new("0.0.0.0/0") if new_prefix < 1
      return self.class.new("#{@address}/#{new_prefix}").network
    end

    # This method implements the subnetting function
    # similar to the one described in [RFC3531](https://tools.ietf.org/html/rfc3531).
    #
    # By specifying a new prefix, the method calculates
    # the network number for the given `IPv4` object
    # and calculates the subnets associated to the new
    # prefix.
    #
    # For example, given the following network:
    #
    # ```
    # ip = IPAddress.new "172.16.10.0/24"
    # ```
    #
    # we can calculate the subnets with a `/26` prefix
    #
    # ```
    # ip.subnets(26).map &.to_string
    # # => ["172.16.10.0/26", "172.16.10.64/26",
    # # => "172.16.10.128/26", "172.16.10.192/26"]
    # ```
    #
    # The resulting number of subnets will of course always be
    # a power of two.
    def subnets(subprefix : Int32) : Array(IPv4)
      unless (@prefix.to_i..32).includes? subprefix
        raise ArgumentError.new "New prefix must be in range #{@prefix}..32, got: #{subprefix}"
      end
      Array.new(2 ** (subprefix - @prefix.to_i)) do |i|
        self.class.parse_u32 network_u32 + (i * (2 ** (32 - subprefix))), subprefix
      end
    end

    private def aggregate(ip1, ip2)
      return [ip1] if ip1.includes? ip2

      snet = ip1.supernet(ip1.prefix - 1)
      if snet.includes?(ip1, ip2) && ((ip1.size + ip2.size) == snet.size)
        [snet]
      else
        [ip1, ip2]
      end
    end

    # Returns the difference between two IP addresses
    # in unsigned int 32 bits format.
    #
    # ```
    # ip1 = IPAddress.new "172.16.10.0/24"
    # ip2 = IPAddress.new "172.16.11.0/24"
    #
    # ip1 - ip2 # => 256
    # ```
    def -(other : IPv4) : UInt32
      (to_u32.to_i - other.to_u32.to_i).abs.to_u32
    end

    # Returns a new `IPv4` object which is the result
    # of the summarization, if possible, of the two
    # objects.
    #
    # ```
    # ip1 = IPAddress.new "172.16.10.1/24"
    # ip2 = IPAddress.new "172.16.11.2/24"
    #
    # (ip1 + ip2).map &.to_string # => ["172.16.10.0/23"]
    # ```
    #
    # If the networks are not contiguous, returns
    # the two network numbers from the objects:
    #
    # ```
    # ip1 = IPAddress.new "10.0.0.1/24"
    # ip2 = IPAddress.new "10.0.2.1/24"
    #
    # (ip1 + ip2).map &.to_string # => ["10.0.0.0/24", "10.0.2.0/24"]
    # ```
    def +(other : IPv4) : Array(IPv4)
      ip1, ip2 = [self, other].sort.map &.network
      aggregate ip1, ip2
    end

    # Checks whether the ip address belongs to a
    # [RFC791](https://tools.ietf.org/html/rfc791) CLASS A network, no matter
    # what the subnet mask is.
    #
    # ```
    # ip = IPAddress.new "10.0.0.1/24"
    # ip.a? # => true
    # ```
    def a?
      CLASSFUL.key(8) === bits
    end

    # Checks whether the ip address belongs to a
    # [RFC791](https://tools.ietf.org/html/rfc791) CLASS B network, no matter
    # what the subnet mask is.
    #
    # ```
    # ip = IPAddress.new "172.16.10.1/24"
    # ip.b? # => true
    # ```
    def b?
      CLASSFUL.key(16) === bits
    end

    # Checks whether the ip address belongs to a
    # [RFC791](https://tools.ietf.org/html/rfc791) CLASS C network, no matter
    # what the subnet mask is.
    #
    # ```
    # ip = IPAddress.new "192.168.1.1/30"
    # ip.c? # => true
    # ```
    def c?
      CLASSFUL.key(24) === bits
    end

    # Returns the ip address in a format compatible
    # with the IPv6 mapped IPv4 addresses.
    #
    # ```
    # ip = IPAddress.new "172.16.10.1/24"
    # ip.to_ipv6 # => "ac10:0a01"
    # ```
    def to_ipv6 : String
      "%02x%02x:%02x%02x" % @octets
    end
  end
end
