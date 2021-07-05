defmodule CandyMartWeb.Router do
  use CandyMartWeb, :router
  use Pow.Phoenix.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :protected do
    plug Pow.Plug.RequireAuthenticated,
      error_handler: Pow.Phoenix.PlugErrorHandler
  end

  pipeline :admin_layout do
    plug :put_layout, {CandyMartWeb.LayoutView, :torch}
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug CandyMartWeb.APIAuthPlug, otp_app: :candy_mart
  end

  pipeline :api_protected do
    plug Pow.Plug.RequireAuthenticated,
      error_handler: CandyMartWeb.APIAuthErrorHandler,
      realm: "Bearer"
  end

  scope "/" do
    pipe_through :browser

    pow_routes()
  end

  scope "/", CandyMartWeb do
    pipe_through :browser

    get "/", PageController, :index
  end

  scope "/admin", CandyMartWeb.Admin, as: :admin do
    pipe_through [:browser, :protected, :admin_layout]

    resources "/orders", OrderController
    post "/import-orders", OrderController, :import
  end

  scope "/api", CandyMartWeb.Api, as: :api do
    pipe_through :api

    resources "/registration", RegistrationController, singleton: true, only: [:create]
    resources "/session", SessionController, singleton: true, only: [:create, :delete]
    post "/session/renew", SessionController, :renew
  end

  scope "/api", CandyMartWeb.Api, as: :api do
    pipe_through [:api, :api_protected]

    post "/sale", ApiController, :create_sale
    post "/sales", ApiController, :create_sales
  end

  # Other scopes may use custom stacks.
  # scope "/api", CandyMartWeb do
  #   pipe_through :api
  # end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :dev_docker, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser
      live_dashboard "/dashboard", metrics: CandyMartWeb.Telemetry
    end
  end
end
