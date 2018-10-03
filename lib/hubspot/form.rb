module Hubspot
  #
  # HubSpot Form API
  #
  # {https://developers.hubspot.com/docs/methods/forms/forms_overview}
  #
  class Form
    FORMS_PATH       = '/forms/v2/forms'.freeze # '/contacts/v1/forms'
    FORM_PATH        = '/forms/v2/forms/:form_guid' # '/contacts/v1/forms/:form_guid'
    FIELDS_PATH      = '/forms/v2/fields/:form_guid' # '/contacts/v1/fields/:form_guid'
    FIELD_PATH       = FIELDS_PATH + '/:field_name'
    SUBMIT_DATA_PATH = '/uploads/form/v2/:portal_id/:form_guid'

    class << self
      # {https://developers.hubspot.com/docs/methods/forms/create_form}
      def create!(params = {}, opts = {})
        response = Hubspot::Connection.post_json(FORMS_PATH, {
                                                   params: {},
                                                   body: params
                                                 }, opts)
        new(response)
      end

      def all(opts = {})
        response = Hubspot::Connection.get_json(FORMS_PATH, {}, opts)
        response.map { |f| new(f) }
      end

      # {https://developers.hubspot.com/docs/methods/forms/get_form}
      def find(guid, opts = {})
        response = Hubspot::Connection.get_json(FORM_PATH, { form_guid: guid }, opts)
        new(response)
      end
    end

    attr_reader :guid
    attr_reader :fields
    attr_reader :properties

    def initialize(hash)
      send(:assign_properties, hash)
    end

    # {https://developers.hubspot.com/docs/methods/forms/get_fields}
    # {https://developers.hubspot.com/docs/methods/forms/get_field}
    def fields(params = {}, opts = {})
      bypass_cache = params.delete(:bypass_cache) { false }
      field_name = params.delete(:only) { nil }

      if field_name
        field_name = field_name.to_s
        if bypass_cache || @fields.nil? || @fields.empty?
          response = Hubspot::Connection.get_json(FIELD_PATH, {
                                                    form_guid: @guid,
                                                    field_name: field_name
                                                  }, opts)
          response
        else
          @fields.detect { |f| f['name'] == field_name }
        end
      else
        if bypass_cache || @fields.nil? || @fields.empty?
          response = Hubspot::Connection.get_json(FIELDS_PATH, { form_guid: @guid }, opts)
          @fields = response
        end
        @fields
      end
    end

    # {https://developers.hubspot.com/docs/methods/forms/submit_form}
    def submit(params = {}, opts = {})
      response = Hubspot::FormsConnection.submit(SUBMIT_DATA_PATH, {
                                                   params: { form_guid: @guid },
                                                   body: params
                                                 }, opts)
      [204, 302, 200].include?(response.code)
    end

    # {https://developers.hubspot.com/docs/methods/forms/update_form}
    def update!(params = {}, opts = {})
      response = Hubspot::Connection.post_json(FORM_PATH, {
                                                 params: { form_guid: @guid },
                                                 body: params
                                               }, opts)
      send(:assign_properties, response)
      self
    end

    # {https://developers.hubspot.com/docs/methods/forms/delete_form}
    def destroy!(opts = {})
      response = Hubspot::Connection.delete_json(FORM_PATH, { form_guid: @guid }, opts)
      @destroyed = (response.code == 204)
    end

    def destroyed?
      !!@destroyed
    end

    private

    def assign_properties(hash)
      @guid = hash['guid']
      @fields = hash['formFieldGroups'].inject([]) { |result, fg| result | fg['fields'] }
      @properties = hash
    end
  end
end
