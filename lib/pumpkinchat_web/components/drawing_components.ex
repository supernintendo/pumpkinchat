defmodule PumpkinchatWeb.DrawingComponents do
  @moduledoc """
  Provides components for the multiplayer drawing canvas.
  """
  use Phoenix.Component

  import PumpkinchatWeb.CoreComponents, only: [icon: 1]

  attr :drawing_mode, :string, required: true

  @doc """
  A set of buttons that allow the user to change the drawing mode.
  """
  def drawing_controls(%{} = assigns) do
    ~H"""
    <div class="relative h-0 w-0 bg-zinc-800 flex flex-col">
      <.drawing_control icon="hero-cursor-arrow-rays" current_mode_id={@drawing_mode} mode_id="select" />
      <.drawing_control icon="hero-pencil" current_mode_id={@drawing_mode} mode_id="pen" />
    </div>
    """
  end

  attr :icon, :string, required: true
  attr :current_mode_id, :string, default: "unknown"
  attr :mode_id, :string, required: true

  @doc """
  A button that allows the user to change the drawing mode.
  """
  def drawing_control(%{} = assigns) do
    ~H"""
    <div class="mx-2 mt-2">
      <button
        type="button"
        class={if @current_mode_id == @mode_id, do: "p-1 w-12 rounded bg-orange-500 cursor-default transition", else: "p-1 w-12 rounded transition hover:bg-neutral-600/25"}
        phx-click="set_drawing_mode"
        phx-value-mode_id={@mode_id}
      >
        <.icon name={@icon} class={if @current_mode_id == @mode_id, do: "h-6 w-6 bg-black", else: "h-6 w-6"} />
      </button>
    </div>
    """
  end

  attr :id, :string, required: true
  attr :drawing, Pumpkinchat.Drawing
  attr :editable, :boolean, default: false
  attr :drawing_mode, :string, required: true
  attr :draw_resolution, :integer, default: 1

  @doc """
  A canvas that allows users to draw on it. Uses the `PaperCanvas` hook
  for clientside functionality.
  """
  def paper_canvas(%{} = assigns) do
    ~H"""
    <canvas
      id={@id}
      class="w-full h-full bg-zinc-900 rounded"
      phx-hook="PaperCanvas"
      data-drawing-content={if is_nil(@drawing), do: nil, else: @drawing.content}
      data-drawing-mode={@drawing_mode}
      data-draw-resolution={@draw_resolution}
      data-editable={@editable}
      phx-update="ignore"
      resize
    >
    </canvas>
    """
  end
end
