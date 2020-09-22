defmodule Spotlight.Components.PercentileGraph do
  use Spotlight.Web, :live_component

  alias DogSketch.SimpleDog

  @impl true
  def mount(socket) do
    {:ok, assign(socket, :scale, "Linear")}
  end

  def update(assigns, socket) do
    socket =
      socket
      |> assign(:id, assigns.id)
      |> assign(:quantile_data, formatted_time_series(assigns.id))

    {:ok, socket}
  end

  def render(assigns) do
    ~L"""
    <div class="chart_container">
      <div class="chart_parent" id="chart_parent">
        <form class="controls" phx-change="controls_changed" phx-target="<%= @myself %>">
          <select name="scale" id="scale_selected" phx-update="ignore">
            <option value="Linear">Linear Scale</option>
            <option value="Log10">Log Scale</option>
          </select>
        </form>
      </div>
      <div id="chart" class="chart" data-quantile="<%= Jason.encode!(@quantile_data) %>" data-scale="<%= Jason.encode!(@scale) %>" phx-hook="ChartData" phx-update="ignore"></div>
    </div>
    """
  end

  @impl true
  def handle_event("controls_changed", %{"scale" => scale_val}, socket) do
    socket = assign(socket, :scale, scale_val)

    {:noreply, assign(socket, :quantile_data, formatted_time_series(socket.assigns.id))}
  end

  defp formatted_time_series(id) do
    data = Spotlight.TelemetryPercentileCollector.get_merged(id)

    keys =
      Enum.map(data, fn {ts, _} -> ts end)
      |> Enum.sort()

    [
      keys,
      Enum.map(keys, fn ts ->
        get_quantile(data, ts, 0.99)
      end),
      Enum.map(keys, fn ts ->
        get_quantile(data, ts, 0.90)
      end),
      Enum.map(keys, fn ts ->
        get_quantile(data, ts, 0.50)
      end),
      Enum.map(keys, fn ts ->
        Map.get(data, ts, SimpleDog.new()) |> SimpleDog.count() |> ceil()
      end)
    ]
  end

  defp get_quantile(data, ts, quantile) do
    Map.get(data, ts, nil)
    |> case do
      nil ->
        nil

      sd ->
        val = SimpleDog.quantile(sd, quantile) |> ceil()
        val / 1000
    end
  end
end
