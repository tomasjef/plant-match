require "net/http"
require "json"
require "digest"

# Permanent copies of plant photos on Cloudinary, because Perenual's image links expire after a day.
# Off until CLOUDINARY_URL (cloudinary://API_KEY:API_SECRET@CLOUD_NAME) is set.
class ImageStore
  DELIVERY = "f_auto,q_auto,c_limit,w_1000".freeze
  TIMEOUT_SECONDS = 20

  def self.configured?
    ENV["CLOUDINARY_URL"].present?
  end

  # Smaller, modern-format copies for the page
  def self.display_url(url)
    url.to_s.sub("/image/upload/", "/image/upload/#{DELIVERY}/")
  end

  def initialize(url: ENV.fetch("CLOUDINARY_URL"))
    uri = URI(url)
    @cloud = uri.host
    @api_key = CGI.unescape(uri.user.to_s)
    @api_secret = CGI.unescape(uri.password.to_s)
  end

  # Cloudinary downloads the source itself, so the app only sends the link
  def upload(source_url, public_id:)
    params = { overwrite: "false", public_id: public_id, timestamp: Time.now.to_i.to_s }
    response = post(params.merge(file: source_url, api_key: @api_key, signature: signature(params)))
    body = JSON.parse(response.body)
    raise "Cloudinary error: #{response.code} #{body.dig('error', 'message')}" unless response.is_a?(Net::HTTPSuccess)

    body.fetch("secure_url")
  end

  private

  def post(form)
    request = Net::HTTP::Post.new(upload_uri)
    request.set_form_data(form)

    Net::HTTP.start(upload_uri.hostname, upload_uri.port, use_ssl: true,
                                                          open_timeout: TIMEOUT_SECONDS,
                                                          read_timeout: TIMEOUT_SECONDS) do |http|
      http.request(request)
    end
  end

  def upload_uri
    URI("https://api.cloudinary.com/v1_1/#{@cloud}/image/upload")
  end

  def signature(params)
    Digest::SHA1.hexdigest(params.sort.map { |key, value| "#{key}=#{value}" }.join("&") + @api_secret)
  end
end
