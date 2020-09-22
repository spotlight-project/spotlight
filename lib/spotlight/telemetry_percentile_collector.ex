defmodule Spotlight.TelemetryPercentileCollector do
  alias DogSketch.SimpleDog

  @type opts :: [opt]
  @type opt ::
          {:metric, []}
          | {:measurement, atom()}
          | {:seconds_to_keep, pos_integer()}
          | {:max_error, float()}

  @doc """
  Example:

  ```elixir
  def start(_type, _args) do
    children = [
      {Spotlight.TelemetryPercentileCollector, %{metric: [:phoenix, :endpoint, :stop], measurement: :duration}}
    ]
    Supervisor.start_link(children, strategy: :one_for_one)
  end
  ```
  """
  def child_spec(opts) do
    metric = Keyword.fetch!(opts, :metric)
    measurement = Keyword.fetch!(opts, :measurement)
    name = Keyword.fetch!(opts, :name)

    %{
      id: name,
      start: {__MODULE__, :start_link, [[name: name, metric: metric, measurement: measurement]]}
    }
  end

  def start_link(opts) do
    name = Keyword.fetch!(opts, :name)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @default_seconds_to_keep 600
  @default_max_error 0.04

  def init(opts) do
    metric = Keyword.fetch!(opts, :metric)
    measurement = Keyword.fetch!(opts, :measurement)
    seconds_to_keep = Keyword.get(opts, :seconds_to_keep, @default_seconds_to_keep)
    max_error = Keyword.get(opts, :max_error, @default_max_error)

    :telemetry.attach(
      "#{__MODULE__}.#{Enum.join(metric, "-")}",
      metric,
      &__MODULE__.handle_metrics/4,
      {measurement, self()}
    )

    {:ok, %{keys: [], value_map: %{}, seconds_to_keep: seconds_to_keep, max_error: max_error}}
  end

  def handle_metrics(metric, measurements, _metadata, {measurement, pid}) do
    send(
      pid,
      {
        :measurement,
        Map.get(measurements, measurement),
        System.monotonic_time(:second),
        System.time_offset(:second)
      }
    )
  end

  def handle_info({:measurement, measurement, mono_time, time_offset}, state) do
    converted_measurement_us = System.convert_time_unit(measurement, :native, :microsecond)
    seconds_to_keep = state.seconds_to_keep

    new_state =
      case state.keys do
        [^mono_time | _] ->
          %{
            state
            | value_map:
                Map.update!(state.value_map, mono_time, fn {dog_sketch, dt} ->
                  {SimpleDog.insert(dog_sketch, converted_measurement_us), dt}
                end)
          }

        keys ->
          sdog =
            SimpleDog.new(error: state.max_error)
            |> SimpleDog.insert(converted_measurement_us)

          new_state = %{
            state
            | keys: [mono_time | keys],
              value_map:
                Map.put(
                  state.value_map,
                  mono_time,
                  {sdog, mono_time + time_offset}
                )
          }

          new_keys =
            new_state.keys
            |> Enum.filter(fn
              key when key > mono_time - seconds_to_keep -> true
              _ -> false
            end)

          new_state = Map.put(new_state, :keys, new_keys)

          Map.put(new_state, :value_map, Map.take(new_state.value_map, new_state.keys))
      end

    {:noreply, new_state}
  end

  def handle_call(:get_all, _from, state) do
    {:reply, Map.new(state.value_map, fn {_time, {sdog, time}} -> {time, sdog} end), state}
  end

  def get_all(name) do
    GenServer.call(name, :get_all)
  end

  def get_merged(name) do
    {results, _bad_nodes} = :rpc.multicall(__MODULE__, :get_all, [name])

    Enum.map(results, fn
      {:badrpc, _reason} -> nil
      result -> result
    end)
    |> Enum.filter(fn x -> x end)
    |> Enum.reduce(%{}, fn result, acc ->
      Map.merge(acc, result, fn _key, s1, s2 ->
        SimpleDog.merge(s1, s2)
      end)
    end)
  end
end
