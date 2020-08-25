defmodule NervesStandingDesk do
  @moduledoc """
  Documentation for NervesStandingDesk.
  """

  def move_desk_to(height) do
    GenServer.cast(NervesStandingDesk.Reader, {:move_desk, height})
  end

  def get_height() do
    GenServer.call(NervesStandingDesk.Reader, {:get_height})
  end
end
