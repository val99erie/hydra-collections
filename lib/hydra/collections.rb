module Hydra
  module Collections
    extend ActiveSupport::Autoload
    autoload :Version
    autoload :Collectible
    autoload :SearchService
    autoload :AcceptsBatches
    autoload :AcceptsPersistedBatches
    class Engine < ::Rails::Engine
      engine_name "collections"
    end
  end
end
