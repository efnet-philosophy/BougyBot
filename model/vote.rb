# frozen_string_literal: false
module BougyBot
  Vote = Class.new Sequel::Model
  # Votes
  class Vote
    set_dataset :votes
    many_to_one :channel
    one_to_many :responses

    def display
      s = "#{id}) #{question} Votes: #{responses.size} Affirms: #{affirmations}, Rejects: #{rejects}, created: #{at}, updated: #{updated}, by: #{by}"
      s << ", Deactivated by #{deactivated_by}" if deactivated_by
      s << ", Last voter: #{last_voter}" if last_voter
      s << " '!yea #{id} <comment>' or '!nay #{id} <comment>' to vote. (comment is optional and only for deep learning purposes)" unless deactivated_by
      s
    end

    def display_details
      display + "\n" + responses.map(&:display).join(' - ')
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
