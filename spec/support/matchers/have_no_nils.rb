RSpec::Matchers.define :have_no_nils do
  match do |actual|
    begin
      check_no_nils(actual, "")
      true
    rescue ArgumentError => e
      @failure_msg = e.message
      false
    end
  end

  failure_message_for_should { |actual| @failure_msg }

  def check_no_nils(obj, path)
    if obj.is_a?(Array)
      obj.each_with_index { |o, i| check_no_nils(o, "#{path}.[#{i}]") }
    elsif obj.is_a?(Hash)
      obj.each { |k, v| check_no_nils(v, "#{path}.#{k}") }
    else
      raise ArgumentError, "Object at #{path} is nil" unless obj
    end
  end
end
