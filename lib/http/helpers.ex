defmodule KvStore.HTTP.Helpers do
  @moduledoc """
  Helpers for `HTTP` interface for our 'Key-Value Store' application.
  """

  @doc """
  Helper for parsing incoming `HTTP` body.
  """
  def parse(conn) do
    {:ok, values, updated_conn} = Plug.Conn.read_body(conn, length: 200, read_length: 200)
    {values, updated_conn}
  end

  @doc """
  Returning common response for not found `URI`.
  """
  def not_found(conn) do
    conn
    |> Plug.Conn.put_resp_content_type("text/plain")
    |> Plug.Conn.send_resp(404, "Nothing to look here. :(")
  end

  @doc """
  Returning common response for created resource.
  """
  def created(conn, message) do
    conn
    |> Plug.Conn.put_resp_content_type("text/plain")
    |> Plug.Conn.send_resp(201, message)
  end

  @doc """
  Returning common response for accepted resource.
  """
  def accepted(conn, message) do
    conn
    |> Plug.Conn.put_resp_content_type("text/plain")
    |> Plug.Conn.send_resp(202, message)
  end

  @doc """
  Returning common response for OK status.
  """
  def ok(conn, message) do
    conn
    |> Plug.Conn.put_resp_content_type("text/plain")
    |> Plug.Conn.send_resp(200, message)
  end

  @doc """
  Returning JSON response.
  """
  def json(conn, terms) do
    conn
    |> Plug.Conn.put_resp_content_type("application/json")
    |> Plug.Conn.send_resp(200, Poison.encode!(terms))
  end
end
