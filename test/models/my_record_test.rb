require "test_helper"

class MyRecordTest < ActiveSupport::TestCase
  test "query cache does not produce false positives" do
    iterations = 10000
    false_positives = 0

    iterations.times do
      key = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'.each_char.to_a.shuffle.first
      val = rand(1000)

      record = MyRecord.create(value: { key => val }, description: "The record we want to find")

      MyRecord.connection.enable_query_cache!

      search = { key => val }
      the_record = MyRecord.where(value: search).first # this should populate the cache

      # cache now looks like this, essentially:
      #  { "SELECT * FROM my_records WHERE value = $1" =>
      #    { [search] => the_record }
      #  }

      new_val = rand(1000) until new_val != val # just to make sure!

      search.merge!(key => new_val) # this mutates the key inside the query cache

      # normally: because the hash of the key has changed, this is a cache miss
      # however, if the new hash key's numerical hash falls into the same bucket
      # as the original, the hash lookup will a) find the first query's entry and
      # b) use it, because the objects are equal b/c the `search` hash was mutated
      # is equal to key_obj (since it's a reference)

      should_not_exist = MyRecord.where(value: search).first # this SHOULD not return a value

      false_positives += 1 if should_not_exist.present?
    end

    assert_equal 0, false_positives
  end
end
