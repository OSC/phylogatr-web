require 'base64'

class Serialize
  def self.to_str(obj)
    Base64.encode64(Marshal.dump(obj))
  end

  def self.from_str(str)
    Marshal.load(Base64.decode64(str))
  end
end
