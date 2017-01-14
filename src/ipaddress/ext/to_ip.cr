class String
  # Returns `self` as an `IPAddress` object if possible, raises otherwise.
  #
  # ```
  # require "ipaddress/src/ext/to_ip"
  #
  # "127.0.0.1".to_ip.to_string  # => "127.0.0.1/32"
  # "10.0.0.256".to_ip.to_string # => raises ArgumentError
  # ```
  def to_ip : IPAddress
    IPAddress.parse self
  end

  # Returns `self` as an `IPAddress` object if possible, otherwise returns `nil`.
  # ```
  # "127.0.0.1".to_ip?.try(&.to_string)  # => "127.0.0.1/32"
  # "10.0.0.256".to_ip?.try(&.to_string) # => nil
  # ```
  def to_ip? : IPAddress?
    to_ip rescue nil
  end
end
