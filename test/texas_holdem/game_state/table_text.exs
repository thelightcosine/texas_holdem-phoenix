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
end
