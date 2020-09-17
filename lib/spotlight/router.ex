defmodule Spotlight.Router do
  defmacro spotlight(path, opts \\ []) do
    quote bind_quoted: binding() do
      scope path, alias: false, as: false do
        import Phoenix.LiveView.Router, only: [live: 4]
        live "/", Spotlight.PageLive, :index, layout: {Spotlight.LayoutView, :spotlight}
      end
    end
  end
end
