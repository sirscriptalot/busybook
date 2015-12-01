# coding: utf-8
require 'rails_helper'


def send_request(method, body, uri, **params)

  request.env['RAW_POST_DATA'] = body
  process method.downcase.to_sym, method, :uri => uri, **params
end


RSpec.describe CalendarController, type: :controller do
  include LoginHelper

  before(:each) do
    User.create(name: get_login_name)
    login
  end

  describe 'OPTIONS' do
    it "responds successfully" do
      send_request('OPTIONS', '', '/')
      expect(response).to have_http_status(200)
      expect(response.header).to include('DAV')
   end
  end

  describe 'PROPFIND /' do
    let(:body) { <<EOS
  <?xml version="1.0" encoding="UTF-8"?>
  <A:propfind xmlns:A="DAV:">
    <A:prop>
      <B:calendar-home-set xmlns:B="urn:ietf:params:xml:ns:caldav"/>
      <B:calendar-user-address-set xmlns:B="urn:ietf:params:xml:ns:caldav"/>
      <A:current-user-principal/>
      <A:displayname/>
      <C:dropbox-home-URL xmlns:C="http://calendarserver.org/ns/"/>
      <C:email-address-set xmlns:C="http://calendarserver.org/ns/"/>
      <C:notification-URL xmlns:C="http://calendarserver.org/ns/"/>
      <A:principal-collection-set/>
      <A:principal-URL/>
      <A:resource-id/>
      <B:schedule-inbox-URL xmlns:B="urn:ietf:params:xml:ns:caldav"/>
      <B:schedule-outbox-URL xmlns:B="urn:ietf:params:xml:ns:caldav"/>
      <A:supported-report-set/>
    </A:prop>
  </A:propfind>
EOS
    }


    it "responds successfully" do
      send_request('PROPFIND', body, '/')
      expect(response).to have_http_status(207)
      expect(response.body).to include("<status>HTTP/1.1 200 OK</status>")
    end
  end

  describe 'MKCALENDAR' do
    let(:body) { <<EOS
  <?xml version="1.0" encoding="UTF-8"?>
  <B:mkcalendar xmlns:B="urn:ietf:params:xml:ns:caldav">
    <A:set xmlns:A="DAV:">
      <A:prop>
        <D:calendar-color xmlns:D="http://apple.com/ns/ical/" symbolic-color="purple">
        #711A76FF
        </D:calendar-color>
        <A:displayname>My Work</A:displayname>
      </A:prop>
    </A:set>
  </B:mkcalendar>
EOS
    }

    it "creates a calendar" do
      send_request('MKCALENDAR', body, '/blah')
      expect(response).to have_http_status(:created)
  
      calendar = Calendar.where(name: 'My Work', user: User.find_by_name(get_login_name))
      expect(calendar).to exist
    end
  end


  describe 'PUT /calendar/:uri' do
    before { @cal = create(:calendar) }
    let(:body) { <<EOS
BEGIN:VCALENDAR
BEGIN:VEVENT
DTEND;TZID=Asia/Tokyo:20150919T200000
DTSTART;TZID=Asia/Tokyo:20150919T190000
UID:6016BB06-B428-47A6-80A5-A6F846D80AF1
SUMMARY:あいうえお
END:VEVENT
END:VCALENDAR
EOS
    }

    it "creates a object" do
      uri = "/#{@cal.id}/foo.ics"
      send_request('PUT', body, uri)
      expect(response).to have_http_status(:created)

      schedule = Schedule.where(uri: uri).first
      expect(schedule).not_to eq(nil)
      expect(schedule.ics).to eq(body.force_encoding("UTF-8"))
    end
  end


  describe 'GET /calendars/:uri' do
    before { @object = create(:schedule) }

    it "gets a object" do
      process :get, 'GET', :uri => @object.uri
      expect(response).to have_http_status(:ok)
      expect(response.body).to eq(@object.ics)
    end
  end


  describe 'DELETE /calendars/:uri' do
    before { @object = create(:schedule) }

    it "deletes a object" do
      process :delete, 'DELETE', :uri => @object.uri
      expect(response).to have_http_status(:no_content)
    end
  end


  describe 'REPORT /calendars/:uri' do
    before { @sched = create(:schedule) }
    let(:body) { <<EOS
<?xml version="1.0" encoding="UTF-8"?>
<B:calendar-multiget xmlns:B="urn:ietf:params:xml:ns:caldav">
  <A:prop xmlns:A="DAV:">
    <A:getetag/>
    <B:calendar-data/>
    <C:updated-by xmlns:C="http://calendarserver.org/ns/"/>
    <C:created-by xmlns:C="http://calendarserver.org/ns/"/>
  </A:prop>
  <A:href xmlns:A="DAV:">#{@sched.uri}</A:href>
</B:calendar-multiget>
EOS
    }


    it "responds successfully" do
      calendar = File.basename(@sched.uri, File.extname(@sched.uri))
      send_request('REPORT', body, "/#{calendar}")
      expect(response).to have_http_status(207)
      expect(response.body).to include("calendar-data>BEGIN:VCALENDAR")
    end
  end
end
