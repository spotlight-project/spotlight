defmodule Spotlight.Router do
  defmacro spotlight(path, opts \\ []) do
    quote bind_quoted: binding() do
      scope path, alias: false, as: false do
        import Phoenix.LiveView.Router, only: [live: 4]
        live "/", SpotlightWeb.PageLive, :index, opts
      end
    end
  end
end
