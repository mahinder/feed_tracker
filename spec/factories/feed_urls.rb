# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :feed_url do
    references ""
    feed_url "MyString"
  end
end
