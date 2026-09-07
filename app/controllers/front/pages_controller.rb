# frozen_string_literal: true

# The page a person sees. Replace it; the shape is the point.
module Front
  class PagesController < BaseController
    def index
      # Read across the seam. If BACK is down this is a refusal, not an
      # exception -- the page renders and says so.
      @answer = pull("thing.list")
    end
  end
end
