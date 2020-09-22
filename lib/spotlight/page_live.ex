defmodule Spotlight.PageLive do
  use Spotlight.Web, :live_view

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:pause_action, "Pause")
      |> assign(:refresh_rate, 1000)
      |> assign(:tick, 0)
      |> schedule_tick()

    {:ok, socket}
  end

  @impl true
  def handle_event("controls_changed", %{"rate" => rate_val}, socket) do
    socket =
      case rate_val do
        "Paused" ->
          assign(socket, :refresh_rate, "Paused")

        str_int ->
          {refresh_rate, _} = Integer.parse(str_int)
          assign(socket, :refresh_rate, refresh_rate)
      end

    {:noreply, schedule_tick(socket)}
  end

  @impl true
  def handle_info({:tick, tick}, socket) do
    case socket.assigns.tick do
      ^tick ->
        socket =
          assign(socket, :tick, socket.assigns.tick + 1)
          |> schedule_tick()

        {:noreply, socket}

      _ ->
        {:noreply, socket}
    end
  end

  defp schedule_tick(socket) do
    unless is_paused?(socket) do
      Process.send_after(self(), {:tick, socket.assigns.tick}, socket.assigns.refresh_rate)
    end

    socket
  end

  defp is_paused?(socket) do
    case socket.assigns.refresh_rate do
      "Paused" -> true
      _ -> false
    end
  end
end
