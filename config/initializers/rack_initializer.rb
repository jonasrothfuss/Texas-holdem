#Increases the key space to be able to upload bigger images
if Rack::Utils.respond_to?("key_space_limit=")
  Rack::Utils.key_space_limit = 68719476736
end