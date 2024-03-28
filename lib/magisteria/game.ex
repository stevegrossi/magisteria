defmodule Magisteria.Game do
  @moduledoc """
  Responsible for all state transitions, which in practice means the rules of the game.
  """

  alias Magisteria.Card

  @starting_hp 30

  def initial_state() do
    %{
      winning_player: nil,
      current_player: 1,
      players: %{
        1 => %{hp: @starting_hp, ai: false},
        2 => %{hp: @starting_hp, ai: false}
      },
      mana: 0,
      might: 0,
      for_purchase: [],
      for_purchase_deck: for_purchase_deck(),
      cards_played: [],
      hands: %{
        1 => [],
        2 => []
      },
      draw_piles: %{
        1 => starting_draw_pile(),
        2 => starting_draw_pile()
      },
      discard_piles: %{
        1 => [],
        2 => []
      },
      required_discards: %{
        1 => 0,
        2 => 0
      }
    }
    |> populate_for_purchase()
  end

  def start(state) do
    start_turn(state)
  end

  def play_all_cards(state) do
    Enum.reduce_while(1..100, state, fn _i, state ->
      if state.hands[state.current_player] == [] do
        {:halt, state}
      else
        {:cont, play_card(state, 0)}
      end
    end)
  end

  def play_card(state, index) do
    {card, remaining_hand} = List.pop_at(state.hands[state.current_player], index)

    card =
      case card do
        %{element: nil} -> card
        %{element: _} -> Map.put(card, :affinity_applied, false)
      end

    state
    |> Map.update!(:cards_played, &(&1 ++ [card]))
    |> put_in([:hands, state.current_player], remaining_hand)
    |> apply_card_effects(card)
    |> apply_affinities()
  end

  def discard(state, index) do
    {card, remaining_hand} = List.pop_at(state.hands[state.current_player], index)

    state
    |> update_in([:discard_piles, state.current_player], &(&1 ++ [card]))
    |> update_in([:required_discards, state.current_player], &(&1 - 1))
    |> put_in([:hands, state.current_player], remaining_hand)
  end

  def purchase_card(state, index) do
    {card, remaining_for_purchase} = List.pop_at(state.for_purchase, index)

    if card.cost <= state.mana do
      state
      |> Map.update!(:mana, &(&1 - card.cost))
      |> update_in([:discard_piles, state.current_player], &(&1 ++ [card]))
      |> Map.put(:for_purchase, remaining_for_purchase)
      |> refill_for_purchase()
    else
      state
    end
  end

  def attack(state) do
    state
    |> Map.put(:might, 0)
    |> update_in([:players, other_player(state), :hp], &(&1 - state.might))
    |> check_for_winner()
  end

  def end_turn(state) do
    state
    |> discard_cards_played()
    |> Map.merge(%{
      current_player: other_player(state),
      mana: 0,
      might: 0
    })
    |> start_turn()
  end

  # PRIVATE

  defp for_purchase_deck() do
    Card.all()
    |> List.duplicate(4)
    |> List.flatten()
    |> Enum.shuffle()
  end

  defp refill_for_purchase(state) do
    {card, for_purchase_deck} = List.pop_at(state.for_purchase_deck, 0)

    state
    |> Map.update!(:for_purchase, &(&1 ++ [card]))
    |> Map.put(:for_purchase_deck, for_purchase_deck)
  end

  defp starting_draw_pile() do
    Enum.shuffle(Card.starting_deck())
  end

  defp populate_for_purchase(state) do
    {for_purchase, for_purchase_deck} = pop_first(state.for_purchase_deck, 5)

    state
    |> Map.put(:for_purchase, for_purchase)
    |> Map.put(:for_purchase_deck, for_purchase_deck)
  end

  defp pop_first(list, count) do
    popped = Enum.take(list, count)
    remaining = Enum.drop(list, count)
    {popped, remaining}
  end

  defp apply_card_effects(state, card, effects \\ :effects) do
    card
    |> Map.get(effects)
    |> Enum.reduce(state, fn effect, state ->
      case effect do
        {:gain_mana, mana} -> Map.update!(state, :mana, &(&1 + mana))
        {:gain_might, might} -> Map.update!(state, :might, &(&1 + might))
        {:gain_hp, hp} -> update_in(state, [:players, state.current_player, :hp], &(&1 + hp))
        {:draw_cards, count} -> draw_cards(state, count)
        {:force_discard, count} -> force_discard(state, count, other_player(state))
        {:self_discard, count} -> force_discard(state, count, state.current_player)
      end
    end)
  end

  defp apply_affinities(state) do
    unlocked_affinities =
      state.cards_played
      |> Enum.frequencies_by(& &1.element)
      |> Enum.filter(fn {_element, frequency} -> frequency > 1 end)
      |> Enum.map(&elem(&1, 0))

    case unlocked_affinities do
      [] ->
        state

      _ ->
        state.cards_played
        |> Enum.with_index()
        |> Enum.filter(fn {card, _index} ->
          not is_nil(card.element) and not card.affinity_applied and
            card.element in unlocked_affinities
        end)
        |> Enum.reduce(state, fn {_card, index}, state -> apply_affinity(state, index) end)
    end
  end

  defp apply_affinity(state, index) do
    card = Enum.at(state.cards_played, index)

    state
    |> apply_card_effects(card, :affinity_effects)
    |> Map.update!(:cards_played, fn cards ->
      List.update_at(cards, index, &%{&1 | affinity_applied: true})
    end)
  end

  defp draw_card(%{current_player: current_player} = state) do
    case state.draw_piles[current_player] do
      [] ->
        state
        |> recycle_discard_pile_to_draw_pile()
        |> draw_card()

      draw_pile ->
        {card, draw_pile} = List.pop_at(draw_pile, 0)

        state
        |> update_in([:hands, current_player], &(&1 ++ [card]))
        |> put_in([:draw_piles, current_player], draw_pile)
    end
  end

  defp draw_cards(state, count) do
    Enum.reduce(1..count, state, fn _, state -> draw_card(state) end)
  end

  defp recycle_discard_pile_to_draw_pile(state) do
    discard_pile = state.discard_piles[state.current_player]

    state
    |> put_in([:discard_piles, state.current_player], [])
    |> put_in([:draw_piles, state.current_player], Enum.shuffle(discard_pile))
  end

  defp force_discard(state, count, player) do
    update_in(state, [:required_discards, player], &(&1 + count))
  end

  defp other_player(%{current_player: 1}), do: 2
  defp other_player(%{current_player: 2}), do: 1

  defp check_for_winner(state) do
    defeated_player = for {num, player} <- state.players, player.hp <= 0, do: num

    case defeated_player do
      [1] -> Map.put(state, :winning_player, 2)
      [2] -> Map.put(state, :winning_player, 1)
      [] -> state
    end
  end

  defp discard_cards_played(state) do
    state
    |> update_in([:discard_piles, state.current_player], &(&1 ++ state.cards_played))
    |> Map.put(:cards_played, [])
  end

  defp start_turn(state) do
    state
    |> draw_cards(5)
  end
end
