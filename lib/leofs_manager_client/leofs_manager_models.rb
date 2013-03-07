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
module LeoFSManager

  # ==========================
  # System Information Model
  # ==========================
  class Status
    # Node
    attr_reader :node_stat
    # System
    attr_reader :system_info
    # Array of Node
    attr_reader :node_list

    def initialize(h)
      @node_stat = NodeStat.new(h[:node_stat]) if h.has_key?(:node_stat)
      @system_info = System.new(h[:system_info]) if h.has_key?(:system_info)
      @node_list = h[:node_list].map {|node| Node.new(node) } if h.has_key?(:node_list)
    end

    class System
      attr_reader :version, :ring_size, :ring_cur, :ring_prev

      # number of replicas
      attr_reader :n
      # number of replicas needed for a successful READ operation
      attr_reader :r
      # number of replicas needed for a successful WRITE operation
      attr_reader :w
      # number of replicas needed for a successful DELETE operation
      attr_reader :d

      def initialize(h)
        @version = h[:version]
        @n = Integer(h[:n])
        @r = Integer(h[:r])
        @w = Integer(h[:w])
        @d = Integer(h[:d])
        @ring_size = Integer(h[:ring_size])
        @ring_cur  = h[:ring_cur]
        @ring_prev = h[:ring_prev]
      end
    end

    # Node Status Model
    class Node
      attr_reader :type, :node, :state, :ring_cur, :ring_prev, :when

      def initialize(h)
        @type  = h[:type]
        @node  = h[:node]
        @when  = Time.parse(h[:when])
        @state = h[:state]
        @ring_cur  = h[:ring_cur]
        @ring_prev = h[:ring_prev]
      end

      alias joined_at when
    end

    class NodeStat
      @@properties = [
        :version, :log_dir, :ring_cur, :ring_prev, :vm_version,
        :total_mem_usage, :system_mem_usage, :procs_mem_usage,
        :ets_mem_usage, :num_of_procs, :limit_of_procs, :thread_pool_size
      ]

      attr_reader *@@properties

      def initialize(h)
        @@properties.each do |property|
          instance_variable_set("@#{property}", h[property])
        end
        @kernel_poll = (h[:kernel_poll] == "true")
      end
    end
  end

  # ==========================
  # Assigned file info Model
  # ==========================
  class AssignedFile
    attr_reader :node, :vnode_id, :size, :clock, :checksum, :timestamp, :delete, :num_of_chunks

    def initialize(h)
      @node      = h[:node]
      @vnode_id  = h[:vnode_id]
      @size      = h[:size]
      @clock     = h[:clock]
      @checksum  = h[:checksum]
      timestamp = h[:timestamp]
      @timestamp = timestamp.empty? ? timestamp : Time.parse(timestamp)
      @delete    = h[:delete] != 0 # bool
      @num_of_chunks = h[:num_of_chunks]
    end
  end

  # ==========================
  # Storage Status Model
  # ==========================
  class StorageStat
    attr_reader :active_num_of_objects, :total_num_of_objects,
                :active_size_of_objects, :total_size_of_objects,
                :last_compaction_start, :last_compaction_end

    alias total_of_objects total_num_of_objects # for compatibility

    def initialize(h)
      @active_num_of_objects  = h[:active_num_of_objects]
      @total_num_of_objects   = h[:total_num_of_objects]
      @active_size_of_objects = h[:active_size_of_objects]
      @total_size_of_objects  = h[:total_size_of_objects]
      @ratio_of_active_size   = h[:ratio_of_active_size]
      @last_compaction_start = h[:last_compaction_start]
      @last_compaction_end = h[:last_compaction_end]
    end

    def file_size
      warn "property 'file_size' is deprecated"
    end
  end

  # ==========================
  # S3 Credential Model
  # ==========================
  class Credential
    # AWS_ACCESS_KEY_ID
    attr_reader :access_key_id
    # AWS_SECRET_ACCESS_KEY
    attr_reader :secret_access_key

    def initialize(h)
      @access_key_id = h[:access_key_id]
      @secret_access_key = h[:secret_access_key]
    end
  end

  # ==========================
  # Login Info Model
  # ==========================
  RoleDef = {
    1 => :general,
    9 => :admin
  }
  RoleDef.default_proc = proc {|_, key| raise "invalid @user_id: #{key}" }
  RoleDef.freeze

  class LoginInfo
    attr_reader :id, :role_id, :access_key_id, :secret_key, :created_at

    def initialize(h)
      h = h[:user]
      @id = h[:id]
      @role_id = h[:role_id]
      @access_key_id = h[:access_key_id]
      @secret_key = h[:secret_key]
      @created_at = Time.parse(h[:created_at])
    end

    def role
      RoleDef[@role_id]
    end
  end

  # ==========================
  # User Info Model
  # ==========================
  class User
    attr_reader :user_id, :role_id, :access_key_id, :created_at

    def initialize(h)
      @user_id = h[:user_id]
      @role_id = h[:role_id]
      @access_key_id = h[:access_key_id]
      @created_at = Time.parse(h[:created_at])
    end

    def role
      RoleDef[@role_id]
    end
  end

  # ==========================
  # Endpoint Model
  # ==========================
  class Endpoint
    # host of the endpoint
    attr_reader :endpoint
    # When the endpoint created at
    attr_reader :created_at

    def initialize(h)
      @endpoint = h[:endpoint]
      @created_at = Time.parse(h[:created_at])
    end
  end

  # ==========================
  # S3-Bucket Model
  # ==========================
  class Bucket
    # name of bucket
    attr_reader :name
    # name of the bucket's owner
    attr_reader :owner
    # when the bucket created at
    attr_reader :created_at

    def initialize(h)
      @name       = h[:bucket]
      @owner      = h[:owner]
      @created_at = Time.parse(h[:created_at])
    end
  end

  # ==========================
  # Compaction Status Model
  # ==========================
  class CompactionStatus
    attr_reader :status
    attr_reader :last_compaction_start
    attr_reader :total_targets
    attr_reader :num_of_pending_targets
    attr_reader :num_of_ongoing_targets
    attr_reader :num_of_out_of_targets

    def initialize(h)
      @status                 = h[:status]
      @last_compaction_start  = h[:last_compaction_start]
      @total_targets          = h[:total_targets]
      @num_of_pending_targets = h[:num_of_pending_targets]
      @num_of_ongoing_targets = h[:num_of_ongoing_targets]
      @num_of_out_of_targets  = h[:num_of_out_of_targets]
    end
  end
end
