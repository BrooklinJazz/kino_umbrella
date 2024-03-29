defmodule KinoLiveViewNative.SmartCells.LiveViewNative do
  require IEx.Helpers
  require Logger

  use Kino.JS
  use Kino.JS.Live
  use Kino.SmartCell, name: "LiveView Native"

  @registry_key :liveviews

  @impl true
  def init(attrs, ctx) do
    {:ok,
     ctx
     |> assign(
       path: attrs["path"] || "/",
       action: attrs["action"] || ":index"
     ),
     editor: [
       attribute: "code",
       language: "elixir",
       default_source: default_source()
     ]}
  end

  @impl true
  def handle_connect(ctx) do
    {:ok, %{path: ctx.assigns.path, action: ctx.assigns.action}, ctx}
  end

  @impl true
  def to_attrs(ctx) do
    %{
      "path" => ctx.assigns.path,
      "action" => ctx.assigns.action
    }
  end

  @impl true
  def to_source(attrs) do
    [
      # Use our defmodule definition
      """
      require KinoLiveViewNative.Livebook
      import KinoLiveViewNative.Livebook
      import Kernel, except: [defmodule: 2]
      """,
      attrs["code"],
      "|> #{register_module_source(attrs)}",
      # Restore the existing definition
      """
      import KinoLiveViewNative.Livebook, only: []
      import Kernel
      :ok
      """
    ]
  end

  def register_module_source(attrs) do
    quote do
      unquote(__MODULE__).register(unquote(attrs["path"]), unquote(attrs["action"]))
    end
    |> Kino.SmartCell.quoted_to_string()
  end

  @impl true
  def handle_event("update_" <> variable_name, value, ctx) do
    variable = String.to_existing_atom(variable_name)
    ctx = assign(ctx, [{variable, value}])

    broadcast_event(
      ctx,
      "update_" <> variable_name,
      ctx.assigns[variable]
    )

    {:noreply, ctx}
  end

  def get_routes() do
    Application.get_env(:kino_live_view_native, @registry_key, [])
  end

  defp put_routes(routes) do
    Application.put_env(:kino_live_view_native, @registry_key, routes)
  end

  def register({:module, module, _, _}, path, action) do
    action =
      action
      |> String.trim_leading(":")
      |> String.to_atom()

    new_route = %{path: path, module: module, action: action}

    get_routes()
    # Remove existing route with the same path
    |> Enum.reject(fn r -> r.path == path end)
    |> Enum.filter(fn r -> is_valid_liveview(r.module) end)
    |> Kernel.++([new_route])
    |> put_routes()

    # Reloading routes must occur before the LV evaluates in Livebook.
    # Otherwise the LV will not be available for previously defined routes when changing the LV name.
    IEx.Helpers.r(KinoLiveViewNativeWeb.Router)
    Phoenix.PubSub.broadcast!(KinoLiveViewNative.PubSub, "reloader", :trigger)
  end

  def default_source() do
    ~s[defmodule KinoLiveViewNativeWeb.ExampleLive do
  use KinoLiveViewNativeWeb, :live_view

  @impl true
  def render(%{format: :swiftui} = assigns) do
    ~SWIFTUI"""
    <Text>Hello from LiveView Native!</Text>
    """
  end

  def render(assigns) do
    ~H"""
    <p>Hello from LiveView!</p>
    """
  end
end]
  end

  asset "main.js" do
    """
    export function init(ctx, payload) {
      ctx.importCSS("main.css");
      ctx.importCSS("https://fonts.googleapis.com/css2?family=Inter:wght@400;500&display=swap");

      root.innerHTML = `
        <div class="app">
          <label class="label">Route</label>
          <input class="input" type="text" name="path" />

          <label class="label">Action</label>
          <input class="input" type="text" name="action" />
        </div>
      `;

      const sync = (id) => {
          const variableEl = ctx.root.querySelector(`[name="${id}"]`);
          variableEl.value = payload[id];

          variableEl.addEventListener("change", (event) => {
            ctx.pushEvent(`update_${id}`, event.target.value);
          });

          ctx.handleEvent(`update_${id}`, (variable) => {
            variableEl.value = variable;
          });
      }

      sync("path")
      sync("action")

      ctx.handleSync(() => {
          // Synchronously invokes change listeners
          document.activeElement &&
            document.activeElement.dispatchEvent(new Event("change"));
      });
    }
    """
  end

  asset "main.css" do
    """
    .app {
      font-family: "Inter";
      display: flex;
      align-items: center;
      gap: 16px;
      background-color: #ecf0ff;
      padding: 8px 16px;
      border: solid 1px #cad5e0;
      border-radius: 0.5rem 0.5rem 0 0;
    }

    .label {
      font-size: 0.875rem;
      font-weight: 500;
      color: #445668;
      text-transform: uppercase;
    }

    .input {
      padding: 8px 12px;
      background-color: #f8f8afc;
      font-size: 0.875rem;
      border: 1px solid #e1e8f0;
      border-radius: 0.5rem;
      color: #445668;
      min-width: 150px;
    }

    .input:focus {
      border: 1px solid #61758a;
      outline: none;
    }
    """
  end

  defp is_valid_liveview(module) do
    if Kernel.function_exported?(module, :__live__, 0) do
      true
    else
      Logger.error("Module #{inspect(module)} is not a valid LiveView.")
      false
    end
  end
end
