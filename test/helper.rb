require 'rubygems'
require 'bundler'
require 'yaml'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'minitest/autorun'


$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'voyager_patron'

SERVER = VoyagerPatron::Server.new(YAML.load_file(File.join(File.dirname(__FILE__), '..', 'config', 'library_credentials.yml')))

