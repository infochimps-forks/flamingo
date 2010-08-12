require "#{File.dirname(__FILE__)}/helper"

class TestNormalOperation < Test::Unit::TestCase

  include WaderTest

  def test_receives_and_consumes_events
    expected_count = 100
    Mockingbird.setup(:port=>8080) do
      expected_count.times do
        send '{"foo":"bar"}'
      end
    end

    wader = new_wader

    event_count = 0
    Resque.after_enqueue do |type,*args|
      if type == Flamingo::DispatchEvent
        event_count += 1
        if event_count == expected_count
          # Wait a second before stopping in case we get more events from the
          # server, which would be an error
          EM.add_timer(1) { wader.stop }
        end
      else
        fail("Should only receive events, not errors")
      end
    end

    assert_nothing_raised("Run should execute without raising errors") do
      wader.run
    end

    assert_equal(expected_count,event_count,"Received an incorrect number of events")

  ensure
    Mockingbird.teardown
  end

end
