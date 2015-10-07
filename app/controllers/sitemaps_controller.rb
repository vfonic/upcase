class SitemapsController < ApplicationController
  layout false

  def show
    @trails = Trail.most_recent_published
    @videos = Show.the_weekly_iteration.videos
  end
end
