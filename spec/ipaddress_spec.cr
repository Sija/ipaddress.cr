require "./spec_helper"

describe IPAddress do
  describe ".ntoa" do
    describe "with int" do
      it "accepts valid addresses" do
        IPAddress.ntoa(167837953).should eq("10.1.1.1")
        IPAddress.ntoa(0).should eq("0.0.0.0")
      end

      it "raises on invalid addresses" do
        expect_raises(ArgumentError) { IPAddress.ntoa -1 }
      end
    end
    describe "with uint32" do
      it "accepts valid addresses" do
        IPAddress.ntoa(167837953_u32).should eq("10.1.1.1")
        IPAddress.ntoa(0_u32).should eq("0.0.0.0")
      end
    end
  end

  describe ".aton" do
    it "accepts valid addresses" do
      IPAddress.aton("10.1.1.1").should eq(167837953_u32)
      IPAddress.aton("0.0.0.0").should eq(0_u32)
    end

    it "raises on invalid addresses" do
      expect_raises(ArgumentError) { IPAddress.aton "-10.10.100.001" }
      expect_raises(ArgumentError) { IPAddress.aton "a.b.c.d" }
    end
  end

  describe ".parse" do
    describe "with ipv4" do
      it "accepts valid addresses" do
        IPAddress.parse("172.16.10.1/24").should be_a(IPAddress::IPv4)
        IPAddress.parse("10.0.0.1").should be_a(IPAddress::IPv4)
      end

      it "accepts valid uint32 addresses" do
        IPAddress.parse(4294967295).should be_a(IPAddress::IPv4)
        IPAddress.parse(167772160).should be_a(IPAddress::IPv4)
        IPAddress.parse(3232235520).should be_a(IPAddress::IPv4)
        IPAddress.parse(0).should be_a(IPAddress::IPv4)
      end

      it "raises on invalid addresses" do
        expect_raises(ArgumentError) { IPAddress.parse "10.0.0.256" }
        expect_raises(ArgumentError) { IPAddress.parse "10.0.0.0.0" }
        expect_raises(ArgumentError) { IPAddress.parse "10.0.0" }
        expect_raises(ArgumentError) { IPAddress.parse "10.0" }
      end

      it "raises on invalid uint32 addresses" do
        expect_raises(ArgumentError) { IPAddress.parse 4294967296 }   # 256.0.0.0
        expect_raises(ArgumentError) { IPAddress.parse "A294967295" } # NaN
        expect_raises(ArgumentError) { IPAddress.parse -1 }
      end
    end

    describe "with ipv6" do
      it "accepts valid addresses" do
        IPAddress.parse("2001:db8::8:800:200c:417a/64").should be_a(IPAddress::IPv6)
        IPAddress.parse("dead:beef:cafe:babe::f0ad").should be_a(IPAddress::IPv6)
      end

      it "accepts valid mapped addresses" do
        IPAddress.parse("::13.1.68.3").should be_a(IPAddress::IPv6::Mapped)
      end

      it "raises on invalid addresses" do
        expect_raises(ArgumentError) { IPAddress.parse ":1:2:3:4:5:6:7" }
        expect_raises(ArgumentError) { IPAddress.parse "2002:::1" }
        expect_raises(ArgumentError) { IPAddress.parse "2002:516:2:200" }
      end

      it "raises on invalid mapped addresses" do
        expect_raises(ArgumentError) { IPAddress.parse "::1:2.3.4" }
      end
    end
  end

  describe ".valid?" do
    describe "with ipv4" do
      it "accepts valid addresses" do
        IPAddress.valid?("0.0.0.0").should be_true
        IPAddress.valid?("10.0.0.1").should be_true
        IPAddress.valid?("10.0.0.0").should be_true
      end

      it "rejects invalid addresses" do
        IPAddress.valid?("10.0.0.256").should be_false
        IPAddress.valid?("10.0.0.0.0").should be_false
        IPAddress.valid?("10.0.0").should be_false
        IPAddress.valid?("10.0").should be_false
      end
    end

    describe "with ipv6" do
      it "accepts valid addresses" do
        IPAddress.valid?("2002::1").should be_true
        IPAddress.valid?("dead:beef:cafe:babe::f0ad").should be_true
      end

      it "rejects invalid addresses" do
        IPAddress.valid?("2002:::1").should be_false
        IPAddress.valid?("2002:516:2:200").should be_false
      end
    end
  end

  describe ".valid_ipv4_netmask?" do
    it "accepts valid netmasks" do
      IPAddress.valid_ipv4_netmask?("255.255.255.0").should be_true
      IPAddress.valid_ipv4_netmask?("255.255.255.128").should be_true
      IPAddress.valid_ipv4_netmask?("255.0.0.0").should be_true
      IPAddress.valid_ipv4_netmask?("0.0.0.0").should be_true
    end

    it "rejects invalid netmasks" do
      IPAddress.valid_ipv4_netmask?("255.255.255.1").should be_false
      IPAddress.valid_ipv4_netmask?("255.255.255.10").should be_false
      IPAddress.valid_ipv4_netmask?("255.0.0.1").should be_false
      IPAddress.valid_ipv4_netmask?("0.0.0.1").should be_false
    end
  end
end
