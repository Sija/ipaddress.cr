require "../../../src/ipaddress/ext/to_ip"
require "../../spec_helper"

describe IPAddress do
  describe "String#to_ip" do
    it "converts valid IP" do
      ip4 = "172.16.10.1/24"
      ip4.to_ip.should be_a(IPAddress::IPv4)
      ip4.to_ip.to_string.should eq(ip4)

      ip6 = "2001:db8::8:800:200c:417a/64"
      ip6.to_ip.should be_a(IPAddress::IPv6)
      ip6.to_ip.to_string.should eq(ip6)
    end

    it "raises on invalid IP" do
      expect_raises(ArgumentError) { "10.0.0.256".to_ip }
      expect_raises(ArgumentError) { ":1:2:3:4:5:6:7".to_ip }
      expect_raises(ArgumentError) { "foobar?".to_ip }
    end
  end

  describe "String#to_ip?" do
    it "converts valid IP" do
      ip4 = "172.16.10.1/24"
      ip4.to_ip?.should_not be_nil

      ip6 = "2001:db8::8:800:200c:417a/64"
      ip6.to_ip?.should_not be_nil
    end

    it "returns nil on invalid IP" do
      "10.0.0.256".to_ip?.should be_nil
      ":1:2:3:4:5:6:7".to_ip?.should be_nil
      "foobar?".to_ip?.should be_nil
    end
  end
end
