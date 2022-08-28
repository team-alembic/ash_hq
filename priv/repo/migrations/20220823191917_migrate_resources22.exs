defmodule AshHq.Repo.Migrations.MigrateResources22 do
  @moduledoc """
  Updates resources based on their most recent snapshots.

  This file was autogenerated with `mix ash_postgres.generate_migrations`
  """

  use Ecto.Migration

  def up do
    create unique_index(:libraries, [:order], name: "libraries_unique_order_index")
  end

  def down do
    drop_if_exists unique_index(:libraries, [:order], name: "libraries_unique_order_index")
  end
end