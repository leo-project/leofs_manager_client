# ======================================================================
# 
#  LeoFS Manager Client
# 
#  Copyright (c) 2012 Rakuten, Inc.
# 
#  This file is provided to you under the Apache License,
#  Version 2.0 (the "License"); you may not use this file
#  except in compliance with the License.  You may obtain
#  a copy of the License at
# 
#    http://www.apache.org/licenses/LICENSE-2.0
# 
#  Unless required by applicable law or agreed to in writing,
#  software distributed under the License is distributed on an
#  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
#  KIND, either express or implied.  See the License for the
#  specific language governing permissions and limitations
#  under the License.
# 
# ======================================================================
require "socket"
require "json"
require_relative "../lib/leofs_manager_client"

Host = "localhost"
Port = 50000

$DEBUG = false
Thread.abort_on_exception = true

module Dummy
  Status = {
    :system_info =>
    { :version=>"0.10.1",
      :n=>"1",
      :r=>"1",
      :w=>"1",
      :d=>"1",
      :ring_size=>"128",
      :ring_hash_cur=>"2688134336",
      :ring_hash_prev=>"2688134336"},
     :node_list=>
      [{:type=>"S",
        :node=>"storage_0@127.0.0.1",
        :state=>"running",
        :ring_cur=>"a039acc0",
        :ring_prev=>"a039acc0",
        :when=>"2012-09-21 15:08:22 +0900"},
       {:type=>"G",
        :node=>"gateway_0@127.0.0.1",
        :state=>"running",
        :ring_cur=>"a039acc0",
        :ring_prev=>"a039acc0",
        :when=>"2012-09-21 15:08:25 +0900"}]
  }.to_json

  Argument = "hoge" # passed to command which requires some arguments.

  # dummy Manager
  class Manager
    Thread.new do
      TCPServer.open(Host, Port) do |server|
        loop do
          socket = server.accept
          while line = socket.gets
            line.rstrip!
            case line
            when "status"
              result = Status
            else
              result = { :result => line }.to_json
            end
            socket.puts(result)
          end
        end
      end
    end
  end
end

# commands which returns result as text simply.
# key: command, value: number of required arguments
SimpleCommands = {
  "detach" => 1,
  "resume" => 1,
  "rebalance" => 0,
  "whereis" => 1,
  "du" => 1,
  "compact" => 1,
  "purge" => 1,
  "s3_gen_key" => 1,
  "s3_set_endpoint" => 1,
  "s3_del_endpoint" => 1,
  "s3_get_endpoints" => 0,
  "s3_add_bucket" => 2,
  "s3_get_buckets" => 0
}

include LeoFSManager

describe LeoFSManager do
  before(:all) do
    Dummy::Manager.new
    @manager = Client.new("#{Host}:#{Port}")
  end

  it "has version" do
    defined?(VERSION).should eql "constant"
    VERSION.should eql "0.2.0"
  end

  it "raises error when it is passed invalid params" do
    lambda { Client.new }.should raise_error
  end

  describe "#status" do
    it "returns Hash" do
      @manager.status.should be_a Hash
    end

    it "returns SystemInfo" do
      @manager.status[:system_info].should be_a SystemInfo
    end

    it "returns node list" do
      node_list = @manager.status[:node_list]
      node_list.should be_a Array
      node_list.each do |node|
        node.should be_a NodeInfo
      end
    end
  end

  describe "#start" do
    it "returns nil" do
      @manager.start.should be_nil
    end
  end

  SimpleCommands.each do |name, args_num|
    describe "##{name}" do
      it "returns result" do
        args = [Dummy::Argument] * args_num
        @manager.send(name, *args)
      end
    end
  end
end
