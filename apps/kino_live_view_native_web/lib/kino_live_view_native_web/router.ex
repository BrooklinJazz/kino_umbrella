defmodule KinoLiveViewNativeWeb.Router do
  use KinoLiveViewNativeWeb, :router

  pipeline :browser do
    plug :accepts, ["html", "swiftui"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {KinoLiveViewNativeWeb.Layouts, :root}, swiftui: {KinoLiveViewNativeWeb.Layouts.SwiftUI, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  live_session :default, on_mount: KinoLiveViewNativeWeb.SetGroupLeader do
    scope "/" do
      pipe_through :browser

      # Often used for debugging
      KinoLiveViewNative.SmartCells.LiveViewNative.get_routes()
      |> Enum.map(fn %{path: path, module: module, action: action} ->
        # Ensure module is a LiveView
        if Kernel.function_exported?(module, :__live__, 0) do
          live(path, module, action)
        else
          Logger.error("Module #{inspect(module)} is not a valid LiveView.")
        end
      end)
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", KinoLiveViewNativeWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard in development
  if Application.compile_env(:kino_live_view_native, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: KinoLiveViewNativeWeb.Telemetry
    end
  end
end
