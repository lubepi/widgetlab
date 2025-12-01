class Widget < ApplicationRecord
  has_many :user_widget_roles, dependent: :destroy
  has_many :members, through: :user_widget_roles, source: :user

  has_many :dashboard_widgets, dependent: :destroy
  has_many :dashboards, through: :dashboard_widgets, source: :dashboard

  enum :type, { value: 0, line: 1, bar: 2, column: 3, pie: 4 }
end
