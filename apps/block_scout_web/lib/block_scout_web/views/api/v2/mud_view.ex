defmodule BlockScoutWeb.API.V2.MudView do
  use BlockScoutWeb, :view

  alias Explorer.Chain.{Block, Mud, Mud.Table, Transaction}
  alias Explorer.Chain.ZkSync.TransactionBatch

  @doc """
    Function to render GET requests to `/api/v2/mud/worlds` endpoint.
  """
  @spec render(String.t(), map()) :: map()
  def render("worlds.json", %{worlds: worlds, next_page_params: next_page_params}) do
    %{
      items: worlds,
      next_page_params: next_page_params
    }
  end

  @doc """
    Function to render GET requests to `/api/v2/mud/worlds/count` endpoint.
  """
  def render("count.json", %{count: count}) do
    %{
      count: count
    }
  end

  @doc """
    Function to render GET requests to `/api/v2/mud/worlds/:world/tables` endpoint.
  """
  def render("tables.json", %{table_ids: table_ids, schemas: schemas, next_page_params: next_page_params}) do
    %{
      items: table_ids |> Enum.map(&%{table: Table.from(&1), schema: schemas[&1]}),
      next_page_params: next_page_params
    }
  end

  @doc """
    Function to render GET requests to `/api/v2/mud/worlds/:world/tables/:table_id/records` endpoint.
  """
  def render("records.json", %{records: records, table_id: table_id, schema: schema, next_page_params: next_page_params}) do
    %{
      items: records |> Enum.map(&format_record(&1, schema)),
      table: table_id |> Table.from(),
      schema: schema,
      next_page_params: next_page_params
    }
  end

  @doc """
    Function to render GET requests to `/api/v2/mud/worlds/:world/tables/:table_id/records/:record_id` endpoint.
  """
  def render("record.json", %{record: record, table_id: table_id, schema: schema}) do
    %{
      record: record |> format_record(schema),
      table: table_id |> Table.from(),
      schema: schema
    }
  end

  defp format_record(nil, schema), do: nil

  defp format_record(record, schema) do
    %{
      id: record.key_bytes,
      raw: %{
        key_bytes: record.key_bytes,
        key0: record.key0,
        key1: record.key1,
        static_data: record.static_data,
        encoded_lengths: record.encoded_lengths,
        dynamic_data: record.dynamic_data,
        block_number: record.block_number,
        log_index: record.log_index
      },
      is_deleted: record.is_deleted,
      decoded: Mud.decode_record(record, schema)
    }
  end
end
