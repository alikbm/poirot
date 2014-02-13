module Hercule
  class LogEntry
    attr_reader :id, :timestamp, :activity, :pid, :level, :source, :message

    def initialize(hit)
      @id = hit['_id']

      source = hit['fields'] || hit['_source']

      @timestamp = source['@timestamp']
      @activity = source['@activity']
      @pid = source['@pid']
      @level = source['@level']
      @source = source['@source']
      @message = source['@message']
    end

    def self.find_by_activity_id(id, options = {})
      query = base_query(options)
      query[:filter] = { term: { '@activity' => id } }

      response = search(query)
      response.items
    end

    def self.query(qs, options = {})
      query = base_query(options)
      query[:sort] = [ { '@timestamp' => { order: "desc" } } ]
      query[:query] = {
        query_string: {
          default_field: '@message',
          default_operator: 'AND',
          query: qs
        }
      } unless qs.blank?

      search(query)
    end

    def self.search(q)
      Result.new Backend.search_all q, type: 'logentry'
    end

    def self.base_query(options = {})
      size = options[:size] || 1000
      from = options[:from] || 0

      query = {
        size: size,
        from: from,
      }
      query
    end

    class Result
      attr_reader :response

      def initialize(response)
        @response = response
      end

      def total
        @total ||= @response['hits']['total']
      end

      def items
        @items ||= @response['hits']['hits'].map do |hit|
          LogEntry.new hit
        end
      end
    end
  end
end

