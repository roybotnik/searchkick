require_relative "test_helper"

class ReindexTest < Minitest::Test
  def setup
    skip if nobrainer?
    super
  end

  def test_scoped
    store_names ["Product A"]
    Searchkick.callbacks(false) do
      store_names ["Product B", "Product C"]
    end
    Product.where(name: "Product B").reindex(refresh: true)
    assert_search "product", ["Product A", "Product B"]
  end

  def test_associations
    store_names ["Product A"]
    store = Store.create!(name: "Test")
    Product.create!(name: "Product B", store_id: store.id)
    store.products.reindex(refresh: true)
    assert_search "product", ["Product A", "Product B"]
  end

  def test_async
    skip unless defined?(ActiveJob) && defined?(ActiveRecord)

    Searchkick.callbacks(false) do
      store_names ["Product A"]
    end
    reindex = Product.reindex(async: true)
    assert_search "product", []

    index = Searchkick::Index.new(reindex[:index_name])
    index.refresh
    assert_equal 1, index.total_docs

    Product.searchkick_index.promote(reindex[:index_name])
    assert_search "product", ["Product A"]
  end
end
