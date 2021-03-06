require 'bosh/director/api/controllers/base_controller'

module Bosh::Director
  module Api::Controllers
    class LinkConsumersController < BaseController
      register DeploymentsSecurity

      def initialize(config)
        super(config)
        @deployment_manager = Api::DeploymentManager.new
      end

      get '/', authorization: :read do
        if params['deployment'].nil?
          raise DeploymentRequired, 'Deployment name is required'
        end

        deployment = @deployment_manager.find_by_name(params['deployment'])

        result = []

        link_consumers = Bosh::Director::Models::Links::LinkConsumer.where(deployment: deployment)
        link_consumers.each do |link_consumer|
          link_consumer.intents.each do |link_consumer_intent|
            result << generate_consumer_hash(link_consumer_intent)
          end
        end

        body(json_encode(result))
      end

      private

      def generate_consumer_hash(model)
        consumer = model.link_consumer
        {
          :id => model.id,
          :name => model.name,
          :optional => model.optional,
          :deployment => consumer.deployment.name,
          :owner_object => {
            :type => consumer.type,
            :name => consumer.name,
            :info => {
              :instance_group => consumer.instance_group,
            },
          },
          :link_consumer_definition => {
            :name => model.original_name,
            :type => model.type,
          }
        }
      end
    end
  end
end
