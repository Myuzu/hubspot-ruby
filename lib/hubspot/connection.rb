module Hubspot
  class Connection
    include HTTParty

    class << self
      def get_json(path, params, opts = {})
        url = generate_url(path, params, opts)
        response = get(url, format: :json)
        log_request_and_response url, response
        raise Hubspot::RequestError, response unless response.success?

        response.parsed_response
      end

      def post_json(path, params, opts = {})
        no_parse = params[:params].delete(:no_parse) { false }

        url = generate_url(path, params[:params], opts)
        response = post(url, body: params[:body].to_json, headers: { 'Content-Type' => 'application/json' }, format: :json)
        log_request_and_response url, response, params[:body]
        raise Hubspot::RequestError, response unless response.success?

        no_parse ? response : response.parsed_response
      end

      def put_json(path, params, opts = {})
        url = generate_url(path, params[:params], opts)
        response = put(url, body: params[:body].to_json, headers: { 'Content-Type' => 'application/json' }, format: :json)
        log_request_and_response url, response, params[:body]
        raise Hubspot::RequestError, response unless response.success?

        response.parsed_response
      end

      def delete_json(path, params, opts = {})
        url = generate_url(path, params, opts)
        response = delete(url, format: :json)
        log_request_and_response url, response, opts[:body]
        raise Hubspot::RequestError, response unless response.success?

        response
      end

      protected

      def log_request_and_response(uri, response, body = nil)
        Hubspot::Config.logger.info "Hubspot: #{uri}.\nBody: #{body}.\nResponse: #{response.code} #{response.body}"
      end

      def generate_url(path, params = {}, options = {})
        Hubspot::Config.ensure! :hapikey
        path = path.clone
        params = params.clone
        base_url = options[:base_url] || Hubspot::Config.base_url
        params['hapikey'] = options[:hapikey] || Hubspot::Config.hapikey unless options[:hapikey] == false

        if path =~ /:portal_id/
          Hubspot::Config.ensure! :portal_id
          params['portal_id'] = Hubspot::Config.portal_id if path =~ /:portal_id/
        end

        params.each do |k, v|
          if path.match(":#{k}")
            path.gsub!(":#{k}", CGI.escape(v.to_s))
            params.delete(k)
          end
        end
        raise Hubspot::MissingInterpolation, 'Interpolation not resolved' if path =~ /:/

        query = params.map do |k, v|
          v.is_a?(Array) ? v.map { |value| param_string(k, value) } : param_string(k, v)
        end.join('&')

        path += path.include?('?') ? '&' : '?' if query.present?
        base_url + path + query
      end

      # convert into milliseconds since epoch
      def converted_value(value)
        value.is_a?(Time) ? (value.to_i * 1000) : CGI.escape(value.to_s)
      end

      def param_string(key, value)
        case key
        when /range/
          raise 'Value must be a range' unless value.is_a?(Range)

          "#{key}=#{converted_value(value.begin)}&#{key}=#{converted_value(value.end)}"
        when /^batch_(.*)$/
          key = Regexp.last_match(1).gsub(/(_.)/) { |w| w.last.upcase }
          "#{key}=#{converted_value(value)}"
        else
          "#{key}=#{converted_value(value)}"
        end
      end
    end
  end

  class FormsConnection < Connection
    follow_redirects true

    def self.submit(path, params, opts = {})
      options = { base_url: 'https://forms.hubspot.com', hapikey: false }.merge(opts)
      url = generate_url(path, params[:params], options)
      post(url, body: params[:body], headers: { 'Content-Type' => 'application/x-www-form-urlencoded' })
    end
  end
end
