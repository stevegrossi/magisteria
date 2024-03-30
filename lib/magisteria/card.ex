defmodule Magisteria.Card do
  @enforce_keys ~w[name effects affinity_effects cost element shield]a
  defstruct name: nil,
            effects: [],
            affinity_effects: [],
            affinity_applied: false,
            cost: nil,
            element: nil,
            shield: nil

  def drawable() do
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
      new(:evocate),
      new(:skeleton),
      new(:frost_giant),
      new(:vines),
      new(:fire_imp)
    ]
  end

  def all() do
    starting_deck()
    |> Enum.uniq()
    |> Kernel.++(drawable())
  end

  def starting_deck() do
    List.duplicate(new(:concentrate), 7) ++
      List.duplicate(new(:arcane_bolt), 3)
  end

  def reset_affinity(%{element: nil} = card), do: card
  def reset_affinity(%{element: _} = card), do: %{card | affinity_applied: false}

  def new(%{} = attrs), do: __MODULE__.__struct__(attrs)

  def new(:concentrate) do
    new(%{
      name: "Concentrate",
      effects: [gain_mana: 1],
      affinity_effects: [],
      cost: nil,
      element: nil,
      shield: nil
    })
  end

  def new(:arcane_bolt) do
    new(%{
      name: "Arcane Bolt",
      effects: [gain_might: 1],
      affinity_effects: [],
      cost: nil,
      element: nil,
      shield: nil
    })
  end

  def new(:amplify) do
    new(%{
      name: "Amplify",
      effects: [gain_mana: 2],
      affinity_effects: [],
      cost: 1,
      element: nil,
      shield: nil
    })
  end

  def new(:poison_bolt) do
    new(%{
      name: "Poison Bolt",
      effects: [gain_might: 2],
      affinity_effects: [gain_might: 2],
      cost: 2,
      element: :earth,
      shield: nil
    })
  end

  def new(:heal) do
    new(%{
      name: "Heal",
      effects: [gain_hp: 2],
      affinity_effects: [gain_hp: 2],
      cost: 2,
      element: :earth,
      shield: nil
    })
  end

  def new(:regrowth) do
    new(%{
      name: "Regrowth",
      effects: [draw_cards: 1, self_discard: 1],
      affinity_effects: [gain_hp: 2],
      cost: 2,
      element: :earth,
      shield: nil
    })
  end

  def new(:flamestrike) do
    new(%{
      name: "Flamestrike",
      effects: [gain_might: 2],
      affinity_effects: [gain_might: 2],
      cost: 2,
      element: :fire,
      shield: nil
    })
  end

  def new(:meteor) do
    new(%{
      name: "Meteor",
      effects: [gain_might: 5],
      affinity_effects: [gain_might: 2],
      cost: 4,
      element: :fire,
      shield: nil
    })
  end

  def new(:shadowbolt) do
    new(%{
      name: "Shadowbolt",
      effects: [gain_might: 2],
      affinity_effects: [gain_might: 2],
      cost: 2,
      element: :shadow,
      shield: nil
    })
  end

  def new(:nullify) do
    new(%{
      name: "Nullify",
      effects: [force_discard: 1],
      affinity_effects: [gain_might: 2],
      cost: 2,
      element: :shadow,
      shield: nil
    })
  end

  def new(:life_drain) do
    new(%{
      name: "Life Drain",
      effects: [gain_might: 2, gain_hp: 2],
      affinity_effects: [draw_cards: 1],
      cost: 4,
      element: :shadow,
      shield: nil
    })
  end

  def new(:water_bolt) do
    new(%{
      name: "Water Bolt",
      effects: [gain_might: 2],
      affinity_effects: [gain_might: 2],
      cost: 2,
      element: :water,
      shield: nil
    })
  end

  def new(:mana_drain) do
    new(%{
      name: "Mana Drain",
      effects: [gain_might: 2, gain_mana: 2],
      affinity_effects: [draw_cards: 1],
      cost: 3,
      element: :water,
      shield: nil
    })
  end

  def new(:evocate) do
    new(%{
      name: "Evocate",
      effects: [gain_mana: 2, draw_cards: 1],
      affinity_effects: [gain_mana: 2],
      cost: 3,
      element: :water,
      shield: nil
    })
  end

  def new(:skeleton) do
    new(%{
      name: "Skeleton",
      effects: [gain_might: 2],
      affinity_effects: [gain_might: 2],
      cost: 2,
      element: :shadow,
      shield: 3
    })
  end

  def new(:frost_giant) do
    new(%{
      name: "Frost Giant",
      effects: [gain_might: 4],
      affinity_effects: [force_discard: 1],
      cost: 4,
      element: :water,
      shield: 5
    })
  end

  def new(:vines) do
    new(%{
      name: "Vines",
      effects: [gain_might: 2],
      affinity_effects: [gain_might: 2],
      cost: 2,
      element: :earth,
      shield: 3
    })
  end

  def new(:fire_imp) do
    new(%{
      name: "Fire Imp",
      effects: [gain_might: 4],
      affinity_effects: [gain_might: 2],
      cost: 4,
      element: :fire,
      shield: 4
    })
  end
end
