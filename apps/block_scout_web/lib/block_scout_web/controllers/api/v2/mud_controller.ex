defmodule BlockScoutWeb.API.V2.MudController do
  use BlockScoutWeb, :controller

  import BlockScoutWeb.Chain,
    only: [
      next_page_params: 3,
      next_page_params: 4,
      paging_options: 1,
      split_list_by_page: 1,
      default_paging_options: 0
    ]

  import BlockScoutWeb.PagingHelper,
    only: [
      delete_parameters_from_next_page_params: 1,
      stability_validators_state_options: 1,
      mud_records_sorting: 1
    ]

  alias Explorer.Chain
  alias Explorer.Chain.Mud

  action_fallback(BlockScoutWeb.API.V2.FallbackController)

  @doc """
    Function to handle GET requests to `/api/v2/mud/worlds` endpoint.
  """
  @spec worlds(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def worlds(conn, params) do
    {worlds, next_page} =
      params
      |> mud_paging_options(["world"])
      |> Mud.worlds_list()
      |> split_list_by_page()

    next_page_params = next_page_params(next_page, worlds, params, fn item ->
      %{"world" => item}
    end)

    conn
    |> put_status(200)
    |> render(:worlds, %{worlds: worlds, next_page_params: next_page_params})
  end

  @doc """
    Function to handle GET requests to `/api/v2/mud/worlds/count` endpoint.
  """
  @spec worlds_count(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def worlds_count(conn, _params) do
    count = Mud.worlds_count()

    conn
    |> put_status(200)
    |> render(:count, %{count: count})
  end

  def world_tables(conn, %{"world" => world_param} = params) do
    with {:ok, world} <- Chain.string_to_address_hash(world_param) do

      options = params |> mud_paging_options(["table_id"])

      {tables, next_page} =
        world
        |> Mud.world_tables(options)
        |> split_list_by_page()

      next_page_params = next_page_params(next_page, tables, params |> Map.drop(["world"]), fn item ->
        %{"table_id" => item.table_id}
      end)

      conn
      |> put_status(200)
      |> render(:tables, %{tables: tables, next_page_params: next_page_params})
    end
  end

  def world_tables_count(conn, %{"world" => world_param} = _params) do
    with {:ok, world} <- Chain.string_to_address_hash(world_param) do
      count = Mud.world_tables_count(world)

      conn
      |> put_status(200)
      |> render(:count, %{count: count})
    end
  end

  def world_table_records(conn, %{"world" => world_param, "table_id" => table_id_param} = params) do
    with {:ok, world} <- Chain.string_to_address_hash(world_param),
         {:ok, table_id} <- Chain.string_to_transaction_hash(table_id_param) do
      options =
        params
        |> mud_paging_options(["key_bytes", "key0", "key1"])
        |> Keyword.merge(mud_records_filter(params))
        |> Keyword.merge(mud_records_sorting(params))

      {table, records_plus_one} = Mud.world_table_records(world, table_id, options)

      {records, next_page} = split_list_by_page(records_plus_one)

      next_page_params =
        next_page_params(next_page, records, params |> Map.drop(["world", "table_id"]), fn item ->
          keys = [item.raw.key_bytes, item.raw.key0, item.raw.key1]
          ["key_bytes", "key0", "key1"] |> Enum.zip(keys) |> Enum.into(%{})
        end)

      conn
      |> put_status(200)
      |> render(:records, %{records: records, table: table, next_page_params: next_page_params})
    end
  end

  defp mud_records_filter(params) do
    Enum.reduce(params, [], fn {key, value}, acc ->
      case key do
        "filter_key0" -> Keyword.put(acc, :filter_key0, value)
        "filter_key1" -> Keyword.put(acc, :filter_key1, value)
        _ -> acc
      end
    end)
  end

  def world_table_records_count(conn, %{"world" => world_param, "table_id" => table_id_param} = _params) do
    with {:ok, world} <- Chain.string_to_address_hash(world_param),
         {:ok, table_id} <- Chain.string_to_transaction_hash(table_id_param) do
      count = Mud.world_table_records_count(world, table_id)

      conn
      |> put_status(200)
      |> render(:count, %{count: count})
    end
  end

  def world_table_record(
        conn,
        %{"world" => world_param, "table_id" => table_id_param, "record_id" => record_id_param} = _params
      ) do
    with {:ok, world} <- Chain.string_to_address_hash(world_param),
         {:ok, table_id} <- Chain.string_to_transaction_hash(table_id_param),
         {:ok, record_id} <- hex_string_to_binary(record_id_param) do
      record = Mud.world_table_record(world, table_id, record_id)

      conn
      |> put_status(200)
      |> render(:record, %{record: record})
    end
  end

  defp hex_string_to_binary("0x" <> hex) do
    Base.decode16(hex, case: :mixed)
  end

  defp hex_string_to_binary(hex) do
    Base.decode16(hex, case: :mixed)
  end

  def mud_paging_options(params, keys) do
    key = params |> Map.take(keys) |> Map.to_list() |> Enum.map(&{String.to_atom(elem(&1, 0)), elem(&1, 1)})
    if key |> Enum.count() == keys |> Enum.count() do
      [paging_options: %{default_paging_options() | key: key |> Enum.into(%{})}]
    else
      [paging_options: default_paging_options()]
    end
  end
end
