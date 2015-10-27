ActionMailer::Base.delivery_method = :smtp
ActionMailer::Base.smtp_settings = {
    :address                => 'smtp.sendrid.net',
    :port                   => '587',
    :authentication         => :plain,
    :user_name              => 'app42475592@heroku.com',
    :password               => 'jmakuqy37001',
    :domain                 => 'heroku.com',
    :enable_starttls_auto   => true
}