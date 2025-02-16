defmodule AshHq.Release do
  @moduledoc """
  Houses tasks that need to be executed in the released application (because mix is not present in releases).
  """

  @app :ash_hq
  def migrate do
    load_app()

    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end
  end

  def migrate_all do
    load_app()
    migrate()
  end

  def rollback(repo, version) do
    load_app()
    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  defp repos do
    apis()
    |> Enum.flat_map(fn api ->
      api
      |> Ash.Api.Info.resources()
      |> Enum.map(&AshPostgres.DataLayer.Info.repo/1)
    end)
    |> Enum.uniq()
  end

  defp apis do
    Application.fetch_env!(@app, :ash_apis)
  end

  defp load_app do
    Application.load(@app)
  end
end
