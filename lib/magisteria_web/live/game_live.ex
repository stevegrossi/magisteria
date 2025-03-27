defmodule MagisteriaWeb.GameLive do
  @moduledoc "The game!"

  use MagisteriaWeb, :live_view

  alias Magisteria.Game
  alias Magisteria.Card

  @impl true
  def mount(_params, _session, socket) do
    state =
      if connected?(socket) do
        Game.initial_state() |> Game.start()
      else
        %{}
      end

    {:ok, assign(socket, state: state)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <%= if connected?(@socket) do %>
      <header class="Header">
        <h1 class="Logo">MagISTerIA</h1>
        <div
          :for={{player_num, player} <- @state.players}
          class={
            if player_num == @state.current_player,
              do: "Player Player--#{player_num} Player--active",
              else: "Player Player--#{player_num}"
          }
        >
          <div class="Player-name">
            Player {player_num} {if player.ai, do: " 🤖"}
          </div>
          <div class="Player-hp">{player.hp}</div>
          <div :if={@state.required_discards[player_num] != 0} class="Player-discards">
            ⬇️ {@state.required_discards[player_num]}
          </div>
        </div>
      </header>
      <%= if @state.winning_player do %>
        <div class="Winner">
          Player {@state.winning_player} wins!
        </div>
      <% else %>
        <section class="SpellBoard">
          <ul class="CardList">
            <li
              :for={{card, index} <- Enum.with_index(@state.market)}
              phx-click="purchase_card"
              phx-value-index={index}
            >
              <.card card={card} obtainable?={card.cost <= @state.mana} />
            </li>
            <li class="CardBack CardList-right">
              <span class="CardCount">{length(@state.market_deck)}</span>
            </li>
          </ul>
          <div class="flex flex-col">
            <div class="Resources">
              <div class="Resources-resource">
                <div class="Resources-title">Mana</div>
                {resource_icon(:mana)}
                <div class="Resources-count">
                  {@state.mana}
                </div>
              </div>
              <div class="Resources-resource">
                <div class="Resources-title">Might</div>
                {resource_icon(:might)}
                <div class="Resources-count">
                  {@state.might}
                </div>
              </div>
            </div>
            <div class="flex items-stretch">
              <button
                :if={not discard_required?(@state) and @state.hands[@state.current_player] != []}
                class="ActionButton"
                phx-click="play_all"
              >
                Play All
              </button>
              <button
                :if={@state.might > 0}
                class="ActionButton ActionButton--might"
                phx-click="attack"
              >
                Attack
              </button>
              <button :if={can_end_turn?(@state)} class="ActionButton" phx-click="end_turn">
                End Turn
              </button>
            </div>
          </div>
        </section>
        <section class="PlayBoard">
          <ul class="CardList mr-auto">
            <li :for={card <- @state.summons[@state.current_player]}><.card card={card} /></li>
          </ul>
          <ul class="CardList">
            <li :for={card <- @state.cards_played}><.card card={card} /></li>
          </ul>
          <ul class="CardList ml-auto">
            <li
              :for={{card, index} <- Enum.with_index(@state.summons[Game.other_player(@state)])}
              phx-click={if @state.might >= card.shield, do: "attack_summon"}
              phx-value-index={index}
            >
              <.card card={card} attackable?={@state.might >= card.shield} />
            </li>
          </ul>
        </section>
        <section class="Hand">
          <section :if={discard_required?(@state)} class="RequiredAction">
            <h2>
              Discard {pluralize(
                "1 card",
                "%{count} cards",
                @state.required_discards[@state.current_player]
              )}:
            </h2>
          </section>
          <ul class="CardList">
            <li
              :for={{card, index} <- Enum.with_index(@state.hands[@state.current_player])}
              phx-click={if discard_required?(@state), do: "discard", else: "play_card"}
              phx-value-index={index}
            >
              <.card card={card} />
            </li>
          </ul>
          <ul class="StackedCardList">
            <li :for={card <- @state.discard_piles[@state.current_player]}><.card card={card} /></li>
          </ul>
          <div class="CardBack CardList-right">
            <span class="CardCount">{length(@state.draw_piles[@state.current_player])}</span>
          </div>
        </section>
      <% end %>
    <% else %>
      Connecting...
    <% end %>
    """
  end

  attr :card, Card, required: true
  attr :obtainable?, :boolean, default: false
  attr :attackable?, :boolean, default: false

  defp card(assigns) do
    ~H"""
    <div class={[
      "Card Card--#{@card.element}",
      @obtainable? && "Card--obtainable",
      @attackable? && "Card--attackable"
    ]}>
      <div class="Card-name">{@card.name}</div>
      <div :if={@card.cost} class="Card-cost">
        {resource_icon(:mana)}
        <span class="Card-costNumber">{@card.cost}</span>
      </div>
      <div class="Card-text">{card_text(@card.effects)}</div>
      <div :if={@card.affinity_effects != []} class="Card-affinity">
        <strong>Affinity:</strong>
        {card_text(@card.affinity_effects)}
        {if @card.affinity_applied, do: "✅"}
      </div>
      <div :if={@card.shield} class="Card-shield">
        🛡️ <span class="Card-shieldNumber">{@card.shield}</span>
      </div>
    </div>
    """
  end

  defp card_text(effects) do
    effects
    |> Enum.map(fn
      {:gain_mana, mana} -> "+#{mana} 🔵"
      {:gain_might, might} -> "+#{might} 🔴"
      {:gain_hp, hp} -> "+#{hp} 🟢"
      {:draw_cards, count} -> "Draw #{pluralize("1 card", "#{count} cards", count)}"
      {:force_discard, count} -> "Opponent discards #{count}"
      {:self_discard, count} -> "Discard #{pluralize("1 card", "#{count} cards", count)}"
    end)
    |> Enum.join(", ")
  end

  @impl true
  def handle_event("play_all", _params, socket) do
    new_state = Game.play_all_cards(socket.assigns.state)

    {:noreply, assign(socket, state: new_state)}
  end

  def handle_event("play_card", %{"index" => index}, socket) do
    new_state = Game.play_card(socket.assigns.state, String.to_integer(index))

    {:noreply, assign(socket, state: new_state)}
  end

  def handle_event("discard", %{"index" => index}, socket) do
    new_state = Game.discard(socket.assigns.state, String.to_integer(index))

    {:noreply, assign(socket, state: new_state)}
  end

  def handle_event("purchase_card", %{"index" => index}, socket) do
    new_state = Game.purchase_card(socket.assigns.state, String.to_integer(index))

    {:noreply, assign(socket, state: new_state)}
  end

  def handle_event("attack", _params, socket) do
    new_state = Game.attack(socket.assigns.state)

    {:noreply, assign(socket, state: new_state)}
  end

  def handle_event("attack_summon", %{"index" => index}, socket) do
    new_state = Game.attack_summon(socket.assigns.state, String.to_integer(index))
    {:noreply, assign(socket, state: new_state)}
  end

  def handle_event("end_turn", _params, socket) do
    new_state = Game.end_turn(socket.assigns.state)
    maybe_schedule_ai_action(new_state)

    {:noreply, assign(socket, state: new_state)}
  end

  @impl true
  def handle_info(:take_ai_action, socket) do
    new_state = Magisteria.Game.AI.take_action(socket.assigns.state)
    maybe_schedule_ai_action(new_state)

    {:noreply, assign(socket, state: new_state)}
  end

  defp maybe_schedule_ai_action(state) do
    if state.players[state.current_player].ai do
      Process.send_after(self(), :take_ai_action, 1_000)
    end
  end

  defp discard_required?(state) do
    state.required_discards[state.current_player] > 0
  end

  defp can_end_turn?(state) do
    state.might == 0 && state.hands[state.current_player] == []
  end

  defp resource_icon(:mana) do
    assigns = %{}

    ~H"""
    <svg
      class="Mana"
      version="1.1"
      xmlns="http://www.w3.org/2000/svg"
      width="32"
      height="32"
      viewBox="0 0 32 32"
    >
      <path d="M3.898 15.076c-0.433-3.154 0.343-6.462 2.526-9.115 3.647-4.432 10.484-5.531 15.020-1.638 3.663 3.145 4.526 8.975 1.092 12.732-2.646 2.894-7.445 3.552-10.411 0.546-1.020-1.033-1.672-2.431-1.741-3.981l-0-0.013c-0.062-1.487 0.486-3.095 1.809-4.164 0.84-0.68 1.9-1.011 3.004-0.956s2.377 0.666 2.935 1.912c0.41 0.914 0.267 1.528-0.068 2.287-0.168 0.379-0.44 0.857-1.058 1.126s-1.399 0.111-1.878-0.205c-0.763-0.472-0.91-1.52-0.307-2.184-0.293 0.045-0.65 0.102-0.82 0.239-0.57 0.461-0.78 1.064-0.75 1.809s0.394 1.582 0.922 2.116c1.695 1.717 4.624 1.297 6.246-0.478 2.254-2.465 1.655-6.449-0.853-8.602-3.232-2.774-8.284-1.986-10.957 1.263-3.29 3.998-2.256 10.090 1.74 13.279 2.667 2.127 6.327 2.812 9.626 1.877 0.118-0.035 0.253-0.055 0.393-0.055 0.794 0 1.437 0.643 1.437 1.437 0 0.654-0.437 1.206-1.034 1.38l-0.010 0.003c-4.175 1.183-8.755 0.348-12.186-2.39-2.486-2.003-4.198-4.879-4.669-8.156l-0.008-0.069z">
      </path>
    </svg>
    """
  end

  defp resource_icon(:might) do
    assigns = %{}

    ~H"""
    <svg
      class="Might"
      viewBox="0 0 700 700"
      xmlns="http://www.w3.org/2000/svg"
      xmlns:xlink="http://www.w3.org/1999/xlink"
    >
      <defs>
        <symbol id="a" overflow="visible"><path d="M.031 0H0v-.031h.031-.015V0H.03v-.016z" /></symbol>
        <symbol id="b" overflow="visible"><path d="M.016-.016V0H0v-.031h.016v.015-.015z" /></symbol>
        <symbol id="c" overflow="visible">
          <path d="M.031-.016H.016V0C.023 0 .03-.004.03-.016V0H0v-.016L.016-.03v.015H.03z" />
        </symbol>
        <symbol id="d" overflow="visible">
          <path d="M.016-.016V0v-.016zm.015 0V0H0v-.016h.016H0V-.03h.016v.015H.03z" />
        </symbol>
        <symbol id="e" overflow="visible"><path d="M.016-.031V0H0v-.031z" /></symbol>
        <symbol id="f" overflow="visible">
          <path d="M.016-.016V-.03H.03V0H0v-.016L.016-.03v.015zm0 .016v-.016V0z" />
        </symbol>
        <symbol id="g" overflow="visible">
          <path d="M.016 0v-.016V0zm0-.016V-.03c.007 0 .015.008.015.015V0H0v-.031h.016z" />
        </symbol>
        <symbol id="h" overflow="visible">
          <path d="M0-.031h.016v.015-.015H.03L.016 0v.016H0V0h.016z" />
        </symbol>
        <symbol id="i" overflow="visible">
          <path d="M.016-.031V0H.03v-.016A.017.017 0 0 0 .016-.03zm0 0H.03V0H0v-.031h.016z" />
        </symbol>
        <symbol id="j" overflow="visible"><path d="M0-.031h.016V0H0z" /></symbol>
        <symbol id="k" overflow="visible">
          <path d="M.031-.016V0H.016v-.016V0H0v-.031h.016v.015-.015c.007 0 .015.008.015.015z" />
        </symbol>
        <symbol id="l" overflow="visible">
          <path d="M0-.031h.031v.015H.016V0H0zm.016 0v.015-.015z" />
        </symbol>
        <symbol id="m" overflow="visible">
          <path d="M.031-.031v.015H.016C.023-.016.03-.008.03 0H0h.016v-.016H0L.016-.03H.03z" />
        </symbol>
        <symbol id="n" overflow="visible">
          <path d="M.016-.016V0v-.016zm0-.015v.015H.03C.031-.004.023 0 .016 0H0v-.016L.016-.03z" />
        </symbol>
        <symbol id="o" overflow="visible"><path d="M0-.031h.016v.015-.015H.03L.016 0z" /></symbol>
        <symbol id="p" overflow="visible">
          <path d="M0-.031h.016v.015-.015H.03l-.015.015L.03 0H.016v-.016V0H0z" />
        </symbol>
        <symbol id="q" overflow="visible"><path d="M.016-.031V0H0v-.031h.016z" /></symbol>
        <symbol id="r" overflow="visible">
          <path d="M.031-.016V-.03c.008 0 .016.008.016.015V0H.03v-.016V0H.016v-.016V0H0v-.031h.016v.015-.015.015H.03z" />
        </symbol>
        <symbol id="s" overflow="visible">
          <path d="M.031-.016V0H.016v-.016V0H0v-.031h.016v.015-.015c.007 0 .015.008.015.015z" />
        </symbol>
        <symbol id="t" overflow="visible">
          <path d="M0-.031h.016l.015.015V-.03 0L.016-.016V0H0z" />
        </symbol>
        <symbol id="u" overflow="visible">
          <path d="M0-.016V-.03h.016V0v-.031H.03V0H0v-.016z" />
        </symbol>
        <symbol id="v" overflow="visible"><path d="M0-.031h.016V0H0v.016zm0 0h.016z" /></symbol>
        <symbol id="w" overflow="visible">
          <path d="M.031-.031v.015H.016V0H.03 0v-.016L.016-.03H.03z" />
        </symbol>
      </defs>
      <path d="M595.88 188.47a3.635 3.635 0 0 1 4.844 1.738 3.635 3.635 0 0 1-1.739 4.844l-121.07 56.914c2.317.14 4.57.426 6.739.867 5.277 1.078 10.074 3.086 14.008 6.133 4.027 3.121 7.09 7.285 8.77 12.594 1.284 4.063 1.75 8.77 1.198 14.16l93.668-14.172.012-.004h.004l21.668-3.277v7.371l-20.594 3.117c-11.035 1.672-19.91 5.434-27.059 11-7.113 5.54-12.594 12.918-16.852 21.844l.004.004c-14.5 36.41-30.668 38.996-46.836 41.586-.871.14-1.742.277-2.613.426 4.304 2.082 8.797 3.98 13.508 5.527 12.316 4.051 16.523 7.957 23.797 14.715 1.426 1.324.968.918 1.976 1.844 6.051 5.574 46.238 13.418 74.668 18.707v7.406c-29.27-5.437-72.012-13.773-79.602-20.766-2.398-2.21-1.867-1.719-2.015-1.855-6.524-6.063-10.297-9.567-21.105-13.121-14.45-4.75-23.125-10.23-35.461-17.664-15.254-9.192-28.156-16.961-40.887-12.355l138.79 90.066a3.639 3.639 0 0 1 1.07 5.03 3.639 3.639 0 0 1-5.031 1.071L411.3 322.9l9.324 39.078 91.062 125.9a3.638 3.638 0 0 1-.82 5.082 3.638 3.638 0 0 1-5.082-.82l-87.16-119.96-7.594 15 22.168 37.082c.078.113.148.234.21.355l35.985 60.195a3.636 3.636 0 0 1-1.274 4.985 3.637 3.637 0 0 1-4.984-1.274l-3.473-5.808c-6.007-10.051-11.922-19.941-17.84-29.844l-14.477-24.22-53.27-47.5-51.039 172.82h-7.578l53.207-180.16c.012-.046.024-.097.035-.148l7.7-28.383-11.051-15.965-61.04 81.781c-.03.043-.058.082-.09.121l-81.968 109.82a3.64 3.64 0 0 1-5.836-4.351l79.906-107.06c-.078-.07-.153-.14-.23-.211-5.227-4.844-7.133-10.426-6.954-15.941.172-5.293 2.324-10.414 5.278-14.648a35.506 35.506 0 0 1 2.996-3.73 36.436 36.436 0 0 0 2.629-3.192c3.132-4.258 5.804-9.621 6.632-14.828.703-4.43.012-8.746-3.066-12.008l-148.21 96.199a3.64 3.64 0 1 1-3.957-6.113l150.39-97.61c.082-.058.164-.113.25-.163l29.766-19.32-6.102-9.782-57.914 27.645c-1.82.868-4 .098-4.87-1.722-.868-1.82-.099-4 1.722-4.871l23.816-11.367-4.652-10.5-79.02 21.465a5.502 5.502 0 0 1-.34.093c-14.75 4.008-17.75 4.395-14.57 13.633a3.64 3.64 0 0 1-3.148 4.656l-75.985 7.114a3.638 3.638 0 0 1-1.297-7.133l91.805-24.938 25.54-44.375-150.8-45.023v-7.61l114.9 34.306 47.433-18.5a3.655 3.655 0 0 1 2.575-.036l.003-.007 72.38 26.227 5.265-11.273-132.74-68.43a3.648 3.648 0 0 1-1.562-4.91 3.648 3.648 0 0 1 4.91-1.563l151.28 77.988 5.148-9.453-145.35-160.53a3.643 3.643 0 0 1 .27-5.14c1.496-1.345 4.148-1.302 5.492.195l33.012 36.46c7.328 8.094 13.988 15.91 20.926 23.575l28.637 31.629c.105-.094.215-.184.336-.27l31.359-22.449a3.65 3.65 0 0 1 5.101.484l12.875 15.391 24.742-18.508-22.23-144.53h7.364l22.355 145.34c.039.164.062.332.078.497l7 45.512a3.621 3.621 0 0 1 1.742.406l22.566 11.68a3.645 3.645 0 0 1 1.938 3.715l-2.102 26.699 2.05 1.66 129.27-165.25a3.647 3.647 0 0 1 5.731 4.511l-92.23 117.9 10.227 9.844 67.227-68.996a2.273 2.273 0 0 1 3.22-.043c.901.875.92 2.32.042 3.22l-40.578 41.647c4.188.192 8.277.797 12.195 1.79 5.383 1.366 10.484 3.472 15.117 6.241 4.227 2.524 7.484 5.473 10.574 8.274 7.742 7.008 14.344 12.984 33 5.777.098-.039.195-.066.293-.094l38.016-17.87zm-142.29 23.316-9.871-9.5-36.496 46.656-.004-.004-.035.047a3.64 3.64 0 0 1-5.121.527l-6.418-5.195a3.635 3.635 0 0 1-1.332-3.105l2.078-26.391-17.527-9.075 1.637 10.63a3.637 3.637 0 0 1-3.04 4.152 3.637 3.637 0 0 1-4.152-3.04l-9.039-58.77-24.398 18.25a3.646 3.646 0 0 1-5.023-.636l-12.88-15.395-28.464 20.375 59.18 65.359a3.64 3.64 0 0 1 .562 4.261l-8.05 14.777a3.643 3.643 0 0 1-4.907 1.56l-15.227-7.853-6.465 13.836a3.653 3.653 0 0 1-4.64 2.094l-74.23-26.898-37.45 14.605 31.052 9.27a3.646 3.646 0 0 1 2.113 5.313l-24.188 42.022 73.449-19.953a3.647 3.647 0 0 1 4.547 1.961l5.836 13.168 30.445-14.535.004.012a3.638 3.638 0 0 1 4.66 1.367l9.652 15.473c.012.02.024.035.035.055a3.64 3.64 0 0 1-1.078 5.035l-29.004 18.824c4.11 4.934 5.043 11.02 4.067 17.164-1.028 6.453-4.23 12.949-7.961 18.027a44.16 44.16 0 0 1-3.149 3.828 27.32 27.32 0 0 0-2.37 2.934c-2.223 3.183-3.837 6.945-3.962 10.695-.109 3.406 1.075 6.902 4.293 10.047l61.676-82.637a3.65 3.65 0 0 1 6.086-.105l14.895 21.515-.004.004a3.63 3.63 0 0 1 .516 3.008l-7.555 27.852 38.527 34.355-10.98-18.371a3.636 3.636 0 0 1-.246-3.71l10.184-20.122-7.914-10.895a3.62 3.62 0 0 1-.687-2.012l-1.168-36.312h.003a3.639 3.639 0 0 1 5.617-3.168l28.024 18.188c17.59-9.867 33.156-.488 51.895 10.797 3.363 2.028 6.84 4.121 10.445 6.164 3.863-1.109 7.668-1.722 11.477-2.332 13.734-2.199 27.465-4.402 40.14-34.484 1.563-6.73 1.649-12.117-.14-15.883-2.29-4.828-8.055-7.105-18.285-6.246l-28.199 4.266c-.125.023-.25.043-.375.059l-81.531 12.336v-.008a3.635 3.635 0 0 1-4.156-4.023l3.566-29.978a3.642 3.642 0 0 1 2.078-3.027l22.707-10.676-8.824-12.453a2.278 2.278 0 0 1 .68-3.27l-.004-.003 15.898-9.582-10.875-7.805a2.275 2.275 0 0 1-.301-3.434l9.73-9.988zm-2.148 44.582 1.98-.93c.121-.066.246-.125.375-.175l40.93-19.242a2.16 2.16 0 0 1 .426-.344c11.887-7.477 17.977-13.621 20.715-19.402 3.613-7.633 3.285-15.504-4.219-19.988-4.219-2.52-8.906-4.45-13.898-5.715a56.946 56.946 0 0 0-15.434-1.71h-.031l-33.32 34.194 11.398 8.18c.305.183.566.445.762.77a2.278 2.278 0 0 1-.778 3.128l-16.758 10.102 7.64 10.785a2.3 2.3 0 0 1 .208.352zm-249.34-52.461a2.272 2.272 0 0 1-2.043 4.059l-69.23-34.766a2.272 2.272 0 0 1 2.043-4.059zm44.98 193.23a2.278 2.278 0 0 1 3.18.5 2.278 2.278 0 0 1-.5 3.18l-43.966 32.016a2.278 2.278 0 0 1-3.18-.5 2.278 2.278 0 0 1 .5-3.18zm86.25 47.934a2.276 2.276 0 0 1 2.96-1.266 2.276 2.276 0 0 1 1.266 2.961l-17.8 44.102a2.276 2.276 0 0 1-2.606 1.375l-8.328-1.578-26.207 53.273a2.274 2.274 0 0 1-3.043 1.035 2.274 2.274 0 0 1-1.036-3.043l26.926-54.73a2.281 2.281 0 0 1 2.512-1.328l8.258 1.567zm143.23-18.207a2.275 2.275 0 1 1 3.582-2.809l35.078 44.406a2.275 2.275 0 1 1-3.582 2.809zm-20.113-164.81-26.938 12.664-2.782 23.387 74.41-11.258c.77-5.172.48-9.512-.656-13.094-1.21-3.824-3.406-6.816-6.293-9.05-2.98-2.31-6.754-3.86-10.996-4.727-8.055-1.645-17.637-.778-26.75 2.078z" /><use
        x="70"
        y="560.141"
        xlink:href="#a"
      /><use x="70.035" y="560.141" xlink:href="#b" /><use x="70.059" y="560.141" xlink:href="#c" /><use
        x="70.09"
        y="560.141"
        xlink:href="#d"
      /><use x="70.121" y="560.141" xlink:href="#e" /><use x="70.145" y="560.141" xlink:href="#c" /><use
        x="70.176"
        y="560.141"
        xlink:href="#f"
      /><use x="70.223" y="560.141" xlink:href="#g" /><use x="70.258" y="560.141" xlink:href="#h" /><use
        x="70.305"
        y="560.141"
        xlink:href="#i"
      /><use x="70.344" y="560.141" xlink:href="#j" /><use x="70.359" y="560.141" xlink:href="#c" /><use
        x="70.391"
        y="560.141"
        xlink:href="#k"
      /><use x="70.426" y="560.141" xlink:href="#d" /><use x="70.473" y="560.141" xlink:href="#l" /><use
        x="70.508"
        y="560.141"
        xlink:href="#d"
      /><use x="70.539" y="560.141" xlink:href="#k" /><use x="70.57" y="560.141" xlink:href="#d" /><use
        x="70.602"
        y="560.141"
        xlink:href="#m"
      /><use x="70.629" y="560.141" xlink:href="#n" /><use x="70.664" y="560.141" xlink:href="#o" /><use
        x="70.691"
        y="560.141"
        xlink:href="#m"
      /><use x="70.723" y="560.141" xlink:href="#p" /><use x="70.75" y="560.141" xlink:href="#d" /><use
        x="70"
        y="560.188"
        xlink:href="#q"
      /><use x="70.02" y="560.188" xlink:href="#b" /><use x="70.043" y="560.188" xlink:href="#n" /><use
        x="70.074"
        y="560.188"
        xlink:href="#r"
      /><use x="70.141" y="560.188" xlink:href="#e" /><use x="70.164" y="560.188" xlink:href="#s" /><use
        x="70.195"
        y="560.188"
        xlink:href="#c"
      /><use x="70.242" y="560.188" xlink:href="#t" /><use x="70.281" y="560.188" xlink:href="#n" /><use
        x="70.316"
        y="560.188"
        xlink:href="#u"
      /><use x="70.348" y="560.188" xlink:href="#k" /><use x="70.398" y="560.188" xlink:href="#l" /><use
        x="70.434"
        y="560.188"
        xlink:href="#b"
      /><use x="70.453" y="560.188" xlink:href="#n" /><use x="70.488" y="560.188" xlink:href="#v" /><use
        x="70.504"
        y="560.188"
        xlink:href="#c"
      /><use x="70.535" y="560.188" xlink:href="#w" /><use x="70.563" y="560.188" xlink:href="#e" />
    </svg>
    """
  end

  def pluralize(singular, plural, count) do
    Gettext.ngettext(MagisteriaWeb.Gettext, singular, plural, count)
  end
end
