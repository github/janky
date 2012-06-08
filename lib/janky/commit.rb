module Janky
  class Commit < ActiveRecord::Base
    belongs_to :repository
    has_many :builds

    def last_build
      builds.last
    end
  end
end
