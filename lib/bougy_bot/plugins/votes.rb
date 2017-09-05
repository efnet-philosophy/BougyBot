# -*- coding: utf-8 -*-
# frozen_string_literal: true
require 'cinch'
require_relative '../../bougy_bot'
require 'cinch/cooldown'

module BougyBot
  M 'vote'
  M 'channel'
  M 'response'
  module Plugins
    # Cinch Plugin to send notes
    class Votes
      include Cinch::Plugin
      include Cinch::Extensions::Authentication
      enforce_cooldown

      match(/^!vote create (.+)/, method: :new_vote, use_prefix: false)
      match(/^!vote end (\d+)$/, method: :end_vote, use_prefix: false)
      match(/^\?votes$/, method: :display_votes, use_prefix: false)
      match(/^\?vote (\d+)$/, method: :display_vote, use_prefix: false)
      match(/^\?vote -d (\d+)$/, method: :vote_tally, use_prefix: false)
      match(/^!yea (\d+)$/, method: :yea, use_prefix: false)
      match(/^!nay (\d+)$/, method: :nay, use_prefix: false)
      match(/^!yea (\d+) (.+)$/, method: :yea, use_prefix: false)
      match(/^!nay (\d+) (.+)$/, method: :nay, use_prefix: false)
      match(/^!yay (\d+)$/, method: :idjit, use_prefix: false)
      match(/^!yay (\d+) (.*)$/, method: :idjit, use_prefix: false)

      def yea(m, id, comment = 'No Comment')
        vote(m, id, true, comment)
      end

      def nay(m, id, comment = 'No Comment')
        vote(m, id, false, comment)
      end

      def idjit(m, _id, _comment = nil)
        reply_with_nick m, "You're the kind of idjit that spells 'yea' wrong. Own it."
      end

      def end_vote(m, id)
        return m.reply 'You must be authenticated to deactivate a vote' unless authenticated? m
        channel = Channel.find_or_create(name: m.channel.name)
        if vote = Vote.find(active: true, channel_id: channel.id, id: id)
          vote.deactivate! m.user.nick
          reply_with_nick(m, "Vote #{vote.id} ended:")
          reply_with_nick(m, vote.display)
        else
          reply_with_nick(m, "No active vote found with id #{id} for #{channel.name}")
        end
      rescue => e
        rescue_me m, e, 'Error ending vote'
      end

      def new_vote(m, message)
        return m.reply 'You must be authenticated to create a vote' unless authenticated? m
        channel = Channel.find_or_create(name: m.channel.name)
        if vote = Vote.create(active: true, by: m.user.nick, channel_id: channel.id, question: message)
          m.reply "Vote #{vote.id} created: #{vote.question}"
        else
          m.reply 'Problem saving vote'
        end
      rescue => e
        rescue_me m, e, 'Error creating vote'
      end

      def vote_tally(m, id)
        channel = Channel.find_or_create(name: m.channel.name)
        vote = Vote.find(channel_id: channel.id, id: id)
        return m.reply "No vote found with id #{id} for #{channel.name}" unless vote
        reply_with_nick m, vote.display_details
      rescue => e
        rescue_me m, e, "Error displaying vote: #{e}"
      end

      def display_vote(m, id)
        channel = Channel.find_or_create(name: m.channel.name)
        vote = Vote.find(channel_id: channel.id, id: id)
        return m.reply "No vote found with id #{id} for #{channel.name}" unless vote
        reply_with_nick m, vote.display
      rescue => e
        rescue_me m, e, "Error displaying vote: #{e}"
      end

      def display_votes(m)
        channel = Channel.find_or_create(name: m.channel.name)
        votes = channel.votes.select(&:active)
        return m.reply 'No current active questions to vote upon' if votes.count.zero?
        return m.reply votes.first.display if votes.size == 1
        reply_with_nick m, "Sending list of #{votes.size} in pm"
        votes.each do |vote|
          m.user.send(vote.display)
        end
      rescue => e
        rescue_me m, e, "Error displaying votes: #{e}"
      end

      private

      def rescue_me(m, e, message)
        m.user.send message
        e.backtrace.each do |err|
          m.user.send err
        end
      end

      def reply_with_nick(m, message)
        m.reply "#{m.user.nick}: #{message}"
      end

      def vote(m, id, yea_or_nay, comment)
        channel = Channel.find_or_create(name: m.channel.name)
        vote = Vote.find(id: id, active: true, channel_id: channel.id)
        return reply_with_nick(m, "No vote with id #{id} exists and is active for channel #{channel.name}") unless vote
        nick = m.user.nick
        mask = m.user.mask.mask.split('!', 2).last
        voted = vote.responses.detect { |r| (r.by == nick) || (r.mask == mask) }
        return reply_with_nick(m, "You already voted on this issue: #{voted.display}") if voted
        Response.create(vote_id: vote.id, by: m.user.nick, mask: mask, affirm: yea_or_nay, comment: comment)
        reply_with_nick(m, "Your response to question #{id} has been registered")
      rescue => e
        rescue_me m, e, "Error #{e}"
      end
    end
  end
end
