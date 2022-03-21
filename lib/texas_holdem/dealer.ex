defmodule TexasHoldem.Dealer do
  @moduledoc "GenServer responsible for dealing out cards"

  @clubs ~w[cA cK cQ cJ c10 c9 c8 c7 c6 c5 c4 c3 c2]a
  @diamonds ~w[dA dK dQ dJ d10 d9 d8 d7 d6 d5 d4 d3 d2]a
  @hearts ~w[hA hK hQ hJ h10 h9 h8 h7 h6 h5 h4 h3 h2]a
  @spades ~w[sA sK sQ sJ s10 s9 s8 s7 s6 s5 s4 s3 s2]a
  @deck @clubs ++ @diamonds ++ @hearts ++ @spades

  use GenServer

  @type card() :: atom()

  #
  # section Client API
  #

  def start_link() do
    GenServer.start_link(__MODULE__, :ok)
  end

  @doc """
  Burn the top card off the Deck. Used before dealing
  streets out onto the Board.
  """
  def burn(server) do
    GenServer.cast(server, :burn)
  end

  @doc """
  Deal N cards out from the Deck.
  """
  @spec deal(pid(), integer()) :: [card()]
  def deal(server, n) do
    GenServer.call(server, {:deal, n})
  end

  @doc """
  Function for inspecting what cards are currently in the muck.
  """
  @spec inspect_muck(pid()) :: [card()]
  def inspect_muck(server) do
    GenServer.call(server, :inspect_muck)
  end

  @doc """
  Mucks a player's hand.
  """
  def muck_hand(server, hand) when is_list(hand) do
    GenServer.cast(server, {:muck_hand, hand})
  end

  @doc """
  Re-shuffles and cuts the deck to be ready for a new
  round of play.
  """
  def shuffle(server) do
    GenServer.cast(server, :shuffle)
  end

  #
  # section Callbacks
  #

  def init(_) do
    # Seed the PRNG for this process with entropy from :crypto
    :crypto.rand_seed()
    shuffled_deck = shuffle_and_cut_deck()
    # create a Muck
    muck = []
    # Put our shuffled deck and muck into the GenServer state
    {:ok, {shuffled_deck, muck}}
  end

  def handle_call({:deal, n}, _from, {deck, muck}) do
    state = deal_n_cards(n, deck)
    {:reply, state.dealt_cards, {state.remaining_deck, muck}}
  end

  def handle_call(:inspect_muck, _from, {deck, muck}) do
    {:reply, muck, {deck, muck}}
  end

  def handle_cast(:burn, {deck, muck}) do
    state = deal_n_cards(1, deck)
    muck = muck ++ state.dealt_cards
    {:no_reply, {state.remaining_deck, muck}}
  end

  def handle_cast({:muck_hand, hand}, {deck, muck}) when is_list(hand) do
    muck = muck ++ hand
    {:no_reply, {deck, muck}}
  end

  def handle_cast(:shuffle, {_deck, _muck}) do
    deck = shuffle_and_cut_deck()
    muck = []
    {:noreply, {deck, muck}}
  end

  def shuffle_and_cut_deck() do
    # Shuffle up our deck using the seeded PRNG
    shuffled_deck = Enum.shuffle(@deck)

    # Simulate cutting the deck at a random location
    cut_size = :rand.uniform(51)

    %{dealt_cards: first_half, remaining_deck: second_half} =
      deal_n_cards(cut_size, shuffled_deck)

    second_half ++ first_half
  end

  def deal_n_cards(n, deck) do
    state = %{dealt_cards: [], remaining_deck: deck}

    Enum.reduce(1..n, state, fn _, state ->
      {card, remainder} = List.pop_at(state.remaining_deck, 0)
      all_dealt_cards = state.dealt_cards ++ [card]
      state = Map.put(state, :dealt_cards, all_dealt_cards)
      Map.put(state, :remaining_deck, remainder)
    end)
  end
end
