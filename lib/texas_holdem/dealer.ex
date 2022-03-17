defmodule TexasHoldem.Dealer do
  @moduledoc "GenServer responsible for dealing out cards"

  @clubs ~w[cA cK cQ cJ c10 c9 c8 c7 c6 c5 c4 c3 c2]a
  @diamonds ~w[dA dK dQ dJ d10 d9 d8 d7 d6 d5 d4 d3 d2]a
  @hearts ~w[hA hK hQ hJ h10 h9 h8 h7 h6 h5 h4 h3 h2]a
  @spades ~w[sA sK sQ sJ s10 s9 s8 s7 s6 s5 s4 s3 s2]a
  @deck @clubs ++ @diamonds ++ @hearts ++ @spades

  use GenServer

  #
  # section Client API
  #

  def start_link() do
    GenServer.start_link(__MODULE__, :ok)
  end

  def deal(server, n) do
    GenServer.call(server, {:deal, n})
  end

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
    # Put our shuffled deck into the GenServer state
    {:ok, shuffled_deck}
  end

  def handle_call({:deal, n}, _from, deck) do
    state = deal_n_cards(n, deck)
    {:reply, state.dealt_cards, state.remaining_deck}
  end

  def handle_cast(:shuffle, _deck) do
    deck = shuffle_and_cut_deck()
    {:noreply, deck}
  end

  def shuffle_and_cut_deck() do
    # Shuffle up our deck using the seeded PRNG
    shuffled_deck = Enum.shuffle(@deck)

    # Simulate cutting the deck at a random location
    cut_size = :rand.uniform(51)
    %{dealt_cards: first_half, remaining_deck: second_half} = deal_n_cards(cut_size, shuffled_deck)
    second_half ++ first_half
  end

  def deal_n_cards(n, deck) do
    state = %{dealt_cards: [], remaining_deck: deck}
    Enum.reduce(1..n, state, fn(_, state) ->
      {card, remainder} = List.pop_at(state.remaining_deck, 0)
      all_dealt_cards = state.dealt_cards ++ [card]
      state = Map.put(state, :dealt_cards, all_dealt_cards)
      Map.put(state, :remaining_deck, remainder)
    end)
  end

end