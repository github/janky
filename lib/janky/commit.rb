module Janky
  class Commit < ActiveRecord::Base
    belongs_to :repository
    has_many :builds

    def last_build
      builds.last
    end

    def build!(user, room_id = nil, compare = nil)
      compare = repository.github_url("compare/#{sha1}^...#{sha1}")

      room_id = room_id.to_s
      if room_id.empty? || room_id == "0"
        room_id = repository.room_id
      end

      builds.create!(
        :compare   => compare,
        :user      => user,
        :commit    => self,
        :room_id   => room_id,
        :branch_id => repository.branch_for('master').id
      )
    end
  end
end
