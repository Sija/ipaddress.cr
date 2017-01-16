require "../spec_helper"

describe IPAddress::IPv6 do
  klass = IPAddress::IPv6

  compress_addr = {
    "2001:db8:0000:0000:0008:0800:200c:417a" => "2001:db8::8:800:200c:417a",
    "2001:db8:0:0:8:800:200c:417a"           => "2001:db8::8:800:200c:417a",
    "ff01:0:0:0:0:0:0:101"                   => "ff01::101",
    "0:0:0:0:0:0:0:1"                        => "::1",
    "0:0:0:0:0:0:0:0"                        => "::",
  }

  # Kindly taken from the python IPy library
  valid_ipv6 = {
    "FEDC:BA98:7654:3210:FEDC:BA98:7654:3210" => "338770000845734292534325025077361652240".to_big_i,
    "1080:0000:0000:0000:0008:0800:200C:417A" => "21932261930451111902915077091070067066".to_big_i,
    "1080:0:0:0:8:800:200C:417A"              => "21932261930451111902915077091070067066".to_big_i,
    "1080:0::8:800:200C:417A"                 => "21932261930451111902915077091070067066".to_big_i,
    "1080::8:800:200C:417A"                   => "21932261930451111902915077091070067066".to_big_i,
    "FF01:0:0:0:0:0:0:43"                     => "338958331222012082418099330867817087043".to_big_i,
    "FF01:0:0::0:0:43"                        => "338958331222012082418099330867817087043".to_big_i,
    "FF01::43"                                => "338958331222012082418099330867817087043".to_big_i,
    "0:0:0:0:0:0:0:1"                         => 1.to_big_i,
    "0:0:0::0:0:1"                            => 1.to_big_i,
    "::1"                                     => 1.to_big_i,
    "0:0:0:0:0:0:0:0"                         => 0.to_big_i,
    "0:0:0::0:0:0"                            => 0.to_big_i,
    "::"                                      => 0.to_big_i,
    "1080:0:0:0:8:800:200C:417A"              => "21932261930451111902915077091070067066".to_big_i,
    "1080::8:800:200C:417A"                   => "21932261930451111902915077091070067066".to_big_i,
  }

  invalid_ipv6 = {
    ":1:2:3:4:5:6:7",
    ":1:2:3:4:5:6:7",
    "2002:516:2:200",
    "dd",
  }

  networks = {
    "2001:db8:1:1:1:1:1:1/32" => "2001:db8::/32",
    "2001:db8:1:1:1:1:1::/32" => "2001:db8::/32",
    "2001:db8::1/64"          => "2001:db8::/64",
  }

  it ".parse_u128" do
    valid_ipv6.each do |addr, int|
      ip = klass.parse_u128(int)
      ip.to_s.should eq(klass.parse_u128(int).to_s)
    end
    ip = klass.parse_u128(-1.to_big_i)
    ip.to_string.should eq("ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff/128")
  end

  it ".parse_hex" do
    ip = klass.new "2001:db8::8:800:200c:417a/64"
    klass.parse_hex("20010db80000000000080800200c417a", 64).to_s.should eq(ip.to_s)
  end

  it ".expand" do
    expanded = "2001:0db8:0000:cd30:0000:0000:0000:0000"
    klass.expand("2001:db8:0:cd30::").should eq(expanded)
    klass.expand("2001:0db8:0::cd3").should_not eq(expanded)
    klass.expand("2001:0db8::cd30").should_not eq(expanded)
    klass.expand("2001:0db8::cd3").should_not eq(expanded)
  end

  it ".compress" do
    compressed = "2001:db8:0:cd30::"
    klass.compress("2001:0db8:0000:cd30:0000:0000:0000:0000").should eq(compressed)
    klass.compress("2001:0db8:0::cd3").should_not eq(compressed)
    klass.compress("2001:0db8::cd30").should_not eq(compressed)
    klass.compress("2001:0db8::cd3").should_not eq(compressed)
  end

  describe "#initialize" do
    it "constructs object with valid address" do
      valid_ipv6.keys.each do |addr|
        ip = klass.new(addr)
        ip.should be_a(IPAddress::IPv6)
        ip.prefix.should be_a(IPAddress::Prefix128)
      end
    end
    it "raises with invalid address" do
      invalid_ipv6.each do |addr|
        expect_raises(ArgumentError) do
          klass.new(addr)
        end
      end
      expect_raises (ArgumentError) do
        klass.new("::10.1.1.1")
      end
    end
    it "constructs object without prefix" do
      ip = klass.new("::")
      ip.prefix.should be_a(IPAddress::Prefix128)
      ip.prefix.to_i.should eq(128)
    end
  end

  it "#ipv4?" do
    ip = klass.new "2001:db8::8:800:200c:417a/64"
    ip.ipv4?.should be_false
  end

  it "#ipv6?" do
    ip = klass.new "2001:db8::8:800:200c:417a/64"
    ip.ipv6?.should be_true
  end

  it "#address" do
    ip = klass.new "2001:db8::8:800:200c:417a/64"
    ip.address.should eq("2001:0db8:0000:0000:0008:0800:200c:417a")
  end

  it "#groups" do
    ip = klass.new "2001:db8::8:800:200c:417a/64"
    ip.groups.should eq([8193, 3512, 0, 0, 8, 2048, 8204, 16762])
  end

  it "#[]" do
    ip = klass.new "2001:db8::8:800:200c:417a/64"
    groups = [8193, 3512, 0, 0, 8, 2048, 8204, 16762]
    groups.each_with_index do |val, index|
      ip[index].should eq(val)
    end
    expect_raises(IndexError) { ip[8] }
  end

  it "#[]=" do
    ip = klass.new "2001:db8::8:800:200c:417a/64"
    ip[2] = 1234
    ip.to_string.should eq("2001:db8:4d2:0:8:800:200c:417a/64")

    expect_raises(IndexError) { ip[8] = 100 }
  end

  it "#hexs" do
    ip = klass.new "2001:db8::8:800:200c:417a/64"
    ip.hexs.should eq("2001:0db8:0000:0000:0008:0800:200c:417a".split(':'))
  end

  it "#bits" do
    ip = klass.new "2001:db8::8:800:200c:417a/64"
    bits = "0010000000000001000011011011100000000000000000000000" +
           "0000000000000000000000001000000010000000000000100000" +
           "000011000100000101111010"
    ip.bits.should eq(bits)
  end

  it "#to_hex" do
    ip = klass.new "2001:db8::8:800:200c:417a/64"
    ip.to_hex.should eq("20010db80000000000080800200c417a")
  end

  it "#to_s" do
    ip = klass.new "2001:db8::8:800:200c:417a/64"
    ip.to_s.should eq("2001:db8::8:800:200c:417a")
  end

  it "#to_string" do
    ip = klass.new "2001:db8::8:800:200c:417a/64"
    ip.to_string.should eq("2001:db8::8:800:200c:417a/64")
  end

  it "#to_string_uncompressed" do
    ip = klass.new "2001:db8::8:800:200c:417a/64"
    ip.to_string_uncompressed.should eq("2001:0db8:0000:0000:0008:0800:200c:417a/64")
  end

  it "#to_u128" do
    valid_ipv6.each do |ip, int|
      klass.new(ip).to_u128.should eq(int)
    end
  end

  it "#prefix" do
    ip = klass.new "2001:db8::8:800:200c:417a"
    ip.prefix.should eq(128)

    ip.prefix = 64
    ip.prefix.should eq(64)
    ip.to_string.should eq("2001:db8::8:800:200c:417a/64")
  end

  it "#literal" do
    ip = klass.new "2001:db8::8:800:200c:417a/64"
    ip.literal.should eq("2001-0db8-0000-0000-0008-0800-200c-417a.ipv6-literal.net")
  end

  it "#reverse" do
    ip = klass.new "3ffe:505:2::f"
    ip.reverse.should eq("f.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.2.0.0.0.5.0.5.0.e.f.f.3.ip6.arpa")
  end

  it "#compressed" do
    compress_addr.each do |addr, compressed|
      ip = klass.new addr
      ip.compressed.should eq(compressed)
    end
  end

  it "#unspecified?" do
    ip = klass.new "2001:db8::8:800:200c:417a/64"
    ip.unspecified?.should be_false

    ip = klass.new "::"
    ip.unspecified?.should be_true
  end

  it "#loopback?" do
    ip = klass.new "2001:db8::8:800:200c:417a/64"
    ip.loopback?.should be_false

    ip = klass.new "::1"
    ip.loopback?.should be_true
  end

  it "#mapped?" do
    ip = klass.new "2001:db8::8:800:200c:417a/64"
    ip.mapped?.should be_false

    ip = klass.new "::ffff:1234:5678"
    ip.mapped?.should be_true
  end

  it "#link_local?" do
    expected = {
      "fe80::"                    => true,
      "fe80::1"                   => true,
      "fe80::208:74ff:feda:625c"  => true,
      "fe80::/64"                 => true,
      "fe80::/65"                 => true,
      "::"                        => false,
      "::1"                       => false,
      "ff80:03:02:01::"           => false,
      "2001:db8::8:800:200c:417a" => false,
      "fe80::/63"                 => false,
    }
    expected.each do |addr, result|
      klass.new(addr).link_local?.should eq(result)
    end
  end

  it "#unique_local?" do
    expected = {
      "fc00::/7"              => true,
      "fc00::/8"              => true,
      "fd00::/8"              => true,
      "fd12:3456:789a:1::1"   => true,
      "fd12:3456:789a:1::/64" => true,
      "fc00::1"               => true,
      "fc00::/6"              => false,
      "::"                    => false,
      "::1"                   => false,
      "fe80::"                => false,
      "fe80::1"               => false,
      "fe80::/64"             => false,
    }
    expected.each do |addr, result|
      klass.new(addr).unique_local?.should eq(result)
    end
  end

  it "#network" do
    networks.each do |addr, network|
      ip = klass.new addr
      ip.network.should be_a(IPAddress::IPv6)
      ip.network.to_string.should eq(network)
    end
  end

  describe "#network?" do
    it "returns true for regular networks" do
      network = klass.new "2001:db8:8:800::/64"
      network.network?.should be_true
    end
    it "returns false for regular ips" do
      ip = klass.new "2001:db8::8:800:200c:417a/64"
      ip.network?.should be_false
    end
  end

  it "#network_u128" do
    ip = klass.new "2001:db8::8:800:200c:417a/64"
    ip.network_u128.should eq("42540766411282592856903984951653826560".to_big_i)
  end

  it "#broadcast_u128" do
    ip = klass.new "2001:db8::8:800:200c:417a/64"
    ip.broadcast_u128.should eq("42540766411282592875350729025363378175".to_big_i)
  end

  it "#size" do
    ip = klass.new("2001:db8::8:800:200c:417a/64")
    ip.size.should eq(2.to_big_i ** 64)
    ip = klass.new("2001:db8::8:800:200c:417a/32")
    ip.size.should eq(2.to_big_i ** 96)
    ip = klass.new("2001:db8::8:800:200c:417a/120")
    ip.size.should eq(2.to_big_i ** 8)
    ip = klass.new("2001:db8::8:800:200c:417a/124")
    ip.size.should eq(2.to_big_i ** 4)
  end

  it "#includes?" do
    expected = {
      "2001:db8::8:800:200c:417a/64" => {
        "2001:db8::8:800:200c:417a/128"  => true,
        "2001:db8::8:800:200c:417a/46"   => false,
        "2001:db8::8:800:200c:0/64"      => true,
        "2001:db8:1::8:800:200c:417a/64" => false,
        "2001:db8::8:800:200c:1/128"     => true,
        "2001:db8:1::8:800:200c:417a/76" => false,
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

  it "#each" do
    ip = klass.new("2001:db8::4/125")
    arr = [] of String
    ip.each { |i| arr << i.compressed }
    arr.should eq([
      "2001:db8::", "2001:db8::1", "2001:db8::2",
      "2001:db8::3", "2001:db8::4", "2001:db8::5",
      "2001:db8::6", "2001:db8::7",
    ])
  end

  it "#<=>" do
    ip1 = klass.new("2001:db8:1::1/64")
    ip2 = klass.new("2001:db8:2::1/64")
    ip3 = klass.new("2001:db8:1::2/64")
    ip4 = klass.new("2001:db8:1::1/65")

    # ip2 should be greater than ip1
    (ip1 < ip2).should be_true
    (ip1 > ip2).should be_false
    # ip3 should be less than ip2
    (ip2 > ip3).should be_true
    (ip2 < ip3).should be_false
    # ip1 should be less than ip3
    (ip1 < ip3).should be_true
    (ip1 > ip3).should be_false
    (ip3 < ip1).should be_false
    # ip1 should be equal to itself
    (ip1 == ip1).should be_true
    (ip1 != ip1).should be_false
    # ip4 should be greater than ip1
    (ip1 < ip4).should be_true
    (ip1 > ip4).should be_false

    # test sorting
    [ip1, ip2, ip3, ip4].sort.map(&.to_string).should eq([
      "2001:db8:1::1/64", "2001:db8:1::1/65",
      "2001:db8:1::2/64", "2001:db8:2::1/64",
    ])
  end
end
