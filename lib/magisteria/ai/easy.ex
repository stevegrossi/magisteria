defmodule Magisteria.AI.Easy do
  def take_action(state) do
    cond do
      unplayed_cards?(state) -> play_card(state)
    end
  end

  defp unplayed_cards?(state) do
    state.hands[state.current_player] != []
  end

  defp play_card(_state) do
    %{type: "play_card", index: 0}
  end
end
