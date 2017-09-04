# frozen_string_literal: true
module BougyBot
  Note = Class.new Sequel::Model
  # Notes, async messages
  class Note
    set_dataset :notes
  end
end
