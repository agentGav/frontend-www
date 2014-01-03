require 'test_helper'

class RootControllerTest < ActionController::TestCase
  
  test "should get index" do
    get :index
    assert_response :ok
  end
  
  test "course instances should load correctly" do
    stub_request(:get, "http://contentapi.dev/course-instance.json?course=open-data-marketers&date=2014-01-22").
      to_return(:status => 200, :body => load_fixture('open-data-marketers-2014-01-22.json'), :headers => {})
    stub_request(:get, "http://contentapi.dev/open-data-marketers.json").
        to_return(:status => 200, :body => load_fixture('open-data-marketers.json'), :headers => {})
    stub_request(:get, "http://contentapi.dev/kathryn-corrick.json").
      to_return(:status => 200, :body => load_fixture('kathryn-corrick.json'), :headers => {})
    get :course_instance, :slug => 'open-data-marketers', :date => '2014-01-22'
    assert_response :ok
  end

  test "course instances should 404 if date is incorrect" do
    get :course_instance, :slug => 'course-name', :date => 'spang'
    assert_response :not_found
  end
  
  test "course instances without trainers should render OK" do
    stub_request(:get, "http://contentapi.dev/course-instance.json?course=open-data-practice&date=2013-04-08").
      to_return(:status => 200, :body => load_fixture('open-data-practice-2013-04-08.json'), :headers => {})
    stub_request(:get, "http://contentapi.dev/open-data-practice.json").
        to_return(:status => 200, :body => load_fixture('open-data-practice.json'), :headers => {})
    get :course_instance, :slug => 'open-data-practice', :date => '2013-04-08'
    assert_response :ok
  end

  test "past events should return correct title" do
    stub_request(:get, "http://contentapi.dev/friday-lunchtime-lecture-how-politicians-lie-with-data.json").
      to_return(:status => 200, :body => load_fixture('friday-lunchtime-lecture-how-politicians-lie-with-data.json'), :headers => {})
    get :events_article, :slug => 'friday-lunchtime-lecture-how-politicians-lie-with-data',
        :section=>"events", :event_type=>:lunchtime_lectures
  
    assert_match /<h1> <a href="\/events">Previous Events<\/a> <\/h1>/, response.body.squish
  end
  
  test "past events should return not show the booking link" do
    stub_request(:get, "http://contentapi.dev/friday-lunchtime-lecture-how-politicians-lie-with-data.json").
      to_return(:status => 200, :body => load_fixture('friday-lunchtime-lecture-how-politicians-lie-with-data.json'), :headers => {})
    get :events_article, :slug => 'friday-lunchtime-lecture-how-politicians-lie-with-data',
        :section=>"events", :event_type=>:lunchtime_lectures
  
    assert_not_match /More information and to book your place/, response.body.squish
  end
  
  test "Handles nil code response from content API with a proper 500 page" do
    GdsApi::HTTPErrorResponse.any_instance.expects(:code).at_least_once.returns(nil)
    GdsApi::ContentApi.any_instance.expects(:artefact).raises(GdsApi::HTTPErrorResponse, '')
    get :page, :slug => 'broken'
    assert_response 500
  end
  
  test "upcoming lectures should show the livestream iframe if livestream is set to true" do
    Timecop.freeze(Time.parse("2013-11-14T13:00:00+00:00"))
    stub_request(:get, "http://contentapi.dev/friday-lunchtime-lecture-how-politicians-lie-with-data.json").
      to_return(:status => 200, :body => load_fixture('lecture-with-livestream.json'), :headers => {})
    get :events_article, :slug => 'friday-lunchtime-lecture-how-politicians-lie-with-data',
        :section=>"events", :event_type => :lunchtime_lectures
        
    assert_match /Live stream/, response.body
    Timecop.return
  end
  
  test "upcoming lectures should not show the livestream iframe if livestream is set to false" do
    Timecop.freeze(Time.parse("2013-11-14T13:00:00+00:00"))
    stub_request(:get, "http://contentapi.dev/friday-lunchtime-lecture-how-politicians-lie-with-data.json").
      to_return(:status => 200, :body => load_fixture('lecture-no-livestream.json'), :headers => {})
    get :events_article, :slug => 'friday-lunchtime-lecture-how-politicians-lie-with-data',
        :section=>"events", :event_type => :lunchtime_lectures
        
    assert_not_match /Live stream/, response.body
    Timecop.return
  end
  
  test "Atom feeds should return full text feed" do
    stub_request(:get, "http://contentapi.dev/with_tag.json?include_children=1&tag=news&whole_body=true").
      to_return(:status => 200, :body => load_fixture('full-text-news.json'), :headers => {})      
    stub_request(:get, "http://contentapi.dev/with_tag.json?include_children=1&tag=blog&whole_body=true").
      to_return(:status => 200, :body => '{"total":47,"start_index":1,"page_size":47,"current_page":1,"pages":1,"_response_info":{"status":"ok","links":[]},"description":"","results": []}', :headers => {})
    
    
    get :news_list, :format => 'atom', :section=>"news"
    
    xml = Nokogiri::XML(response.body)
    assert_equal "<p>Ahead of <a rel=\"external\" href=\"http://summit.theodi.org/\">our Summit</a> in London on 29 October, we're delighted to be announcing two new members; London-based <a rel=\"external\" href=\"http://www.ratesetter.com\">RateSetter</a>, and Seattle's <a rel=\"external\" href=\"http://www.socrata.com\">Socrata</a>. They take our membership to 45, and are testimony to the international appeal and multi-sector influence that we are forging.</p>", xml.xpath("//xmlns:entry/xmlns:content").text
  end

end
  