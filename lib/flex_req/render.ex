defmodule FlexReq.Render do
  alias FlexReq.Render

  def url(%FlexReq{} = req) do
    Render.scheme(req)
    <> "://"
    <> Render.userpass(req)
    <> Render.host(req)
    <> Render.port(req)
    <> Render.path(req)
    <> Render.query(req)
    <> Render.fragment(req)
  end

  def scheme(%{scheme: nil}),        do: "http"
  def scheme(%{scheme: ""<>scheme}), do: scheme

  def userpass(%{user: ""<>user, pass: ""<>pass}) do
    user <> ":" <> pass
  end
  def userpass(%{user: _, pass: _}) do
    ""
  end

  def host(%{host: host}) when host |> is_binary do
    host
  end
  def host(req) do
    raise "Invalid Host - #{inspect req}"
  end

  def port(%{scheme: "http", port: nil}),   do: ""
  def port(%{scheme: "http", port: 80}),    do: ""
  def port(%{scheme: "https", port: nil}),  do: ""
  def port(%{scheme: "https", port: 443}),  do: ""
  def port(%{port: nil}),  do: ""
  def port(%{port: p}),    do: ":" <> (p |> Kernel.to_string)

  def path(path) do
    case path do
      []        -> ""
      nil       -> ""
      "/"       -> "/"
      "" <> p   -> "/" <> p
      p when p |> is_list ->
        p
        |> Path.join
        |> Render.path
      "/" <> p ->
        p
        |> Render.path
      %{path: p} ->
        p
        |> Render.path
    end
  end

  def query(%FlexReq{query: q}) do
    Render.query(q)
  end
  def query(nil) do
    ""
  end
  def query(q) when q |> is_map do
    if Map.equal?(q, %{}) do
      ""
    else
      "?" <> URI.encode_query(q)
    end
  end
  def query("?"<>q) do
    Render.query(q)
  end
  def query(q) when q |> is_binary do
    "?" <> q
  end

  def fragment(%{fragment: frag}) do
    frag
    |> Render.fragment
  end
  def fragment(nil), do: ""
  def fragment([]), do: ""
  def fragment(frag) when frag |> is_list do
    frag
    |> Path.join
    |> Render.fragment
  end
  def fragment(frag) when frag |> is_binary do
    "#" <> frag
  end
end
