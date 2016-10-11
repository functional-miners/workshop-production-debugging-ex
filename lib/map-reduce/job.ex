defmodule KvStore.MapReduce.Job do
  require Logger

  @moduledoc """
  Module which represents aggregation jobs built on top of lightweight `OTP` processes (`proc_lib`).
  """

  # Client API

  @doc """
  Starting point for a job which need to be performed.
  It casts result to its parent.
  """
  def start(job_id, type, bucket) do
    start_time = System.system_time()
    :proc_lib.start(__MODULE__, :init, [self(), {job_id, type, bucket, nil, start_time}])
  end

  # Required functions.

  def system_continue(parent, opts, {job_id, type, bucket, result}) do
    loop({job_id, type, bucket, result}, parent, opts)
  end

  def system_terminate(reason, _parent, _opts, _state) do
    exit(reason)
  end

  def system_get_state(state) do
    {:ok, state}
  end

  def system_replace_state(modify_state_fun, state) do
    updated_state = modify_state_fun.(state)
    {:ok, updated_state, updated_state}
  end

  defp write_debug(device, event, name) do
    :io.format(device, "~p event = ~p~n", [ name, event ])
  end

  # Private functions.

  def init(parent, state) do
    opts = :sys.debug_options([])

    :proc_lib.init_ack(parent, {:ok, self()})

    send(self(), :get_keys)
    loop(state, parent, opts)
  end

  defp loop({job_id, type, bucket, result, start_time} = state, parent, opts) do
    receive do
      {:system, from, request} ->
        :sys.handle_system_msg(request, from, parent, __MODULE__, opts, state)
        loop({job_id, type, bucket, result, start_time}, parent, opts)

      :get_keys ->
        new_opts = :sys.handle_debug(opts, &write_debug/3, __MODULE__, {:in, :get_keys})

        send(self(), :aggregation)
        keys = KvStore.Bucket.keys(bucket)

        loop({job_id, type, bucket, keys, start_time}, parent, new_opts)

      :aggregation ->
        new_opts = :sys.handle_debug(opts, &write_debug/3, __MODULE__, {:in, :aggregate})

        send(self(), :final_aggregation_step)
        aggregate = aggregation(bucket, result)

        loop({job_id, type, bucket, aggregate, start_time}, parent, new_opts)

      :final_aggregation_step ->
        new_opts = :sys.handle_debug(opts, &write_debug/3, __MODULE__, {:in, :final_aggregation_step})

        send(self(), :return_result)
        final_aggregate = final_aggregation_step(type, result)

        loop({job_id, type, bucket, final_aggregate, start_time}, parent, new_opts)

      :return_result ->
        :sys.handle_debug(opts, &write_debug/3, __MODULE__, {:in, :return_result})

        GenServer.cast(parent, {:finished, job_id, result})

        end_time = System.system_time()
        Logger.info("Job #{job_id} took #{System.convert_time_unit(end_time - start_time, :native, :milliseconds)} ms")
    end
  end

  defp aggregation(bucket, keys) do
    sum = Enum.reduce(keys, 0, fn(key, accumulator) ->
      KvStore.Helpers.maybe_sum(accumulator, KvStore.Bucket.get(bucket, key))
    end)

    {length(keys), sum}
  end

  defp final_aggregation_step(:avg, {size, sum}) do
    sum / size
  end

  defp final_aggregation_step(:sum, {_size, sum}) do
    sum
  end
end
