defmodule FlexReqTest do
  use ExUnit.Case
  doctest FlexReq

  setup do
    req =
      "https://someuser:somepass@www.google.com/en?somekey=somevalue&somenil=#somefragment"
      |> FlexReq.parse
    {:ok, %{req: req}}
  end

  test "a parsed url is a FlexReq struct", %{req: req} do
    assert req.__struct__ == FlexReq
  end

  test "parsed queries are maps", %{req: req} do
    assert req.query == %{"somekey" => "somevalue", "somenil" => ""}
  end

  test "parsed host is a string", %{req: req} do
    assert req.host == "www.google.com"
  end

  test "parsed path is a list", %{req: req} do
    assert req.path == ["/", "en"]
  end

  test "parsed fragment is a list", %{req: req} do
    assert req.fragment == ["somefragment"]
  end

  test "parsed port is 80 when http" do
    req =
      "http://www.google.com"
      |> FlexReq.parse
    assert req.port == 80
  end

  test "parsed port is 443 when https" do
    req =
      "https://www.google.com"
      |> FlexReq.parse
    assert req.port == 443
  end

  test "parsed port is the number of the port in the url" do
    req =
      "https://localhost:4000"
      |> FlexReq.parse
    assert req.port == 4000
  end

  test "user parsing works", %{req: req} do
    assert req.user == "someuser"
  end

  test "pass parsing works", %{req: req} do
    assert req.pass == "somepass"
  end

  test "defaults to port 443 when port is invalid" do
    req =
      "https://localhost:dooop"
      |> FlexReq.parse
    assert req.port == 443
    assert "https://localhost" == req |> to_string
  end

  test "method default is :get when parsed", %{req: req} do
    assert req.method == :get
  end

  test "headers default is [] when parsed", %{req: req} do
    assert req.headers == []
  end

  test "added_headers/3 can add a header to the headers", %{req: req} do
    req =
      req
      |> FlexReq.add_headers("Hello", "World")
    assert req.headers == [{"Hello", "World"}]
  end

  test "add_headers/2 can handle tuple", %{req: req} do
    req =
      req
      |> FlexReq.add_headers({"Hello", "World"})
    assert req.headers == [{"Hello", "World"}]
  end

  test "add_headers/2 can handle a list", %{req: req} do
    req =
      req
      |> FlexReq.add_headers([{"Hello", "World"}, {"Happy", "Tuesday"}])
      |> FlexReq.add_headers([{"Hello", "World"}, {"Happy", "Tuesday"}])
    assert req.headers == [
      {"Happy", "Tuesday"},
      {"Hello", "World"},
      {"Happy", "Tuesday"},
      {"Hello", "World"},
    ]
  end

  test "a request can be sent" do
    x = "www.google.com"
      |> FlexReq.new
      |> FlexReq.send
  end

end
