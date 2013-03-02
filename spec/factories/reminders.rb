# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :reminder do
    assigned_task nil
    sent_at "2013-03-01 23:58:31"
  end
end
