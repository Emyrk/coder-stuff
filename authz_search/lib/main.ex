defmodule Mix.Tasks.Main do
  use Task

  @moduledoc """
  Runs and prints the standard tables/sets
  """

  def start() do
    Supervisor.start_link(
      [
        {__MODULE__, []}
      ],
      strategy: :one_for_one
    )
  end

  # Server

  def start_link(arg) do
    Task.start_link(__MODULE__, :run, [arg])
  end

  def run(_) do
    IO.puts("Below is the number permissions in each set")
    Authz.set_space_counts(true)
  end
end
