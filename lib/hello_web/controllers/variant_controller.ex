defmodule HelloWeb.VariantController do
  use HelloWeb, :controller

  alias Hello.Catalog

  def index(conn, params) do
    variants = Catalog.variants_list(params)
    render(conn, :index, variants: variants, query: "foo")
  end

end
