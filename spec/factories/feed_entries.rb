# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :feed_entry, :class => 'FeedEntries' do
    news_source_id 1
    headline "MyString"
    published_at ""
    news_type_id 1
    url "MyString"
    description "MyText"
  end
end
