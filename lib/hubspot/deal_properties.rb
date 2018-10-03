module Hubspot
  class DealProperties < Properties

    ALL_PROPERTIES_PATH  = '/deals/v1/properties'
    ALL_GROUPS_PATH      = '/deals/v1/groups'
    CREATE_PROPERTY_PATH = '/deals/v1/properties/'
    UPDATE_PROPERTY_PATH = '/deals/v1/properties/named/:property_name'
    DELETE_PROPERTY_PATH = '/deals/v1/properties/named/:property_name'
    CREATE_GROUP_PATH    = '/deals/v1/groups/'
    UPDATE_GROUP_PATH    = '/deals/v1/groups/named/:group_name'
    DELETE_GROUP_PATH    = '/deals/v1/groups/named/:group_name'

    class << self
      def add_default_parameters(params={})
        superclass.add_default_parameters(params)
      end

      def all(params={}, filter={}, opts = {})
        superclass.all(ALL_PROPERTIES_PATH, params, filter, opts)
      end

      def groups(params={}, filter={}, opts = {})
        superclass.groups(ALL_GROUPS_PATH, params, filter, opts)
      end

      def create!(params={}, opts = {})
        superclass.create!(CREATE_PROPERTY_PATH, params, opts)
      end

      def update!(property_name, params={}, opts = {})
        superclass.update!(UPDATE_PROPERTY_PATH, property_name, params, opts)
      end

      def delete!(property_name, opts = {})
        superclass.delete!(DELETE_PROPERTY_PATH, property_name, opts)
      end

      def create_group!(params={}, opts = {})
        superclass.create_group!(CREATE_GROUP_PATH, params, opts)
      end

      def update_group!(group_name, params={}, opts = {})
        superclass.update_group!(UPDATE_GROUP_PATH, group_name, params, opts)
      end

      def delete_group!(group_name, opts = {})
        superclass.delete_group!(DELETE_GROUP_PATH, group_name, opts)
      end

      def same?(src, dst)
        superclass.same?(src, dst)
      end

      def valid_params(params)
        superclass.valid_params(params)
      end
    end
  end
end
