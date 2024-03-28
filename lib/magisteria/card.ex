defmodule Magisteria.Card do
  @enforce_keys ~w[name effects affinity_effects cost element]a
  defstruct ~w[name effects affinity_effects affinity_applied cost element]a

  def all() do
    [
      new(:amplify),
      new(:poison_bolt),
      new(:heal),
      new(:regrowth),
      new(:flamestrike),
      new(:meteor),
      new(:shadowbolt),
      new(:life_drain),
      new(:nullify),
      new(:water_bolt),
      new(:mana_drain),
      new(:evocate)
    ]
  end

  def starting_deck() do
    List.duplicate(new(:concentrate), 7) ++
      List.duplicate(new(:arcane_bolt), 3)
  end

  def new(%{} = attrs) do
    __MODULE__.__struct__(attrs)
  end

  def new(:concentrate) do
    new(%{
      name: "Concentrate",
      effects: [{:gain_mana, 1}],
      affinity_effects: [],
      cost: nil,
      element: nil
    })
  end

  def new(:arcane_bolt) do
    new(%{
      name: "Arcane Bolt",
      effects: [{:gain_might, 1}],
      affinity_effects: [],
      cost: nil,
      element: nil
    })
  end

  def new(:amplify) do
    new(%{
      name: "Amplify",
      effects: [{:gain_mana, 2}],
      affinity_effects: [],
      cost: 1,
      element: nil
    })
  end

  def new(:poison_bolt) do
    new(%{
      name: "Poison Bolt",
      effects: [{:gain_might, 2}],
      affinity_effects: [{:gain_might, 2}],
      cost: 2,
      element: :earth
    })
  end

  def new(:heal) do
    new(%{
      name: "Heal",
      effects: [{:gain_hp, 2}],
      affinity_effects: [{:gain_hp, 2}],
      cost: 2,
      element: :earth
    })
  end

  def new(:regrowth) do
    new(%{
      name: "Regrowth",
      effects: [{:draw_cards, 1}, {:self_discard, 1}],
      affinity_effects: [{:gain_hp, 2}],
      cost: 2,
      element: :earth
    })
  end

  def new(:flamestrike) do
    new(%{
      name: "Flamestrike",
      effects: [{:gain_might, 2}],
      affinity_effects: [{:gain_might, 2}],
      cost: 2,
      element: :fire
    })
  end

  def new(:meteor) do
    new(%{
      name: "Meteor",
      effects: [{:gain_might, 5}],
      affinity_effects: [{:gain_might, 2}],
      cost: 4,
      element: :fire
    })
  end

  def new(:shadowbolt) do
    new(%{
      name: "Shadowbolt",
      effects: [{:gain_might, 2}],
      affinity_effects: [{:gain_might, 2}],
      cost: 2,
      element: :shadow
    })
  end

  def new(:nullify) do
    new(%{
      name: "Nullify",
      effects: [{:force_discard, 1}],
      affinity_effects: [{:gain_might, 2}],
      cost: 2,
      element: :shadow
    })
  end

  def new(:life_drain) do
    new(%{
      name: "Life Drain",
      effects: [{:gain_might, 2}, {:gain_hp, 2}],
      affinity_effects: [{:draw_cards, 1}],
      cost: 4,
      element: :shadow
    })
  end

  def new(:water_bolt) do
    new(%{
      name: "Water Bolt",
      effects: [{:gain_might, 2}],
      affinity_effects: [{:gain_might, 2}],
      cost: 2,
      element: :water
    })
  end

  def new(:mana_drain) do
    new(%{
      name: "Mana Drain",
      effects: [{:gain_might, 2}, {:gain_mana, 2}],
      affinity_effects: [{:draw_cards, 1}],
      cost: 3,
      element: :water
    })
  end

  def new(:evocate) do
    new(%{
      name: "Evocate",
      effects: [{:gain_mana, 2}, {:draw_cards, 1}],
      affinity_effects: [{:gain_mana, 2}],
      cost: 3,
      element: :water
    })
  end
end
