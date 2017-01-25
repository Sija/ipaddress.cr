require "../spec_helper"

describe IPAddress::Prefix32 do
  prefix_hash = {
    "0.0.0.0"         => 0,
    "255.0.0.0"       => 8,
    "255.255.0.0"     => 16,
    "255.255.255.0"   => 24,
    "255.255.255.252" => 30,
  }
  octets_hash = {
    [0, 0, 0, 0]         => 0,
    [255, 0, 0, 0]       => 8,
    [255, 255, 0, 0]     => 16,
    [255, 255, 255, 0]   => 24,
    [255, 255, 255, 252] => 30,
  }
  u32_hash = {
     0 => 0,
     8 => 4278190080,
    16 => 4294901760,
    24 => 4294967040,
    30 => 4294967292,
  }
  klass = IPAddress::Prefix32

  it ".parse_netmask" do
    prefix_hash.each do |netmask, num|
      prefix = klass.parse_netmask(netmask)
      prefix.prefix.should eq(num)
      prefix.should be_a(IPAddress::Prefix32)
    end
  end

  it "#initialize" do
    expect_raises (ArgumentError) do
      klass.new 33
    end
    klass.new(8).should be_a(IPAddress::Prefix32)
  end

  it "#+" do
    p1 = klass.new 8
    p2 = klass.new 10
    (p1 + p2).should eq(18)
    (p1 + 4).should eq(12)
  end

  it "#-" do
    p1 = klass.new 8
    p2 = klass.new 24
    (p1 - p2).should eq(16)
    (p2 - p1).should eq(16)
    (p2 - 4).should eq(20)
  end

  it "#<=>" do
    p1 = klass.new 8
    p2 = klass.new 24
    (p1 == 8).should be_true
    (p1 == 24).should be_false
    (p1 > p2).should be_false
    (p1 > 24).should be_false
    (p1 < p2).should be_true
    (p1 < 24).should be_true
    (p1 <=> p1).should eq(0)
  end

  it "works with ranges" do
    range = klass.new(0)...klass.new(3)
    range.to_a.should be_a(Array(IPAddress::Prefix32))
    range.map(&.to_i).should eq([0, 1, 2])
  end

  it "#prefix" do
    prefix_hash.values.each do |num|
      prefix = klass.new(num)
      prefix.prefix.should eq(num)
    end
  end

  it "#to_ip" do
    prefix_hash.each do |netmask, num|
      prefix = klass.new(num)
      prefix.to_ip.should eq(netmask)
    end
  end

  it "#to_s" do
    prefix = klass.new(8)
    prefix.to_s.should eq("8")
  end

  it "#bits" do
    prefix = klass.new(16)
    prefix.bits.should eq("1" * 16 + "0" * 16)
  end

  it "#to_u32" do
    u32_hash.each do |num, u32|
      klass.new(num).to_u32.should eq(u32)
    end
  end

  it "#octets" do
    octets_hash.each do |arr, pref|
      prefix = klass.new(pref)
      prefix.octets.should eq(arr)
    end
  end

  it "#[]" do
    octets_hash.each do |arr, pref|
      prefix = klass.new(pref)
      arr.each_with_index do |oct, index|
        prefix[index].should eq(oct)
      end
    end
  end

  it "#hostmask" do
    prefix = klass.new(8)
    prefix.hostmask.should eq("0.255.255.255")
  end
end

describe IPAddress::Prefix128 do
  u128_hash = {
     32 => "340282366841710300949110269838224261120".to_big_i,
     64 => "340282366920938463444927863358058659840".to_big_i,
     96 => "340282366920938463463374607427473244160".to_big_i,
    126 => "340282366920938463463374607431768211452".to_big_i,
  }
  klass = IPAddress::Prefix128

  describe "#initialize" do
    it "constructs object with valid prefix" do
      klass.new(64).should be_a(IPAddress::Prefix128)
    end
    it "raises with invalid prefix" do
      expect_raises (ArgumentError) do
        klass.new 129
      end
    end
  end

  describe "#bits" do
    it "returns correct representation" do
      prefix = klass.new(64)
      prefix.bits.should eq("1" * 64 + "0" * 64)
    end
  end

  describe "#to_u32" do
    it "returns correct representation" do
      u128_hash.each do |num, u128|
        klass.new(num).to_u128.should eq(u128)
      end
    end
  end
end
