defmodule MyPlugTest do
  use ExUnit.Case, async: true
  use Plug.Test

  @opts KvStore.HTTP.Router.init([])

  test "For an unknown `URI` on main level, it should return 404 and common response" do
    conn = conn(:get, "/unknown_url_which_should_not_be_matched")

    conn = KvStore.HTTP.Router.call(conn, @opts)

    assert conn.state == :sent
    assert conn.status == 404
    assert Plug.Conn.get_resp_header(conn, "content-type") == [ "text/plain; charset=utf-8" ]
    assert conn.resp_body == "Nothing to look here. :("
  end

  test "For an unknown `URI` on `/bucket` level, it should return 404 and common response" do
    conn = conn(:get, "/bucket/unknown_url_which_should_not_be_matched")

    conn = KvStore.HTTP.Router.call(conn, @opts)

    assert conn.state == :sent
    assert conn.status == 404
    assert Plug.Conn.get_resp_header(conn, "content-type") == [ "text/plain; charset=utf-8" ]
    assert conn.resp_body == "Nothing to look here. :("
  end

  test "For an unknown `URI` on `/buckets` level, it should return 404 and common response" do
    conn = conn(:get, "/buckets/unknown_url_which_should_not_be_matched")

    conn = KvStore.HTTP.Router.call(conn, @opts)

    assert conn.state == :sent
    assert conn.status == 404
    assert Plug.Conn.get_resp_header(conn, "content-type") == [ "text/plain; charset=utf-8" ]
    assert conn.resp_body == "Nothing to look here. :("
  end
end
