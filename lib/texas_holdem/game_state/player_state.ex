defmodule TexasHoldem.GameState.PlayerState do
  defstruct [:name, :stack, hole_cards: [], in_hand: true, sitting_out: false]

  @type t :: %__MODULE__{
          name: String.t(),
          stack: integer(),
          hole_cards: [atom()],
          in_hand: boolean(),
          sitting_out: boolean()
        }
end
