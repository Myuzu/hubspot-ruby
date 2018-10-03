require 'hubspot/utils'

module Hubspot
  #
  # HubSpot Deals API
  #
  # {http://developers.hubspot.com/docs/methods/deal-pipelines/overview}
  #
  class DealPipeline
    PIPELINES_PATH = '/deals/v1/pipelines'.freeze
    PIPELINE_PATH = '/deals/v1/pipelines/:pipeline_id'

    attr_reader :active
    attr_reader :display_order
    attr_reader :label
    attr_reader :pipeline_id
    attr_reader :stages

    def initialize(response_hash)
      @active = response_hash['active']
      @display_order = response_hash['displayOrder']
      @label = response_hash['label']
      @pipeline_id = response_hash['pipelineId']
      @stages = response_hash['stages']
    end

    class << self
      def find(pipeline_id, opts = {})
        response = Hubspot::Connection.get_json(PIPELINE_PATH, { pipeline_id: pipeline_id }, opts)
        new(response)
      end

      def all(opts = {})
        response = Hubspot::Connection.get_json(PIPELINES_PATH, {}, opts)
        response.map { |p| new(p) }
      end

      # Creates a DealPipeline
      # {https://developers.hubspot.com/docs/methods/deal-pipelines/create-deal-pipeline}
      # @return [Hubspot::PipeLine] Company record
      def create!(post_data = {}, opts = {})
        response = Hubspot::Connection.post_json(PIPELINES_PATH, {
                                                   params: {},
                                                   body: post_data
                                                 }, opts)
        new(response)
      end
    end

    # Destroys deal_pipeline
    # {http://developers.hubspot.com/docs/methods/companies/delete_company}
    # @return [TrueClass] true
    def destroy!(opts)
      Hubspot::Connection.delete_json(PIPELINE_PATH, { pipeline_id: @pipeline_id }, opts)
    end

    def [](stage)
      @stages[stage]
    end
  end
end
