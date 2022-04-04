defmodule TexasHoldem.GameState.Table do
  @moduledoc """
  GenServer for maintaining the state of one Poker Table
  """

  use GenServer

  alias TexasHoldem.GameState.PlayerState

  @type table_state :: %{
          required(:pot) => integer(),
          required(:bb) => integer(),
          required(:ante) => integer(),
          required(:button) => integer(),
          required(:max_players) => 1..9,
          required(:seats) => %{
            required(:seat1) => PlayerState.t() | nil,
            required(:seat2) => PlayerState.t() | nil,
            required(:seat3) => PlayerState.t() | nil,
            required(:seat4) => PlayerState.t() | nil,
            required(:seat5) => PlayerState.t() | nil,
            required(:seat6) => PlayerState.t() | nil,
            required(:seat7) => PlayerState.t() | nil,
            required(:seat8) => PlayerState.t() | nil,
            required(:seat9) => PlayerState.t() | nil
          }
        }

  @type seat :: :seat1 | :seat2 | :seat3 | :seat4 | :seat5 | :seat6 | :seat7 | :seat8 | :seat9
  #
  # section Client API
  #

  def start_link() do
    GenServer.start_link(__MODULE__, :ok)
  end

  @doc """
  Returns the current state of the Player at the given seat.
  """
  @spec get_player_info(pid(), seat()) :: PlayerState.t()
  def get_player_info(server, seat) do
    GenServer.call(server, {:get_player_info, seat})
  end

  @doc """
  Adds the PlayerState to a random open seat at the table
  and returns what seat they were placed at.
  """
  @spec seat_player(pid(), PlayerState.t()) :: seat()
  def seat_player(server, player_state) do
    GenServer.call(server, {:seat_player, player_state})
  end

  #
  # section Callbacks
  #

  def init(_) do
    state = %{
      pot: 0,
      bb: 0,
      ante: 0,
      button: 1,
      max_players: 9,
      seats: %{
        seat1: nil,
        seat2: nil,
        seat3: nil,
        seat4: nil,
        seat5: nil,
        seat6: nil,
        seat7: nil,
        seat8: nil,
        seat9: nil
      }
    }

    {:ok, state}
  end

  def handle_call({:get_player_info, seat}, _from, state) do
    {:reply, state[:seats][seat], state}
  end

  def handle_call({:seat_player, player_state}, _from, state) do
    seat = random_open_seat(state)
    state = update_in(state[:seats][seat], fn(_) -> player_state end)
    {:reply, seat, state}
  end

  @doc """
  Returns one randomly selected empty seat available
  at this table.
  """
  @spec random_open_seat(table_state()) :: seat()
  def random_open_seat(state) do
    state
    |> available_seats()
    |> Enum.random()
  end

  @doc """
    Returns a List of empty seats available at this Table.
  """
  @spec available_seats(table_state()) :: [seat()]
  def available_seats(state) do
    state
    |> Map.get(:seats, %{})
    |> Stream.filter(fn {_k, v} -> is_nil(v) end)
    |> Stream.filter(fn {k, _v} -> valid_seat?(k, state) end)
    |> Enum.map(fn {k, _v} -> k end)
  end

  @doc """
  Takes a seat name (such as :seat3) and determines if it
  it valid for the game, based on the set max players. For
  example, in a six high game, seat7 seat8 and seat9 would
  not be valid.
  """
  @spec valid_seat?(seat(), table_state()) :: boolean()
  def valid_seat?(seat, state) do
    seat
    |> Atom.to_string()
    |> String.last()
    |> String.to_integer()
    |> then(&(&1 <= state.max_players))
  end
end
