defmodule PumpkinchatWeb.DrawLive do
  @moduledoc """
  A multiplayer canvas that allows users to carve a pumpkin together.
  If the `uuid` query parameter is present, a drawing will be loaded
  from the database.
  """
  use PumpkinchatWeb, :live_view

  require Ecto.Query

  alias Pumpkinchat.Drawing
  alias Pumpkinchat.Repo
  alias Pumpkinchat.SessionServer

  @impl true
  def mount(params, _session, socket) do
    with true <- connected?(socket),
         drawing <- get_drawing(params["uuid"])
    do
      SessionServer.join(self())

      {:ok, assign(socket,
        active_layer: "carving",
        admin: true,
        drawing: drawing,
        drawing_mode: "pen",
        drawing_type: drawing[:type] || "user",
        draw_resolution: 6,
        editable: true,
        fill_color: "#060504",
        loading: false
      )}
    else
      _ ->
        {:ok, assign(socket, loading: true)}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="grid items-center justify-items-center ">
      <%= if @loading do %>
        <div class="w-full h-full grid justify-items-center content-center items-center">
          <div class="loader"></div>
        </div>
      <% else %>
        <%= if @admin do %>
          <form class="flex flex-row-reverse gap-2 pb-1 w-[512px]" phx-change="admin_settings_updated">
            <button class="px-1 rounded transition bg-zinc-900 hover:bg-zinc-800" type="button" phx-click="load_drawing">
              delete
            </button>
            <button class="px-1 rounded transition bg-zinc-900 hover:bg-zinc-800" type="button" phx-click="save_drawing">
              save
            </button>
            <select name="drawing_type" class="p-0 rounded transition bg-zinc-900 hover:bg-zinc-800">
              <option disabled>type</option>
              <option selected={@drawing_type == "template"}>template</option>
              <option selected={@drawing_type == "user"}>user</option>
            </select>
            <select name="active_layer" class="p-0 rounded transition bg-zinc-900 hover:bg-zinc-800">
              <option disabled>layer</option>
              <option selected={@active_layer == "pumpkin"}>pumpkin</option>
              <option selected={@active_layer == "pumpkindeco"}>pumpkindeco</option>
              <option selected={@active_layer == "carving"}>carving</option>
            </select>
            <input name="fill_color" class="bg-zinc-900 rounded w-24" value={@fill_color} placeholder="fill_color" />
            <input name="draw_resolution" class="bg-zinc-900 rounded w-24" value={@draw_resolution} placeholder="draw_resolution" />
          </form>
        <% end %>
        <div class="w-[512px]">
          <.drawing_controls drawing_mode={@drawing_mode} />
          <.paper_canvas
            id="pumpkin"
            active_layer={@active_layer}
            draw_resolution={@draw_resolution}
            drawing_mode={@drawing_mode}
            drawing_type={@drawing_type}
            drawing={@drawing}
            editable={@editable}
            fill_color={@fill_color}
          />
        </div>
      <% end %>
    </div>
    """
  end

  @impl true
  def handle_event("admin_settings_updated", %{} = params, socket) do
    {:noreply, assign(socket,
      active_layer: params["active_layer"],
      draw_resolution: params["draw_resolution"],
      drawing_type: params["drawing_type"],
      fill_color: params["fill_color"]
    )}
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

  defp save_drawing(encoded_drawing, %{drawing: drawing, drawing_type: drawing_type}) do
    drawing = drawing || %Drawing{}

    drawing
    |> Drawing.changeset(%{content: encoded_drawing, type: drawing_type})
    |> Repo.insert_or_update()
  end

  defp get_drawing(nil), do: get_random_template()
  defp get_drawing(uuid) do
    case Repo.get(Drawing, uuid) do
      nil ->
        get_random_template()

      drawing ->
        drawing
    end
  end

  defp get_random_template do
    Ecto.Query.from(d in Drawing, where: d.type == :template)
    |> Repo.all()
    |> Enum.shuffle()
    |> List.first()
  end
end
