require 'hubspot/utils'

module Hubspot
  #
  # HubSpot Engagements API
  #
  # {http://developers.hubspot.com/docs/methods/engagements/create_engagement}
  #
  class Engagement
    CREATE_ENGAGMEMENT_PATH = '/engagements/v1/engagements'.freeze
    ENGAGEMENT_PATH = '/engagements/v1/engagements/:engagement_id'
    GET_ASSOCIATED_ENGAGEMENTS = '/engagements/v1/engagements/associated/:objectType/:objectId/paged'

    attr_reader :id
    attr_reader :engagement
    attr_reader :associations
    attr_reader :attachments
    attr_reader :metadata

    def initialize(response_hash)
      @engagement = response_hash['engagement']
      @associations = response_hash['associations']
      @attachments = response_hash['attachments']
      @metadata = response_hash['metadata']
      @id = engagement['id']
    end

    class << self
      def create!(params = {}, opts = {})
        response = Hubspot::Connection.post_json(CREATE_ENGAGMEMENT_PATH, {
                                                   params: {},
                                                   body: params
                                                 }, opts)
        new(HashWithIndifferentAccess.new(response))
      end

      def find(engagement_id, opts = {})
        response = Hubspot::Connection.get_json(ENGAGEMENT_PATH, { engagement_id: engagement_id }, opts)
        response ? new(HashWithIndifferentAccess.new(response)) : nil
      rescue Hubspot::RequestError => ex
        if ex.response.code == 404
          nil
        else
          raise ex
        end
      end

      def find_by_company(company_id, opts = {})
        find_by_association company_id, 'COMPANY', opts
      end

      def find_by_contact(contact_id, opts = {})
        find_by_association contact_id, 'CONTACT', opts
      end

      def find_by_association(association_id, association_type, opts = {})
        path = GET_ASSOCIATED_ENGAGEMENTS
        params = { objectType: association_type, objectId: association_id }
        raise Hubspot::InvalidParams, 'expecting Integer parameter' unless association_id.try(:is_a?, Integer)
        raise Hubspot::InvalidParams, 'expecting String parameter' unless association_type.try(:is_a?, String)

        engagements = []
        begin
          response = Hubspot::Connection.get_json(path, params, opts)
          engagements = response['results'].try(:map) { |engagement| new(engagement) }
        rescue StandardError => err
          raise err unless err.message =~ /not found/
        end
        engagements
      end
    end

    # Archives the engagement in hubspot
    # {http://developers.hubspot.com/docs/methods/engagements/delete-engagement}
    # @return [TrueClass] true
    def destroy!(opts = {})
      Hubspot::Connection.delete_json(ENGAGEMENT_PATH, { engagement_id: id }, opts)
      @destroyed = true
    end

    def destroyed?
      !!@destroyed
    end

    def [](property)
      @properties[property]
    end

    # Updates the properties of an engagement
    # {http://developers.hubspot.com/docs/methods/engagements/update_engagement}
    # @param params [Hash] hash of properties to update
    # @return [Hubspot::Engagement] self
    def update!(params, opts = {})
      data = {
        engagement: params[:engagement]     || engagement,
        associations: params[:associations] || associations,
        attachments: params[:attachments]   || attachments,
        metadata: params[:metadata]         || metadata
      }

      Hubspot::Connection.put_json(ENGAGEMENT_PATH, {
                                     params: { engagement_id: id },
                                     body: data
                                   }, opts)
      self
    end
  end

  class EngagementNote < Engagement
    def body
      metadata['body']
    end

    def contact_ids
      associations['contactIds']
    end

    class << self
      def create!(contact_id, note_body, owner_id = nil, opts = {})
        data = {
          engagement: {
            type: 'NOTE'
          },
          associations: {
            contactIds: [contact_id]
          },
          metadata: {
            body: note_body
          }
        }

        # if the owner id has been provided, append it to the engagement
        data[:engagement][:owner_id] = owner_id if owner_id

        super(data, opts)
      end
    end
  end

  class EngagementCall < Engagement
    def body
      metadata['body']
    end

    def contact_ids
      associations['contactIds']
    end

    def company_ids
      associations['companyIds']
    end

    def deal_ids
      associations['dealIds']
    end

    class << self
      def create!(contact_vid, body, duration, owner_id = nil, deal_id = nil, status = 'COMPLETED', time = nil, opts = {})
        data = {
          engagement: {
            type: 'CALL'
          },
          associations: {
            contactIds: [contact_vid],
            dealIds: [deal_id],
            ownerIds: [owner_id]
          },
          metadata: {
            body: body,
            status: status,
            durationMilliseconds: duration
          }
        }

        data[:engagement][:timestamp] = time.to_i * 1000 if time
        data[:engagement][:owner_id] = owner_id if owner_id

        super(data, opts)
      end
    end
  end
end
