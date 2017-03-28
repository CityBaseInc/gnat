defmodule EchoServer do
  def run(gnat) do
    spawn(fn -> init(gnat) end)
  end

  def init(gnat) do
    Gnat.sub(gnat, self(), "echo", queue_group: "bench")
    Gnat.sub(gnat, self(), "echo_ack", queue_group: "bench")
    loop(gnat)
  end

  def loop(gnat) do
    receive do
      {:msg, %{topic: "echo", reply_to: reply_to, body: body}} ->
        spawn(fn ->
          Gnat.pub(gnat, reply_to, body)
        end)
      {:msg, %{topic: "echo_ack", reply_to: reply_to, body: body}} ->
        spawn(fn ->
          Gnat.pub(gnat, reply_to, <<1>>) # ACK
          Gnat.pub(gnat, reply_to, body) # Response
        end)
      other ->
        IO.puts "server received: #{inspect other}"
    end

    loop(gnat)
  end

  def wait_loop do
    :timer.sleep(1_000)
    wait_loop()
  end
end

connection_settings = %{host: "somewhere_else"}
(1..2) |> Enum.map(fn(_i) ->
  {:ok, gnat} = Gnat.start_link(connection_settings)
  EchoServer.run(gnat)
end)

EchoServer.wait_loop()
