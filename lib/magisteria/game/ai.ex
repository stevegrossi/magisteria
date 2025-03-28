defmodule Magisteria.Game.AI do
  @moduledoc """
  Handles taking computer-controlled turns.
  """

  alias Magisteria.Game

  def take_action(state) do
    cond do
      must_discard?(state) -> discard_cards(state)
      has_unplayed_cards?(state) -> Game.play_all_cards(state)
      can_purchase_spells?(state) -> purchase_biggest_spell(state)
      can_attack?(state) -> attack_opponent(state)
      true -> Game.end_turn(state)
    end
  end

  defp must_discard?(state) do
    state.required_discards[state.current_player] > 0
  end

  defp has_unplayed_cards?(state) do
    state.hands[state.current_player] != []
  end

  defp can_purchase_spells?(state) do
    Enum.any?(state.market, &(&1.cost <= state.mana))
  end

  defp can_attack?(state) do
    state.might > 0
  end

  defp discard_cards(state) do
    lowest_cost =
      state.hands[state.current_player]
      |> Enum.map(& &1.cost)
      |> Enum.min()

    index =
      Enum.find_index(
        state.hands[state.current_player],
        &(is_nil(&1.cost) or &1.cost == lowest_cost)
      )

    Game.discard(state, index)
  end

  defp purchase_biggest_spell(state) do
    highest_cost =
      state.market
      |> Enum.map(& &1.cost)
      |> Enum.filter(&(&1 <= state.mana))
      |> Enum.max()

    index = Enum.find_index(state.market, &(&1.cost == highest_cost))

    Game.purchase_card(state, index)
  end

  defp attack_opponent(state) do
    Game.attack(state)
  end
end
