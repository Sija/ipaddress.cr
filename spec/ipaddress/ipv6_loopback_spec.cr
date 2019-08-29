require "../spec_helper"

describe IPAddress::IPv6::Loopback do
  klass = IPAddress::IPv6::Loopback
  ip = klass.new

  it "#initialize" do
    ip.should be_a(IPAddress::IPv6::Loopback)
  end

  it "sets proper attributes" do
    ip.prefix.should eq(128)
    ip.compressed.should eq("::1")
    ip.to_s.should eq("::1")
    ip.to_string.should eq("::1/128")
    ip.to_string_uncompressed.should eq("0000:0000:0000:0000:0000:0000:0000:0001/128")
    ip.to_big_i.should eq(1)
  end

  it "#ipv6?" do
    ip.ipv6?.should be_true
  end

  it "#loopback?" do
    ip.loopback?.should be_true
  end
end
