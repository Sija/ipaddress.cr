require "../spec_helper"

describe IPAddress::IPv6::Unspecified do
  klass = IPAddress::IPv6::Unspecified
  ip = klass.new

  it "#initialize" do
    ip.should be_a(IPAddress::IPv6::Unspecified)
  end

  it "sets proper attributes" do
    ip.prefix.should eq(128)
    ip.compressed.should eq("::")
    ip.to_s.should eq("::")
    ip.to_string.should eq("::/128")
    ip.to_string_uncompressed.should eq("0000:0000:0000:0000:0000:0000:0000:0000/128")
    ip.to_u128.should eq(0)
  end

  it "#ipv6?" do
    ip.ipv6?.should be_true
  end

  it "#unspecified?" do
    ip.unspecified?.should be_true
  end
end
