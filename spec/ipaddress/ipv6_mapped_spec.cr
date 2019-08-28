require "../spec_helper"

describe IPAddress::IPv6::Mapped do
  valid_mapped = {
    "::13.1.68.3"                  => 281470899930115,
    "0:0:0:0:0:ffff:129.144.52.38" => 281472855454758,
    "::ffff:129.144.52.38"         => 281472855454758,
  }
  valid_mapped_ipv6 = {
    "::0d01:4403"              => 281470899930115,
    "0:0:0:0:0:ffff:8190:3426" => 281472855454758,
    "::ffff:8190:3426"         => 281472855454758,
  }
  valid_mapped_ipv6_conversion = {
    "::0d01:4403"              => "13.1.68.3",
    "0:0:0:0:0:ffff:8190:3426" => "129.144.52.38",
    "::ffff:8190:3426"         => "129.144.52.38",
  }
  klass = IPAddress::IPv6::Mapped
  ip = klass.new("::172.16.10.1")

  it "#initialize" do
    ip.should be_a(IPAddress::IPv6::Mapped)
  end

  it "sets proper attributes" do
    ip.prefix.should eq(128)
    ip.compressed.should eq("::ffff:ac10:a01")
    ip.to_s.should eq("::ffff:172.16.10.1")
    ip.to_string.should eq("::ffff:172.16.10.1/128")
    ip.to_string_uncompressed.should eq("0000:0000:0000:0000:0000:ffff:ac10:0a01/128")
    ip.to_big_i.should eq("281473568475649".to_big_i)
  end

  it "#ipv6?" do
    ip.ipv6?.should be_true
  end

  it "#mapped?" do
    ip.mapped?.should be_true
  end

  it "#to_big_i" do
    valid_mapped.merge(valid_mapped_ipv6).each do |addr, u128|
      klass.new(addr).to_big_i.should eq(u128)
    end
  end

  it "#ipv4" do
    valid_mapped_ipv6_conversion.each do |ip6, ip4|
      klass.new(ip6).ipv4.to_s.should eq(ip4)
    end
  end
end
