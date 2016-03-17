$:.unshift(File.dirname(__FILE__))
require 'spec_helper'

describe AnemoneKai do

  it "should have a version" do
    AnemoneKai.const_defined?('VERSION').should == true
  end

  it "should return a AnemoneKai::Core from the crawl, which has a PageStore" do
    result = AnemoneKai.crawl(SPEC_DOMAIN)
    result.should be_an_instance_of(AnemoneKai::Core)
    result.pages.should be_an_instance_of(AnemoneKai::PageStore)
  end

end
