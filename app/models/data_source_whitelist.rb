class DataSourceWhitelist < ApplicationRecord
  belongs_to :data_source
  belongs_to :whitelistable, polymorphic: true
end
