# frozen_string_literal: true
# name: discourse-nationalflags
# about: Display National Flags from User's home countries.
# version: 2.0
# authors: Neil Ebrey <neil.ebrey@gmail.com>, Rob Barrow <merefield@gmail.com>
# url: https://github.com/Ebsy/discourse-nationalflags

gem 'geocoder', '1.7.3', require: true

enabled_site_setting :nationalflag_enabled

after_initialize do
end