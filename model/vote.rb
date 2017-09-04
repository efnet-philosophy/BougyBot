# frozen_string_literal: true
module BougyBot
  Vote = Class.new Sequel::Model
  # Votes
  class Vote
    set_dataset :votes
    many_to_one :channel
    one_to_many :responses

    def display
      "#{id}) #{question} Votes: #{responses.size} Affirms: #{affirmations}, Rejects: #{rejects}, created: #{at}, updated: #{updated}, by: #{by}"
    end

    def display_details
      display + "\n" + responses.map(&:display).join(', ')
    end

    def deactivate!(by)
      self.active = false
      self.deactivated_by = by
      save
      reload
    end

    private

    def affirmations
      @affirmations ||= responses.select(&:affirm).size
    end

    def rejects
      responses.size - affirmations
    end
  end
end
