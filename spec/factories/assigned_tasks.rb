# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :assigned_task do
    user nil
    task nil
    reminder_frequency 1
    completed_at "2013-03-01 23:57:02"
  end
end
