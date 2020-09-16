defmodule SpotlightWeb.Router do
  use SpotlightWeb, :router

  defmacro spotlight(path, opts \\ []) do
    quote bind_quoted: binding() do
      scope path, alias: false, as: false do
        import Phoenix.LiveView.Router, only: [live: 4]
        live "/", SpotlightWeb.PageLive, :index
      end
    end
  end
end
