class UserWidgetRole < ApplicationRecord
  belongs_to :widget
  belongs_to :user

  enum :role, { viewer: 0, owner: 1 }
end
