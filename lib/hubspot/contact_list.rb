module Hubspot
  #
  # HubSpot Contact lists API
  #
  class ContactList
    LISTS_PATH           = '/contacts/v1/lists'.freeze
    LIST_PATH            = '/contacts/v1/lists/:list_id'
    LIST_BATCH_PATH      = LISTS_PATH + '/batch'
    CONTACTS_PATH        = LIST_PATH + '/contacts/all'
    RECENT_CONTACTS_PATH = LIST_PATH + '/contacts/recent'
    ADD_CONTACT_PATH     = LIST_PATH + '/add'
    REMOVE_CONTACT_PATH  = LIST_PATH + '/remove'
    REFRESH_PATH         = LIST_PATH + '/refresh'

    class << self
      # {http://developers.hubspot.com/docs/methods/lists/create_list}
      def create!(params = {}, opts = {})
        dynamic = params.delete(:dynamic) { false }
        portal_id = params.delete(:portal_id) { Hubspot::Config.portal_id }

        response = Hubspot::Connection.post_json(LISTS_PATH, {
                                                   params: {},
                                                   body: params.merge(dynamic: dynamic, portal_id: portal_id)
                                                 }, opts)
        new(response)
      end

      # {http://developers.hubspot.com/docs/methods/lists/get_lists}
      # {http://developers.hubspot.com/docs/methods/lists/get_static_lists}
      # {http://developers.hubspot.com/docs/methods/lists/get_dynamic_lists}
      def all(params = {}, opts = {})
        static = params.delete(:static) { false }
        dynamic = params.delete(:dynamic) { false }

        # NOTE: As opposed of what the documentation says, getting the static or dynamic lists returns all the lists, not only 20 lists
        path = LISTS_PATH + (static ? '/static' : dynamic ? '/dynamic' : '')
        response = Hubspot::Connection.get_json(path, params, opts)
        response['lists'].map { |l| new(l) }
      end

      # {http://developers.hubspot.com/docs/methods/lists/get_list}
      # {http://developers.hubspot.com/docs/methods/lists/get_batch_lists}
      def find(ids, opts = {})
        batch_mode, path, params = case ids
                                   when Integer then [false, LIST_PATH, { list_id: ids }]
                                   when String then [false, LIST_PATH, { list_id: ids.to_i }]
                                   when Array then [true, LIST_BATCH_PATH, { batch_list_id: ids.map(&:to_i) }]
                                   else raise Hubspot::InvalidParams, 'expecting Integer or Array of Integers parameter'
        end

        response = Hubspot::Connection.get_json(path, params, opts)
        batch_mode ? response['lists'].map { |l| new(l) } : new(response)
      end
    end

    attr_reader :id
    attr_reader :portal_id
    attr_reader :name
    attr_reader :dynamic
    attr_reader :properties

    def initialize(hash)
      send(:assign_properties, hash)
    end

    # {http://developers.hubspot.com/docs/methods/lists/update_list}
    def update!(params = {}, opts = {})
      response = Hubspot::Connection.post_json(LIST_PATH, {
                                                 params: { list_id: @id },
                                                 body: params
                                               }, opts)
      send(:assign_properties, response)
      self
    end

    # {http://developers.hubspot.com/docs/methods/lists/delete_list}
    def destroy!(opts = {})
      response = Hubspot::Connection.delete_json(LIST_PATH, { list_id: @id }, opts)
      @destroyed = (response.code == 204)
    end

    # {http://developers.hubspot.com/docs/methods/lists/get_list_contacts}
    def contacts(params = {}, _opts = {})
      # NOTE: caching functionality can be dependant of the nature of the list, if dynamic or not ...
      bypass_cache = params.delete(:bypass_cache) { false }
      recent = params.delete(:recent) { false }
      paged = params.delete(:paged) { false }

      if bypass_cache || @contacts.nil?
        path = recent ? RECENT_CONTACTS_PATH : CONTACTS_PATH
        params[:list_id] = @id

        response = Hubspot::Connection.get_json(path, Hubspot::ContactProperties.add_default_parameters(params))
        @contacts = response['contacts'].map! { |c| Hubspot::Contact.new(c) }
        paged ? response : @contacts
      else
        @contacts
      end
    end

    # {http://developers.hubspot.com/docs/methods/lists/refresh_list}
    def refresh(opts = {})
      response = Hubspot::Connection.post_json(REFRESH_PATH, {
                                                 params: { list_id: @id, no_parse: true },
                                                 body: {}
                                               }, opts)
      response.code == 204
    end

    # {http://developers.hubspot.com/docs/methods/lists/add_contact_to_list}
    def add(contacts, opts = {})
      contact_ids = [contacts].flatten.uniq.compact.map(&:vid)
      response = Hubspot::Connection.post_json(ADD_CONTACT_PATH, {
                                                 params: { list_id: @id },
                                                 body: { vids: contact_ids }
                                               }, opts)

      response['updated'].sort == contact_ids.sort
    end

    # {http://developers.hubspot.com/docs/methods/lists/remove_contact_from_list}
    def remove(contacts, opts = {})
      contact_ids = [contacts].flatten.uniq.compact.map(&:vid)
      response = Hubspot::Connection.post_json(REMOVE_CONTACT_PATH, {
                                                 params: { list_id: @id },
                                                 body: { vids: contact_ids }
                                               }, opts)
      response['updated'].sort == contact_ids.sort
    end

    def destroyed?
      !!@destroyed
    end

    private

    def assign_properties(hash)
      @id = hash['listId']
      @portal_id = hash['portalId']
      @name = hash['name']
      @dynamic = hash['dynamic']
      @properties = hash
    end
  end
end
