FactoryGirl.define do
  factory :user do |f|
    f.user_name "organisation"
    f.email "organisation@gmail.com"
    f.password "organisation"
    f.password_confirmation "organisation"
  end
end
