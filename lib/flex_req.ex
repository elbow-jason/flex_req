defmodule FlexReq do
  defstruct [
    method:     :get,
    scheme:     "http",
    user:       nil,
    pass:       nil,
    host:       nil,
    port:       80,
    path:       [],
    query:      %{},
    fragment:   [],
    body:       nil,
    headers:    [],
    options:    [],
  ]

  def new(url) when url |> is_binary do
    url
    |> prepare_url
    |> URI.parse
    |> new
  end
  def new(%URI{} = uri) do
    {user, pass} = parse_userinfo(uri.userinfo)
    %FlexReq{
      host:       uri.host,
      port:       uri.port,
      scheme:     uri.scheme,
      path:       uri.path,
      query:      uri.query,
      fragment:   uri.fragment,
      user:       user,
      pass:       pass,
    }
    |> path_to_list
    |> query_to_map
    |> fragment_to_list
  end
  def new(parts) when parts |> is_list do
    parts
    |> Enum.into(%{})
    |> new
  end
  def new(parts) when parts |> is_map do
    struct_set =
      %FlexReq{}
      |> Map.from_struct
      |> Map.keys
      |> MapSet.new
    parts_set =
      parts
      |> Map.keys
      |> MapSet.new
    drop_fields =
      parts_set
      |> MapSet.difference(struct_set)
      |> MapSet.to_list
    parts
    |> Map.drop(drop_fields)
    |> Enum.reduce(%FlexReq{}, fn ({field, val}, req) -> Map.put(req, field, val) end)
  end

  defp prepare_url("http://" <> rest),  do: "http://"  <> rest
  defp prepare_url("https://" <> rest), do: "https://" <> rest
  defp prepare_url("//" <> rest),       do: "http://"  <> rest
  defp prepare_url(url),                do: "http://"  <> url

  defp parse_userinfo(nil), do: {nil, nil}
  defp parse_userinfo(info) when info |> is_binary do
    case String.split(info, ":") do
      [user, pass] -> {user, pass}
      _ -> raise "Invalid Url Userinfo"
    end
  end

  def send(%FlexReq{} = req) do
    # prep for httpoison
    req
    |> prepare_req
    |> do_send
  end

  defp do_send(req) do
    HTTPoison.request(req.method, url(req), req.body, req.headers, req.options)
  end

  def url(req) do
    render_scheme(req)
      <> "://"
      <> render_userpass(req)
      <> render_host(req)
      <> render_port(req)
      <> render_path(req)
      <> render_query(req)
      <> render_fragment(req)
  end

  defp render_scheme(%{scheme: nil}),        do: "http"
  defp render_scheme(%{scheme: ""<>scheme}), do: scheme

  defp render_userpass(%{user: ""<>user, pass: ""<>pass}) do
    user <> ":" <> pass
  end
  defp render_userpass(_) do
    ""
  end

  defp render_host(%{host: host}) when host |> is_binary do
    host
  end
  defp render_host(req) do
    raise "Invalid Host - #{inspect req}"
  end

  defp render_port(%{scheme: "http", port: nil}),   do: ""
  defp render_port(%{scheme: "http", port: 80}),    do: ""
  defp render_port(%{scheme: "https", port: nil}),  do: ""
  defp render_port(%{scheme: "https", port: 443}),  do: ""
  defp render_port(%{port: nil}),                   do: ""
  defp render_port(%{port: port}) do
    ":" <> (port |> Kernel.to_string)
  end

  defp render_path(%{path: []}) do
    ""
  end
  defp render_path(%{path: path}) when path |> is_list do
    path |> Path.join |> render_path
  end
  defp render_path(%{path: path}) do
    path |> render_path
  end
  defp render_path(nil) do
    ""
  end
  defp render_path("/" <> "") do
    "/"
  end
  defp render_path("/" <> path) do
    path |> render_path
  end
  defp render_path(path) when path |> is_binary do
    "/" <> path
  end

  defp render_query(%FlexReq{query: query}) do
    render_query(query)
  end
  defp render_query(nil) do
    ""
  end
  defp render_query(q) when q |> is_map do
    if Map.equal?(q, %{}) do
      ""
    else
      "?" <> URI.encode_query(q)
    end
  end
  defp render_query(q) when q |> is_binary do
    "?" <> URI.encode(q)
  end


  defp render_fragment(%{fragment: frag}) do
    frag |> render_fragment
  end
  defp render_fragment(nil), do: ""
  defp render_fragment([]), do: ""
  defp render_fragment(frag) when frag |> is_list do
    frag |> Path.join |> render_fragment
  end
  defp render_fragment(frag) when frag |> is_binary do
    "#" <> frag
  end

  defp prepare_req(req) do
    req
    |> render_body
    |> prepare_headers
    |> prepare_method
  end

  defp render_body(%FlexReq{body: body} = req) when body |> is_list or body |> is_map do
    case Poison.encode(body) do
      {:ok, rendered} ->
        req
        |> json_headers
        |> Map.put(:body, rendered)
      _ ->
        raise "Failed to JSON Encode Body: #{inspect body}"
    end
  end
  defp render_body(%FlexReq{body: body} = req) do
    %{ req | body: body |> Kernel.to_string }
  end

  defp json_headers do
    [{"Content-Type", "application/json"}]
  end
  defp json_headers(%FlexReq{headers: headers} = req) do
    %{ req | headers: json_headers() ++ headers }
  end

  defp prepare_headers(%FlexReq{headers: headers} = req) do
    %{ req | headers: headers |> Enum.uniq }
  end

  @atom_methods ~w(
    get post put patch delete options head
  )a

  @string_methods ~w(
    get post put patch delete options head
    GET POST PUT PATCH DELETE OPTIONS HEAD
  )

  defp prepare_method(%{method: method} = req) do
    %{ req | method: prepare_method(method) }
  end
  defp prepare_method(method) when method in @atom_methods do
    method
  end
  defp prepare_method(method) when method in @string_methods do
    method
    |> String.downcase
    |> String.to_existing_atom
  end

  def query_to_map(%FlexReq{query: nil} = req) do
    %{ req | query: %{} }
  end
  def query_to_map(%FlexReq{query: q} = req) when q |> is_binary do
    %{ req | query: URI.decode_query(q) }
  end
  def query_to_map(%FlexReq{query: %{} = _a_map} = req) do
    req
  end

  defp path_to_list(%FlexReq{path: p} = req) do
    %{ req | path:  do_path_to_list(p) }
  end
  defp fragment_to_list(%FlexReq{fragment: f} = req) do
    %{ req | fragment:  do_path_to_list(f) }
  end

  def do_path_to_list(p) when p |> is_nil,    do: []
  def do_path_to_list(p) when p |> is_binary, do: p |> Path.split
  def do_path_to_list(p) when p |> is_list,   do: p

  def add_query(%FlexReq{} = req, key, value) do
    qmap =
      req
      |> query_to_map
      |> Map.get(:query)
    %{ req | query: Map.put(qmap, key, value) }
  end

  def merge_query(%FlexReq{} = req, other) do
    qmap =
      req
      |> query_to_map
      |> Map.get(:query)
    %{ req | query: Map.merge(qmap, other) }
  end

  def append_path(%FlexReq{} = req, other) when other |> is_binary do
    append_path(req, [other])
  end
  def append_path(%FlexReq{} = req, other) when other |> is_list do
    path =
      req
      |> path_to_list
      |> Map.get(:path)
    %{ req | path: path ++ other }
  end


end
