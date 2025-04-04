defmodule VortexPubSub.Redix do
# We can later increase the pool size if we want to
  @pool_size 1


    def child_spec(_args) do
      children =
        for index <- 0..(@pool_size - 1) do
          Supervisor.child_spec({Redix, name: :"redix_#{index}"}, id: {Redix, index})
        end

      # Spec for the supervisor that will supervise the Redix connections.
      %{
        id: RedixSupervisor,
        type: :supervisor,
        start: {Supervisor, :start_link, [children, [strategy: :one_for_one]]}
      }
    end

    def command(command) do
      Redix.command(:"redix_#{random_index()}", command)
    end

    defp random_index do
      Enum.random(0..@pool_size - 1)
    end



end
