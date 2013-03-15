class VideosController < ApplicationController
  
  def index
    @videos = Video.where('status=?', 'success').all
    respond_to do |format|
      format.json{ render :json=>@videos.to_json(:methods=>[:converted_url, :screenshot_small_url, :screenshot_large_url]) }
    end
  end
  
  def show
    @video = Video.find(params[:id])
    
    respond_to do |format|
      format.json{ render :json=>@video.to_json(:methods=>[:converted_url, :screenshot_small_url, :screenshot_large_url]) }
    end
  end
  
  def create
    @video = Video.new(params[:video])
    if @video.save
      
      channel  = bunny_client.create_channel
      queue    = channel.queue("mandula.videos.new_video")
      exchange = channel.default_exchange
      exchange.publish({
        :video_id       => @video.id,
        :original_path  => @video.original_path,
        :converted_path => @video.converted_path,
        :screenshot_small_path => @video.screenshot_small_path,
        :screenshot_large_path => @video.screenshot_large_path,
      }.to_json, :routing_key => queue.name)
      
      redirect_to "/#/videos/#{@video.id}"
    else
      redirect_to '/#/videos/new'
    end
  end
  
  
  
private
  def rabbit_url
    "amqp://#{ENV['RABBIT_MQ_USER']}:#{ENV['RABBIT_MQ_PASSWORD']}@#{ENV['RABBIT_MQ_HOST']}:#{ENV['RABBIT_MQ_PORT']}"
  end

  def bunny_client
    @client ||= begin
      c = Bunny.new(rabbit_url)
      c.start
      c
    end
  end
  
end
