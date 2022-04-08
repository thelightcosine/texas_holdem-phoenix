defmodule TexasHoldem.GameState.TableTest do
  use ExUnit.Case

  alias TexasHoldem.GameState.{PlayerState, Table}

  describe "valid_seat?/2" do
    test " returns true if the seat is allowed by max_players" do
      fake_state = %{max_players: 2}
      assert Table.valid_seat?(:seat2, fake_state)
    end

    test "returns false if seat is not allowed by max_players" do
      fake_state = %{max_players: 2}
      refute Table.valid_seat?(:seat3, fake_state)
    end
  end

  describe "available_seats/1" do
    test "returns a List of all empty seats" do
      fake_state = %{
        max_players: 9,
        seats: %{
          seat1: nil,
          seat2: %{},
          seat3: nil
        }
      }

      assert Table.available_seats(fake_state) == [:seat1, :seat3]
    end

    test "does not return seats higher than max_players" do
      fake_state = %{
        max_players: 2,
        seats: %{
          seat1: nil,
          seat2: %{},
          seat3: nil
        }
      }

      assert Table.available_seats(fake_state) == [:seat1]
    end
  end

  describe "random_open_seat/1" do
    test "returns one randomly selected open seat at the table" do
      fake_state = %{
        max_players: 9,
        seats: %{
          seat1: nil,
          seat2: %{},
          seat3: nil
        }
      }

      assigned_seat = Table.random_open_seat(fake_state)
      assert Enum.member?([:seat1, :seat3], assigned_seat)
    end
  end

  describe "seat_player/2" do
    test "adds the PlayerState to a randomly selected open seat" do
      player = %PlayerState{name: "Doyle Brunson", stack: 100_000}
      {:ok, server} = Table.start_link()
      seat = Table.seat_player(server, player)
      player_state = Table.get_player_info(server, seat)
      assert player_state.name == "Doyle Brunson"
      assert player_state.stack == 100_000
    end
  end

  describe "active_players/1" do
    test "returns an ordered list of active players in the hand" do
      player1 = %PlayerState{
        name: "Doyle Brunson",
        stack: 100_000,
        in_hand: true,
        sitting_out: false
      }

      player2 = %PlayerState{
        name: "Phil Ivey",
        stack: 100_000,
        in_hand: false,
        sitting_out: false
      }

      player3 = %PlayerState{
        name: "Phil Hellmuth",
        stack: 100_000,
        in_hand: false,
        sitting_out: true
      }

      player4 = %PlayerState{name: "Tony G", stack: 100_000, in_hand: true, sitting_out: false}

      player5 = %PlayerState{
        name: "Antonio Esfandiari",
        stack: 100_000,
        in_hand: true,
        sitting_out: false
      }

      player6 = %PlayerState{
        name: "Ike Haxton",
        stack: 100_000,
        in_hand: false,
        sitting_out: false
      }

      player7 = %PlayerState{
        name: "Daniel Negreanu",
        stack: 100_000,
        in_hand: true,
        sitting_out: false
      }

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
        dealer: nil,
        pot: 0,
        bb: 0,
        ante: 0,
        button: :seat4,
        max_players: max_players,
        seats: %{
          seat1: player1,
          seat2: player2,
          seat3: player3,
          seat4: player4,
          seat5: player5,
          seat6: player6,
          seat7: player7,
          seat8: nil,
          seat9: nil
        },
        seat_order: seat_order
      }

      assert Table.active_players(state) == [:seat4, :seat5, :seat7, :seat1]
    end
  end

  describe "order_seats/2" do
    setup do
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
        dealer: nil,
        pot: 0,
        bb: 0,
        ante: 0,
        button: :seat3,
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

      %{table_state: state}
    end

    test "orders the given set of seats based on the button", %{table_state: state} do
      seats = [:seat1, :seat3, :seat5, :seat7, :seat8]
      assert Table.order_seats(seats, state) == [:seat5, :seat7, :seat8, :seat1, :seat3]
    end

    test "works even if the button is not in the seats to be ordered", %{table_state: state} do
      seats = [:seat1, :seat5, :seat7, :seat8]
      assert Table.order_seats(seats, state) == [:seat5, :seat7, :seat8, :seat1]
    end
  end
end
