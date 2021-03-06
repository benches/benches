defmodule Benches.Router do
  use Benches.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", Benches do
    pipe_through :browser # Use the default browser stack

    get "/", PageController, :index
  end

   # Other scopes may use custom stacks.
   scope "/api", Benches do
     pipe_through :api

     resources "/builds", BuildController
   end

   scope "/graphs", Benches do
     get "/:project/:branch", GraphController, :show
   end
end
