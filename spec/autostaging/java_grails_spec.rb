require "harness"
require "spec_helper"
require "nokogiri"
include BVT::Spec
include BVT::Spec::AutoStagingHelper

describe BVT::Spec::AutoStaging::JavaGrails do

  before(:each) do
    @session = BVT::Harness::CFSession.new
  end

  after(:each) do
    @session.cleanup!
  end

  def add_records(app, number, path='')
    records = {}
    1.upto number do |i|
      key = "key-#{i}"
      value = "FooBar-#{i}"
      records[key] = value
      response = app.get_response(:post, path, Curl::PostField.content("name", value))
      response.response_code.should == 302
    end
    records
  end

  def verify_records(app, records, number, path='', xpath='//li/p')
    response = app.get_response(:get, path)
    response.should_not == nil
    response.response_code.should == 200
    verify_contents(records, number, response.body_str, xpath)
  end

  def verify_contents(records, count, contents, path)
    doc = Nokogiri::XML(contents)
    list = doc.xpath(path)
    list.length.should == count
    records.values.each do |record_val|
      record_present(record_val, list)
    end
  end

  def record_present record, list
    list.each do |item|
      if item.content.include? record
        return true
      end
    end
    nil
  end

  it "Start grails app and add some records", :mysql => true, :p1 => true do
    app = create_push_app("grails_app")
    service = bind_service(MYSQL_MANIFEST, app)

    records = add_records(app, 3, "/guest/save")

    verify_records(app, records, 3, "/guest/list", "//tbody/tr")

    app.delete

    app2 = create_push_app("grails_app")
    app2.bind(service)

    verify_records(app2, records, 3, "/guest/list", "//tbody/tr")
  end
end
