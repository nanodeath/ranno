# To change this template, choose Tools | Templates
# and open the template in the editor.
require File.dirname(__FILE__) + '/json_annotations'

class User
  include JSON
  use_annotations JSONAnnotations

  json_arg
  attr_reader :username

  json_arg
  attr_reader :email

  json_arg
  attr_reader :zipcode

  attr_reader :address1, :address2, :city, :state, :country

  set_json_arg 'location', [:address1, :address2, :city, :state, :country]

  def initialize(username, password, email, zipcode, address1, address2, city, state, country)
    @username = username
    @password = password
    @email = email
    @zipcode = zipcode
    @address1 = address1
    @address2 = address2
    @city = city
    @state = state
    @country = country
  end
end
