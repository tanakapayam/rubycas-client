require 'casclient/tickets/storage'
require 'redis'

module CASClient
  module Tickets
    module Storage

      # A Ticket Store that keeps its ticket data in redis

      class RedisStore < AbstractTicketStore

        def initialize(config={})
          @namespace = config.fetch(:namespace, "cas_ticket_")
          @redis = Redis.new({ host: config[:host], port: config[:port] })
          @ttl = config.fetch(:ttl, 12.hours).to_i
        end

        def redis
          @redis
        end

        def key_for(key)
          @namespace + key
        end

        def set(key, value)
          redis.set(key, value)
          redis.expire(key, @ttl)
        end

        def get(key)
          val = redis.get(key)
          redis.del(key)
          val
        end

        def store_service_session_lookup(st, controller)
          raise CASException, "No service_ticket specified." unless st
          raise CASException, "No controller specified." unless controller

          st = st.ticket if st.kind_of? ServiceTicket
          set(key_for(st), dump(controller.session.id))
        end

        def read_service_session_lookup(st)
          raise CASException, "No service_ticket specified." unless st
          st = st.ticket if st.kind_of? ServiceTicket
          sesh = load(get(key_for(st)))
          raise CASException, "No service_ticket found." unless sesh
          sesh
        end

        def cleanup_service_session_lookup(st)
          #no cleanup needed for this ticket store
          #we still raise the exception for API compliance
          raise CASException, "No service_ticket specified." unless st
        end

        def save_pgt_iou(pgt_iou, pgt)
          raise CASClient::CASException.new("Invalid pgt_iou") if pgt_iou.nil?
          raise CASClient::CASException.new("Invalid pgt") if pgt.nil?
          set(key_for(pgt_iou), dump(pgt) )
        end

        def retrieve_pgt(pgt_iou)
          raise CASException, "No pgt_iou specified. Cannot retrieve the pgt." unless pgt_iou
          pgt_id = load(get(key_for(pgt_iou)))
          raise CASException, "Invalid pgt_iou specified. Perhaps this pgt has already been retrieved?" unless pgt_id
          pgt_id
        end

        def dump(str)
          str.to_s
        end

        def load(str)
          str
        end

      end

      REDIS_TICKET_STORE = RedisStore

    end
  end
end
