# encoding: UTF-8
module Janky
  module Views
    class Layout < Mustache
      def title
        ENV["JANKY_PAGE_TITLE"] || "Janky Hubot"
      end

      def page_class
        nil
      end

      def root
        @request.env['SCRIPT_NAME']
      end
    end
  end
end
