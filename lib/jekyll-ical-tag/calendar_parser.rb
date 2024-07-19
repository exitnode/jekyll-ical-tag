# frozen_string_literal: true

require "active_support"
require "icalendar"
require "icalendar/recurrence"

module Jekyll
  class IcalTag
    class CalendarParser
      def initialize(raw_feed, recurring_start_date:, recurring_end_date:)
        @raw_feed = raw_feed
        @recurring_start_date = recurring_start_date
        @recurring_end_date = recurring_end_date
      end

      def events
        @events ||= parsed_events.sort_by(&:dtstart)
          .map { |event| Jekyll::IcalTag::Event.new(event) }
      end

      private

      def parsed_events
        events = Icalendar::Event.parse(@raw_feed)

        recurring_events =
          events
            .select(&:rrule)
            .flat_map do |event|
              event
                .occurrences_between(@recurring_start_date, @recurring_end_date)
                .drop(1) # drop the first occurrence, as it is already included in the events array
                .map { |occurrence| build_occurance_event(event, occurrence) }
            end

        events.concat(recurring_events)
      end

      # return a new event with the same attributes, but different start and end times
      def build_occurance_event(event, occurrence)
        event.dup.tap do |e|
          e.dtstart = occurrence.start_time
          e.dtend = occurrence.end_time
        end
      end
    end
  end
end
