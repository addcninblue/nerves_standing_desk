defmodule NervesStandingDesk.Reader do
  use GenServer
  alias Circuits.UART
  require Logger

  def start_link(state) when is_list(state), do: start_link(Map.new(state))
  def start_link(state) when is_map(state) do
    state = state
            |> Map.put_new(:port, "ttyAMA0")
            |> Map.put(:current_height, "28.7") # Arbitrary default height (my current minimum allowed height)
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  @impl true
  def init(state) do
    send self(), :init
    {:ok, state}
  end

  @impl true
  def handle_info(:init, %{port: port} = state) do
    {:ok, uart} = UART.start_link()
    :ok = UART.open(uart, port)

    # setting LOW will move the desk in whatever direction the pin is for
    # Be sure to initialize with HIGH to prevent moving on pin open.
    {:ok, up_pin} = Circuits.GPIO.open(23, :output, initial_value: 1)
    {:ok, down_pin} = Circuits.GPIO.open(24, :output, initial_value: 1)
    {:ok, m_pin} = Circuits.GPIO.open(18, :output, initial_value: 1)

    {:noreply, state
    |> Map.put(:uart, uart)
    |> Map.put(:up_pin, up_pin)
    |> Map.put(:down_pin, down_pin)
    |> Map.put(:m_pin, m_pin)
    |> Map.put(:sleeping, false)
    |> Map.put(:intended_height, nil)}
  end

  @impl true
  def handle_info({:circuits_uart, name, <<tens, lower_bound, upper_bound>>},
    %{up_pin: up_pin, down_pin: down_pin, port: port, intended_height: intended_height} = state) when name == port and tens < 10 do
    height_lower = (lower_bound + upper_bound) / 2
    # the thing that's sent is really weird. Format is in inches: <<tens, _, ones tenths hundredths in centimeters>>
    height = (tens * 10 + height_lower / 25.4) |> Float.round(1)

    if height != state.current_height do
      Logger.info(height)
      # This is where I report, but commenting out so it can compile for you
      # send Controller.Reporter, {:height_update, new_height}
    end

    margin_of_error = 0.5
    intended_height =
      if intended_height do
        Logger.info(intended_height)
        cond do
          abs(intended_height - height) <= margin_of_error ->
            stop(up_pin, down_pin)
            nil
          height > intended_height ->
            move_down(down_pin)
            intended_height
          height < intended_height ->
            move_up(up_pin)
            intended_height
        end
      end

    {:noreply, state |> Map.put(:current_height, height) |> Map.put(:intended_height, intended_height)}
  end

  def handle_info({:circuits_uart, name, <<17, 17, 34>>}, %{port: port} = state) when name == port do
    {:noreply, state |> Map.put(:sleeping, true)}
  end

  def handle_info({:circuits_uart, name, <<85, 85, 170>>}, %{port: port} = state) when name == port do
    {:noreply, state |> Map.put(:sleeping, false)}
  end

  def handle_info({:circuits_uart, name, <<first, second, third>>}, %{port: port} = state) when name == port do
    Logger.info("<<#{first}, #{second}, #{third}>>")
    {:noreply, state}
  end

  # ignore messages we don't care about
  def handle_info({:circuits_uart, _, _}, state), do: {:noreply, state}

  @impl true
  def handle_cast({:move_desk, height}, %{up_pin: up_pin, down_pin: down_pin, m_pin: m_pin, sleeping: sleeping, current_height: current_height} = state) do
    stop(up_pin, down_pin)
    if sleeping do
      unlock(m_pin)
    end

    if current_height < height do
      move_up(up_pin)
    else
      move_down(down_pin)
    end
    {:noreply, %{state | intended_height: height}}
  end

  defp move_up(up_pin) do
    Circuits.GPIO.write(up_pin, 0) # start moving
  end

  defp move_down(down_pin) do
    Circuits.GPIO.write(down_pin, 0) # start moving
  end

  defp stop(up_pin, down_pin) do
    Circuits.GPIO.write(up_pin, 1) # stop moving
    Circuits.GPIO.write(down_pin, 1) # stop moving
  end

  defp unlock(m_pin) do
    Circuits.GPIO.write(m_pin, 0)
    :timer.sleep(1000)
    Circuits.GPIO.write(m_pin, 1)
  end

  @impl true
  def handle_call({:get_height}, _caller, %{current_height: height} = state) do
    {:reply, height, state}
  end
end
