require "../spec_helper"

describe IPAddress::IPv4 do
  klass = IPAddress::IPv4

  valid_ipv4 = {
    "0.0.0.0/0"              => {"0.0.0.0", 0},
    "10.0.0.0"               => {"10.0.0.0", 32},
    "10.0.0.1"               => {"10.0.0.1", 32},
    "10.0.0.1/24"            => {"10.0.0.1", 24},
    "10.0.0.1/255.255.255.0" => {"10.0.0.1", 24},
  }

  invalid_ipv4 = {
    "10.0.0.256",
    "10.0.0.0.0",
    "10.0.0",
    "10.0",
  }

  valid_ipv4_range = {
    "10.0.0.1-254",
    "10.0.1-254.0",
    "10.1-254.0.0",
  }

  netmask_values = {
    "0.0.0.0/0"        => "0.0.0.0",
    "10.0.0.0/8"       => "255.0.0.0",
    "172.16.0.0/16"    => "255.255.0.0",
    "192.168.0.0/24"   => "255.255.255.0",
    "192.168.100.4/30" => "255.255.255.252",
    "192.168.12.4/32"  => "255.255.255.255",
  }

  decimal_values = {
    "0.0.0.0/0"        => 0,
    "10.0.0.0/8"       => 167772160,
    "172.16.0.0/16"    => 2886729728,
    "192.168.0.0/24"   => 3232235520,
    "192.168.100.4/30" => 3232261124,
  }
  hex_values = {
    "10.0.0.0"      => "0a000000",
    "172.16.5.4"    => "ac100504",
    "192.168.100.4" => "c0a86404",
  }

  broadcast = {
    "10.0.0.0/8"       => "10.255.255.255/8",
    "172.16.0.0/16"    => "172.16.255.255/16",
    "192.168.0.0/24"   => "192.168.0.255/24",
    "192.168.100.4/30" => "192.168.100.7/30",
    "192.168.12.3/31"  => "255.255.255.255/31",
    "10.0.0.1/32"      => "10.0.0.1/32",
  }

  networks = {
    "10.5.4.3/8"       => "10.0.0.0/8",
    "172.16.5.4/16"    => "172.16.0.0/16",
    "192.168.4.3/24"   => "192.168.4.0/24",
    "192.168.100.5/30" => "192.168.100.4/30",
    "192.168.1.3/31"   => "192.168.1.2/31",
    "192.168.2.5/32"   => "192.168.2.5/32",
  }

  class_a = klass.new("10.0.0.1/8")
  class_b = klass.new("172.16.0.1/16")
  class_c = klass.new("192.168.0.1/24")

  classful = {
    "10.1.1.1"  => 8,
    "150.1.1.1" => 16,
    "200.1.1.1" => 24,
  }

  in_range = {
    "10.32.0.1" => {"10.32.0.253", 253},
    "192.0.0.0" => {"192.1.255.255", 131072},
  }

  it ".parse_u32" do
    decimal_values.each do |addr, int|
      ip = klass.parse_u32(int)
      ip.prefix = addr.split('/').last.to_i
      ip.to_string.should eq(addr)
    end
  end

  it ".parse_classful" do
    classful.each do |addr, prefix|
      ip = klass.parse_classful(addr)
      ip.prefix.should eq(prefix)
      ip.to_string.should eq("#{addr}/#{prefix}")
    end
    expect_raises(ArgumentError) { klass.parse_classful("192.168.256.257") }
  end

  it ".extract" do
    klass.extract("foobar172.16.10.1barbaz").to_s.should eq("172.16.10.1")
  end

  it ".summarize" do
    ip = klass.new("172.16.10.1/24")

    # Should return self if only one network given
    klass.summarize(ip).should eq([ip.network])

    # Summarize homogeneous networks
    ip1 = klass.new("172.16.10.1/24")
    ip2 = klass.new("172.16.11.2/24")
    klass.summarize(ip1, ip2).map(&.to_string).should eq(["172.16.10.0/23"])

    ip1 = klass.new("10.0.0.1/24")
    ip2 = klass.new("10.0.1.1/24")
    ip3 = klass.new("10.0.2.1/24")
    ip4 = klass.new("10.0.3.1/24")
    result = ["10.0.0.0/22"]
    klass.summarize(ip1, ip2, ip3, ip4).map(&.to_string).should eq(result)
    klass.summarize(ip4, ip3, ip2, ip1).map(&.to_string).should eq(result)

    # Summarize non homogeneous networks
    ip1 = klass.new("10.0.0.0/23")
    ip2 = klass.new("10.0.2.0/24")
    klass.summarize(ip1, ip2).map(&.to_string).should eq([
      "10.0.0.0/23", "10.0.2.0/24",
    ])

    ip1 = klass.new("10.0.0.0/16")
    ip2 = klass.new("10.0.2.0/24")
    klass.summarize(ip1, ip2).map(&.to_string).should eq([
      "10.0.0.0/16",
    ])

    ip1 = klass.new("10.0.0.0/23")
    ip2 = klass.new("10.1.0.0/24")
    klass.summarize(ip1, ip2).map(&.to_string).should eq([
      "10.0.0.0/23", "10.1.0.0/24",
    ])

    ip1 = klass.new("10.0.0.0/23")
    ip2 = klass.new("10.0.2.0/23")
    ip3 = klass.new("10.0.4.0/24")
    ip4 = klass.new("10.0.6.0/24")
    klass.summarize(ip1, ip2, ip3, ip4).map(&.to_string).should eq([
      "10.0.0.0/22", "10.0.4.0/24", "10.0.6.0/24",
    ])

    ip1 = klass.new("10.0.1.1/24")
    ip2 = klass.new("10.0.2.1/24")
    ip3 = klass.new("10.0.3.1/24")
    ip4 = klass.new("10.0.4.1/24")
    result = ["10.0.1.0/24", "10.0.2.0/23", "10.0.4.0/24"]
    klass.summarize(ip1, ip2, ip3, ip4).map(&.to_string).should eq(result)
    klass.summarize(ip4, ip3, ip2, ip1).map(&.to_string).should eq(result)

    ip1 = klass.new("10.0.1.1/24")
    ip2 = klass.new("10.10.2.1/24")
    ip3 = klass.new("172.16.0.1/24")
    ip4 = klass.new("172.16.1.1/24")
    klass.summarize(ip1, ip2, ip3, ip4).map(&.to_string).should eq([
      "10.0.1.0/24", "10.10.2.0/24", "172.16.0.0/23",
    ])

    ips = [klass.new("10.0.0.12/30"), klass.new("10.0.100.0/24")]
    result = ["10.0.0.12/30", "10.0.100.0/24"]
    klass.summarize(ips).map(&.to_string).should eq(result)

    ips = [klass.new("172.16.0.0/31"), klass.new("10.10.2.1/32")]
    result = ["10.10.2.1/32", "172.16.0.0/31"]
    klass.summarize(ips).map(&.to_string).should eq(result)

    ips = [klass.new("172.16.0.0/32"), klass.new("10.10.2.1/32")]
    result = ["10.10.2.1/32", "172.16.0.0/32"]
    klass.summarize(ips).map(&.to_string).should eq(result)
  end

  describe "#initialize" do
    it "constructs object with valid address" do
      valid_ipv4.keys.each do |addr|
        ip = klass.new(addr)
        ip.should be_a(IPAddress::IPv4)
        ip.prefix.should be_a(IPAddress::Prefix32)
      end
    end
    it "raises with invalid address" do
      invalid_ipv4.each do |addr|
        expect_raises(ArgumentError) do
          klass.new(addr)
        end
      end
      expect_raises (ArgumentError) do
        klass.new("10.0.0.0/asd")
      end
    end
    it "constructs object without prefix" do
      ip = klass.new("10.10.0.0")
      ip.prefix.should be_a(IPAddress::Prefix32)
      ip.prefix.to_i.should eq(32)
    end
  end

  it "sets proper address and prefix" do
    valid_ipv4.each do |str, (addr, prefix)|
      ip = klass.new(str)
      ip.address.should eq(addr)
      ip.prefix.to_i.should eq(prefix)
    end
  end

  it "#ipv4?" do
    ip = klass.new("172.16.10.1/24")
    ip.ipv4?.should be_true
  end

  it "#ipv6?" do
    ip = klass.new("172.16.10.1/24")
    ip.ipv6?.should be_false
  end

  it "#a?" do
    class_a.a?.should be_true
    class_b.a?.should be_false
    class_c.a?.should be_false
  end

  it "#b?" do
    class_a.b?.should be_false
    class_b.b?.should be_true
    class_c.b?.should be_false
  end

  it "#c?" do
    class_a.c?.should be_false
    class_b.c?.should be_false
    class_c.c?.should be_true
  end

  it "#reverse" do
    ip = klass.new("172.16.10.1/24")
    ip.reverse.should eq("1.10.16.172.in-addr.arpa")
  end

  it "#to_ipv6" do
    ip = klass.new("172.16.10.1/24")
    ip.to_ipv6.should eq("ac10:0a01")
  end

  it "#to_s" do
    valid_ipv4.each do |str, (addr, prefix)|
      ip = klass.new(str)
      ip.to_s.should eq(addr)
    end
  end

  it "#to_string" do
    valid_ipv4.each do |str, (addr, prefix)|
      ip = klass.new(str)
      ip.to_string.should eq("#{addr}/#{prefix}")
    end
  end

  it "#to_u32" do
    decimal_values.each do |addr, int|
      ip = klass.new(addr)
      ip.to_u32.should eq(int)
    end
  end

  it "#to_hex" do
    hex_values.each do |addr, hex|
      ip = klass.new(addr)
      ip.to_hex.should eq(hex)
    end
  end

  it "#octets" do
    ip = klass.new("10.1.2.3/8")
    ip.octets.should eq([10, 1, 2, 3])
  end

  it "#[]" do
    ip = klass.new("172.16.10.1/24")
    ip[0].should eq(172)
    ip[1].should eq(16)
    ip[2].should eq(10)
    ip[3].should eq(1)

    expect_raises(IndexError) { ip[4] }
  end

  it "#[]=" do
    ip = klass.new("10.0.1.15/32")
    ip[1] = 15
    ip.to_string.should eq("10.15.1.15/32")

    ip = klass.new("172.16.100.1")
    ip[3] = 200
    ip.to_string.should eq("172.16.100.200/32")

    ip = klass.new("192.168.199.0/24")
    ip[2] = 200
    ip.to_string.should eq("192.168.200.0/24")

    expect_raises(IndexError) { ip[4] = 100 }
  end

  it "#bits" do
    ip = klass.new("127.0.0.1")
    ip.bits.should eq("01111111000000000000000000000001")
  end

  it "#size" do
    ip = klass.new("10.0.0.1/29")
    ip.size.should eq(8)
  end

  it "#netmask" do
    netmask_values.each do |addr, mask|
      ip = klass.new(addr)
      ip.netmask.should eq(mask)
    end
  end

  it "changes prefix based on netmask" do
    ip = klass.new("10.1.1.1/16")
    ip.prefix.to_i.should eq(16)
    ip.netmask = "255.255.255.0"
    ip.prefix.to_i.should eq(24)
  end

  it "#network_u32" do
    ip = klass.new("172.16.10.1/24")
    ip.network_u32.should eq(2886732288)
  end

  it "#broadcast_u32" do
    ip = klass.new("172.16.10.1/24")
    ip.broadcast_u32.should eq(2886732543)
  end

  it "#broadcast" do
    broadcast.each do |addr, broadcast_addr|
      ip = klass.new(addr)
      ip.broadcast.should be_a(IPAddress::IPv4)
      ip.broadcast.to_string.should eq(broadcast_addr)
    end
  end

  it "#network" do
    networks.each do |addr, network_addr|
      ip = klass.new(addr)
      ip.network.should be_a(IPAddress::IPv4)
      ip.network.to_string.should eq(network_addr)
    end
  end

  describe "#network?" do
    it "returns true for regular networks" do
      network = klass.new("172.16.10.0/24")
      network.network?.should be_true
    end
    it "returns false for networks with one address" do
      network = klass.new("172.16.10.1/32")
      network.network?.should be_false
    end
    it "returns false for regular ips" do
      ip = klass.new("172.16.10.1/24")
      ip.network?.should be_false
    end
  end

  it "#first" do
    ip = klass.new("192.168.100.0/24")
    ip.network.should be_a(IPAddress::IPv4)
    ip.network.first.to_s.should eq("192.168.100.1")

    ip = klass.new("192.168.100.50/24")
    ip.network.should be_a(IPAddress::IPv4)
    ip.network.first.to_s.should eq("192.168.100.1")

    ip = klass.new("192.168.100.50/32")
    ip.network.should be_a(IPAddress::IPv4)
    ip.network.first.to_s.should eq("192.168.100.50")

    ip = klass.new("192.168.100.50/31")
    ip.network.should be_a(IPAddress::IPv4)
    ip.network.first.to_s.should eq("192.168.100.50")
  end

  it "#last" do
    ip = klass.new("192.168.100.0/24")
    ip.network.should be_a(IPAddress::IPv4)
    ip.network.last.to_s.should eq("192.168.100.254")

    ip = klass.new("192.168.100.50/24")
    ip.network.should be_a(IPAddress::IPv4)
    ip.network.last.to_s.should eq("192.168.100.254")

    ip = klass.new("192.168.100.50/32")
    ip.network.should be_a(IPAddress::IPv4)
    ip.network.last.to_s.should eq("192.168.100.50")

    ip = klass.new("192.168.100.50/31")
    ip.network.should be_a(IPAddress::IPv4)
    ip.network.last.to_s.should eq("192.168.100.51")
  end

  it "#each" do
    ip = klass.new("10.0.0.1/29")
    arr = [] of String
    ip.each { |i| arr << i.to_s }
    arr.should eq([
      "10.0.0.0", "10.0.0.1", "10.0.0.2",
      "10.0.0.3", "10.0.0.4", "10.0.0.5",
      "10.0.0.6", "10.0.0.7",
    ])
  end

  it "#each_host" do
    ip = klass.new("10.0.0.1/29")
    arr = [] of String
    ip.each_host { |i| arr << i.to_s }
    arr.should eq([
      "10.0.0.1", "10.0.0.2", "10.0.0.3",
      "10.0.0.4", "10.0.0.5", "10.0.0.6",
    ])
  end

  it "#hosts" do
    ip = klass.new("10.0.0.1/29")
    arr = ip.hosts.map &.to_s
    arr.should eq([
      "10.0.0.1", "10.0.0.2", "10.0.0.3",
      "10.0.0.4", "10.0.0.5", "10.0.0.6",
    ])
  end

  it "#includes?" do
    expected = {
      "192.168.10.100/24" => {
        "192.168.10.102/24" => true,
        "172.16.0.48"       => false,
      },
      "10.0.0.0/8" => {
        "10.0.0.0/9"    => true,
        "10.1.1.1/32"   => true,
        "10.1.1.1/9"    => true,
        "172.16.0.0/16" => false,
        "10.0.0.0/7"    => false,
        "5.5.5.5/32"    => false,
        "11.0.0.0/8"    => false,
      },
      "13.13.0.0/13" => {
        "13.16.0.0/32" => false,
      },
    }
    expected.each do |addr, matches|
      ip = klass.new(addr.to_s)
      matches.each do |match, result|
        ip.includes?(klass.new(match.to_s)).should eq(result)
      end

      truthy, falsey = matches.partition &.last.==(true)
      truthy = truthy.map { |(match, _)| klass.new(match) }
      falsey = falsey.map { |(match, _)| klass.new(match) }

      unless truthy.empty? || falsey.empty?
        ip.includes?(truthy.first, falsey.first).should be_false
      end
      ip.includes?(truthy).should be_true
      ip.includes?(falsey).should be_false
    end
  end

  it "#private?" do
    expected = {
      "192.168.10.50/24" => true,
      "192.168.10.50/16" => true,
      "172.16.77.40/24"  => true,
      "172.16.10.50/14"  => true,
      "10.10.10.10/10"   => true,
      "10.0.0.0/8"       => true,
      "192.168.10.50/12" => false,
      "3.3.3.3"          => false,
      "10.0.0.0/7"       => false,
      "172.32.0.0/12"    => false,
      "172.16.0.0/11"    => false,
      "192.0.0.2/24"     => false,
    }
    expected.each do |addr, result|
      klass.new(addr).private?.should eq(result)
    end
  end

  it "#<=>" do
    ip1 = klass.new("10.1.1.1/8")
    ip2 = klass.new("10.1.1.1/16")
    ip3 = klass.new("172.16.1.1/14")
    ip4 = klass.new("10.1.1.1/8")

    # ip2 should be greater than ip1
    (ip1 < ip2).should be_true
    (ip1 > ip2).should be_false
    # ip2 should be less than ip3
    (ip2 < ip3).should be_true
    (ip2 > ip3).should be_false
    # ip1 should be less than ip3
    (ip1 < ip3).should be_true
    (ip1 > ip3).should be_false
    (ip3 < ip1).should be_false
    # ip1 should be equal to itself
    (ip1 == ip1).should be_true
    (ip1 != ip1).should be_false
    # ip1 should be equal to ip4
    (ip1 == ip4).should be_true

    # test sorting
    [ip1, ip2, ip3].sort.map(&.to_string).should eq([
      "10.1.1.1/8", "10.1.1.1/16", "172.16.1.1/14",
    ])

    # test same prefix
    ip1 = klass.new("10.0.0.0/24")
    ip2 = klass.new("10.0.0.0/16")
    ip3 = klass.new("10.0.0.0/8")

    [ip1, ip2, ip3].sort.map(&.to_string).should eq([
      "10.0.0.0/8", "10.0.0.0/16", "10.0.0.0/24",
    ])
  end

  it "#-" do
    ip1 = klass.new("10.1.1.1/8")
    ip2 = klass.new("10.1.1.10/8")
    (ip2 - ip1).should eq(9)
    (ip1 - ip2).should eq(9)
  end

  it "#+" do
    ip1 = klass.new("172.16.10.1/24")
    ip2 = klass.new("172.16.11.2/24")
    (ip1 + ip2).map(&.to_string).should eq(["172.16.10.0/23"])

    ip2 = klass.new("172.16.12.2/24")
    (ip1 + ip2).map(&.to_string).should eq([
      ip1.network.to_string, ip2.network.to_string,
    ])

    ip1 = klass.new("10.0.0.0/23")
    ip2 = klass.new("10.0.2.0/24")
    (ip1 + ip2).map(&.to_string).should eq(["10.0.0.0/23", "10.0.2.0/24"])

    ip1 = klass.new("10.0.0.0/16")
    ip2 = klass.new("10.0.2.0/24")
    (ip1 + ip2).map(&.to_string).should eq(["10.0.0.0/16"])

    ip1 = klass.new("10.0.0.0/23")
    ip2 = klass.new("10.1.0.0/24")
    (ip1 + ip2).map(&.to_string).should eq(["10.0.0.0/23", "10.1.0.0/24"])
  end

  it "#split" do
    ip = klass.new("172.16.10.1/24")
    network = klass.new("172.16.10.0/24")

    expect_raises(ArgumentError) { ip.split(0) }
    expect_raises(ArgumentError) { ip.split(257) }

    ip.split(1).first.should eq(ip.network)

    network.split(8).map(&.to_string).should eq([
      "172.16.10.0/27", "172.16.10.32/27", "172.16.10.64/27",
      "172.16.10.96/27", "172.16.10.128/27", "172.16.10.160/27",
      "172.16.10.192/27", "172.16.10.224/27",
    ])
    network.split(7).map(&.to_string).should eq([
      "172.16.10.0/27", "172.16.10.32/27", "172.16.10.64/27",
      "172.16.10.96/27", "172.16.10.128/27", "172.16.10.160/27",
      "172.16.10.192/26",
    ])
    network.split(6).map(&.to_string).should eq([
      "172.16.10.0/27", "172.16.10.32/27", "172.16.10.64/27",
      "172.16.10.96/27", "172.16.10.128/26", "172.16.10.192/26",
    ])
    network.split(5).map(&.to_string).should eq([
      "172.16.10.0/27", "172.16.10.32/27", "172.16.10.64/27",
      "172.16.10.96/27", "172.16.10.128/25",
    ])
    network.split(4).map(&.to_string).should eq([
      "172.16.10.0/26", "172.16.10.64/26", "172.16.10.128/26",
      "172.16.10.192/26",
    ])
    network.split(3).map(&.to_string).should eq([
      "172.16.10.0/26", "172.16.10.64/26", "172.16.10.128/25",
    ])
    network.split(2).map(&.to_string).should eq([
      "172.16.10.0/25", "172.16.10.128/25",
    ])
    network.split(1).map(&.to_string).should eq([
      "172.16.10.0/24",
    ])
  end

  it "#split with proper length" do
    classful.each do |addr, prefix|
      ip = klass.new("#{addr}/#{prefix}")
      ip.split(1).size.should eq(1)
      ip.split(2).size.should eq(2)
      ip.split(32).size.should eq(32)
      ip.split(256).size.should eq(256)
    end
  end

  it "#subnets" do
    network = klass.new("172.16.10.0/24")

    expect_raises(ArgumentError) { network.subnets(23) }
    expect_raises(ArgumentError) { network.subnets(33) }

    network.subnets(26).map(&.to_string).should eq([
      "172.16.10.0/26", "172.16.10.64/26", "172.16.10.128/26",
      "172.16.10.192/26",
    ])
    network.subnets(25).map(&.to_string).should eq([
      "172.16.10.0/25", "172.16.10.128/25",
    ])
    network.subnets(24).map(&.to_string).should eq([
      "172.16.10.0/24",
    ])
  end

  it "#supernet" do
    ip = klass.new("172.16.10.1/24")

    expect_raises(ArgumentError) { ip.supernet(24) }

    ip.supernet(0).to_string.should eq("0.0.0.0/0")
    ip.supernet(-2).to_string.should eq("0.0.0.0/0")
    ip.supernet(23).to_string.should eq("172.16.10.0/23")
    ip.supernet(22).to_string.should eq("172.16.8.0/22")
  end

  it "#to" do
    in_range.each do |addr, (range_to, range_size)|
      ip = klass.new(addr)
      ip.to(range_to).size.should eq(range_size)
    end
  end
end
