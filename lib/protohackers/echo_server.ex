defmodule Protohackers.EchoServer do
  require Logger
  use GenServer

  def start_link([] = _opts) do
    GenServer.start_link(__MODULE__, :no_state)
  end

  defstruct [:listen_socket]

  @impl true
  def init(:no_state) do
    listen_options = [
      # Data read and written to socket will be binary. By default, it is char list for legacy reasons.
      mode: :binary,
      # Actions on socket need to be explicit and blocking.
      active: false,
      # Can reuse the port number for things like tests etc.
      reuseaddr: true,
      # The client's write side of the socket will close when it's done, but we still need to
      # use the server write side of the socket to write to the client's read side, so don't
      # exit when a close occurs.
      exit_on_close: false
    ]

    case :gen_tcp.listen(5001, listen_options) do
      {:ok, listen_socket} ->
        Logger.info("Starting echo server on port 5001")
        state = %__MODULE__{listen_socket: listen_socket}
        {:ok, state, {:continue, :accept}}

      {:error, reason} ->
        {:stop, reason}
    end
  end

  @impl true
  def handle_continue(:accept, %__MODULE__{} = state) do
    case :gen_tcp.accept(state.listen_socket) do
      # socket is the 1:1 peer socket.
      {:ok, socket} ->
        handle_connection(socket)
        {:noreply, state, {:continue, :accept}}

      {:error, reason} ->
        {:stop, reason}
    end
  end

  defp handle_connection(socket) do
    case receive_until_closed(socket, _buffer = "", _buffered_size = 0) do
      {:ok, data} ->
        :gen_tcp.send(socket, data)

      {:error, reason} ->
        Logger.error("Failed to receive data: #{inspect(reason)}")
    end

    :gen_tcp.close(socket)
  end

  @limit _100_kb = 1024 * 100

  defp receive_until_closed(socket, buffer, buffered_size) do
    # :gen_tcp.recv will block until data is received since we're in active mode.
    # The second argument of zero means read all available bytes.
    case :gen_tcp.recv(socket, 0, 10_000) do
      # This prevents a client from streaming an unlimited amount of data and causing the BEAM
      # to run out of memory. Always want some sort of limit.
      {:ok, data} when buffered_size + byte_size(data) > @limit -> {:error, :buffer_overflow}
      # The last argument in the recursive call is an IO data structure. More efficient than concatenating lots of binaries.
      # A lot of Erlang and Elixir `write` operations can consume IO data, and are very efficient by making use of OS buffers.
      {:ok, data} -> receive_until_closed(socket, [buffer, data], buffered_size + byte_size(data))
      {:error, :closed} -> {:ok, buffer}
      {:error, reason} -> {:error, reason}
    end
  end
end

