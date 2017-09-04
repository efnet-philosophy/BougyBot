# frozen_string_literal: true
# Bot Namespace
module BougyBot
  Mask = Class.new Sequel::Model
  # A mask
  class Mask
    set_dataset :masks
    plugin :timestamps, create: :at, update: :last
    many_to_one :user
  end
end
