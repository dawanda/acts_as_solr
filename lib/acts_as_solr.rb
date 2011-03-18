# Copyright (c) 2006 Erik Hatcher, Thiago Jackiw
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

require 'active_record'
require 'rexml/document'
require 'net/http'
require 'yaml'

require File.dirname(__FILE__) + '/solr'
require File.dirname(__FILE__) + '/acts_methods'
require File.dirname(__FILE__) + '/class_methods'
require File.dirname(__FILE__) + '/instance_methods'
require File.dirname(__FILE__) + '/common_methods'
require File.dirname(__FILE__) + '/deprecation'
require File.dirname(__FILE__) + '/search_results'
require File.dirname(__FILE__) + '/lazy_document'

module ActsAsSolr
  def self.config
    file = "#{Rails.root}/config/solr.yml"
    if File.exists?(file)
      YAML::load_file(file)[Rails.env]
    else
      warn "no config found #{file}"
      {}
    end
  end
  
  def self.url
    url = config['url']
    # for backwards compatibility
    url ||= "http://#{config['host']}:#{config['port']}/#{config['servlet_path']}"
    url ||= 'http://localhost:8982/solr'
    url
  end

  def self.slave_url
    config['slave_url'] || url
  end

  
  def self.client_timeout
    config['client_timeout'].to_i || 5
  end

  class Post
    def self.execute(request, options={})
      url = (options[:slave] ? ActsAsSolr.slave_url : ActsAsSolr.url)
      begin
        Solr::Connection.new(url).send(request, options)
      rescue
        raise "Couldn't connect to the Solr server at #{url}. #{$!}"
      end
    end
  end
end

# reopen ActiveRecord and include the acts_as_solr method
ActiveRecord::Base.extend ActsAsSolr::ActsMethods
