defmodule PumpkinchatWeb.DrawLive do
  @moduledoc """
  A multiplayer canvas that allows users to carve a pumpkin together.
  If the `uuid` query parameter is present, a drawing will be loaded
  from the database.
  """
  use PumpkinchatWeb, :live_view

  alias Pumpkinchat.Drawing
  alias Pumpkinchat.Repo

  @impl true
  def mount(params, _session, socket) do
    {:ok, assign(socket,
      admin: true,
      brush_type: "carve",
      drawing: get_drawing(params["uuid"]),
      drawing_mode: "select",
      drawing_type: "pumpkin",
      editable: true
    )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <%= if @admin do %>
        <form class="flex flex-row-reverse gap-2 pb-1" phx-change="admin_settings_updated">
          <button class="px-1 rounded transition bg-zinc-900 hover:bg-zinc-800" type="button" phx-click="load_drawing">
            delete
          </button>
          <button class="px-1 rounded transition bg-zinc-900 hover:bg-zinc-800" type="button" phx-click="save_drawing">
            save
          </button>
          <select name="drawing_type" class="p-0 rounded transition bg-zinc-900 hover:bg-zinc-800">
            <option disabled>type</option>
            <option selected={@drawing_type == "pumpkin"}>pumpkin</option>
            <option selected={@drawing_type == "carving"}>carving</option>
          </select>
          <select name="brush_type" class="p-0 rounded transition bg-zinc-900 hover:bg-zinc-800">
            <option disabled>brush</option>
            <option selected={@brush_type == "primary"}>primary</option>
            <option selected={@brush_type == "secondary"}>secondary</option>
          </select>
        </form>
      <% end %>
      <div class="overflow-hidden">
        <.drawing_controls drawing_mode={@drawing_mode} />
        <.paper_canvas
          id="pumpkin"
          drawing_mode={@drawing_mode}
          editable={@editable}
          drawing={@drawing}
          draw_resolution={8}
        />
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("admin_settings_updated", %{} = params, socket) do
    {:noreply, assign(socket, brush_type: params["brush_type"], drawing_type: params["drawing_type"])}
  end

  @impl true
  def handle_event("save_drawing", _params, socket) do
    {:noreply, push_event(socket, "persist", %{})}
  end

  @impl true
  def handle_event("set_drawing_mode", %{"mode_id" => mode_id}, socket) do
    {:noreply, assign(socket, drawing_mode: mode_id)}
  end

  @impl true
  def handle_event("persist_drawing", %{"drawing" => encoded_drawing}, %{assigns: %{} = assigns} = socket) do
    case save_drawing(encoded_drawing, assigns) do
      {:ok, %Drawing{} = drawing} ->
        {:noreply, assign(socket, drawing: drawing)}

      _ ->
        # TODO: Handle error
        {:noreply, socket}
    end
  end

  ###

  defp save_drawing(encoded_drawing, %{drawing_type: drawing_type} = assigns) do
    assigns
    |> Map.get(:drawing, %Drawing{})
    |> Drawing.changeset(%{content: encoded_drawing, type: drawing_type})
    |> Repo.insert_or_update()
  end

  defp get_drawing(nil), do: nil
  defp get_drawing(uuid), do: Repo.get(Drawing, uuid)
end
