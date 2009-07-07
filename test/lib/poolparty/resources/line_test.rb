require "#{File.dirname(__FILE__)}/../../../test_helper"

include_fixture_resources

class LineResourceTest < Test::Unit::TestCase
  context "Base" do
    setup do
      PoolParty::Resource.define_resource_methods
      @res = PoolParty::Resources::Line.new "/etc/poolparty", :line => "hi hi"
      @base = PoolParty::DependencyResolvers::Chef
    end
    
    should "have the method denoted by has_method_name" do      
      assert_match /execute "\/usr\/sbin\/mail -s 'hi' arilerner@mac\.com"/, @res.compile(:chef)
    end
    
  end
  
end