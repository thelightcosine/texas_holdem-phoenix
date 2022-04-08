defmodule TexasHoldem.GameState.Table do
  @moduledoc """
  GenServer for maintaining the state of one Poker Table
  """

  use GenServer

  alias TexasHoldem.GameState.{Dealer, PlayerState}

  @type seat :: :seat1 | :seat2 | :seat3 | :seat4 | :seat5 | :seat6 | :seat7 | :seat8 | :seat9

  @type table_state :: %{
          required(:dealer) => pid(),
          required(:pot) => integer(),
          required(:bb) => integer(),
          required(:ante) => integer(),
          required(:button) => seat(),
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
    {:ok, dealer} = Dealer.start_link()
    max_players = 9

    seat_order =
      Enum.reduce(1..max_players, %{}, fn seat_number, acc ->
        seat = String.to_atom("seat#{seat_number}")

        next =
          if seat_number == max_players do
            :seat1
          else
            String.to_atom("seat#{seat_number + 1}")
          end

        Map.put(acc, seat, next)
      end)

    state = %{
      dealer: dealer,
      pot: 0,
      bb: 0,
      ante: 0,
      button: :seat1,
      max_players: max_players,
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
      },
      seat_order: seat_order
    }

    {:ok, state}
  end

  def handle_call({:get_player_info, seat}, _from, state) do
    {:reply, state[:seats][seat], state}
  end

  def handle_call({:seat_player, player_state}, _from, state) do
    seat = random_open_seat(state)
    state = update_in(state[:seats][seat], fn _ -> player_state end)
    {:reply, seat, state}
  end

  @doc """
  Returns an ordered list of seats that have active players
  currently in the hand.
  """
  @spec active_players(table_state()) :: [seat()]
  def active_players(state) do
    state
    |> Map.get(:seats)
    |> Enum.reject(fn {_k, v} -> is_nil(v) or v.in_hand == false end)
    |> order_seats(state)
  end

  @doc """
  Takes a List of seats and orders them based on the position of
  the dealer button.
  """
  @spec order_seats([seat()], table_state()) :: [seat()]
  def order_seats(seats, state) do
    button = state[:button]
    order = state[:seat_order]
    first = order[button]
    do_button_ordering(button, order, first, seats, [])
  end

  @doc """
  Recursive function for ordering seats starting to the left of the button.
  """
  @spec do_button_ordering(seat(), %{seat() => seat()}, seat(), [seat()], [seat()]) :: [seat()]
  def do_button_ordering(button, order, cursor, unordered_seats, ordered_seats) do
    ordered_seats =
      if Enum.member?(unordered_seats, cursor) do
        ordered_seats ++ [cursor]
      else
        ordered_seats
      end

    if cursor == button do
      ordered_seats
    else
      do_button_ordering(button, order, order[cursor], unordered_seats, ordered_seats)
    end
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
    |> Map.get(:seats)
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
