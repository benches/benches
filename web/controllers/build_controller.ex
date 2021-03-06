defmodule Benches.BuildController do
  use Benches.Web, :controller

  alias Benches.Build
  alias Benches.Metric

  plug :scrub_params, "build" when action in [:create, :update]
  plug :action

  def index(conn, _params) do
    builds = Repo.all(Build)
    render(conn, "index.json", builds: builds)
  end

  def create(conn, %{"build" => build_params, "metrics" => metric_params}) do
    result = Repo.transaction fn() ->
      result = build_params
        |> persist_build
        |> persist_metrics(metric_params)

      case result do
        {:ok, build} -> build
        {:error, changeset} -> Repo.rollback(changeset)
      end
    end
    
    case result do
      {:ok, build} -> 
        render(conn, "show.json", build: build)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(Benches.ChangesetView, "error.json", changeset: changeset)
    end
  end

  defp persist_build(build_params) do
    changeset = Build.changeset(%Build{}, build_params)
    if changeset.valid? do
      {:ok, Repo.insert(changeset)}
    else
      {:error, changeset}
    end
  end

  defp persist_metrics({:ok, build}, metrics) do
    changesets =
      metrics
      |> Enum.map(fn(m) -> Map.put(m, "build_id", build.id) end)
      |> Enum.map(fn(m) -> Metric.changeset(%Metric{}, m) end)
      |> Enum.partition(fn(changeset) -> changeset.valid? end)

    case changesets do
      {valid_changesets, []} ->
        metrics = Enum.map(valid_changesets, fn(c) -> Repo.insert(c) end)
        build = %{build | metrics: metrics}
        {:ok, build}
      {_, invalid_changesets} ->
        {:error, invalid_changesets}
    end
  end

  defp persist_metrics({:error, changeset}, _) do
    {:error, changeset}
  end

  def show(conn, %{"id" => id}) do
    build = Repo.get(Build, id)
    render conn, "show.json", build: build
  end

  def update(conn, %{"id" => id, "build" => build_params}) do
    build = Repo.get(Build, id)
    changeset = Build.changeset(build, build_params)

    if changeset.valid? do
      build = Repo.update(changeset)
      render(conn, "show.json", build: build)
    else
      conn
      |> put_status(:unprocessable_entity)
      |> render(Benches.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    build = Repo.get(Build, id)

    build = Repo.delete(build)
    render(conn, "show.json", build: build)
  end
end
