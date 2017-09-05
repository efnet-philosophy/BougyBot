# frozen_string_literal: true
module BougyBot
  Response = Class.new Sequel::Model
  # Responses, votes registered by users
  class Response
    set_dataset :responses
    many_to_one :vote
    def display
      "#{affirm ? 'Yea!' : 'Nay!'} (#{comment} - #{by}) at #{at}"
    end

    def after_create
      vote.last_voter = by
      vote.save
    end
  end
end
