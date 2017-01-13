defmodule FlexReq do
  alias FlexReq.{Parse, Render}

  @handler Application.get_env(:flex_req, :request_handler) || FlexReq.DefaultRequestHandler

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

  def handler, do: @handler

  def new do
    %FlexReq{}
  end
  def new(url) when url |> is_binary do
    Parse.url(url)
  end
  def new(parts) when parts |> is_list do
    parts
    |> Enum.into(%{})
    |> new
  end

  def parse(url) when url |> is_binary do
    Parse.url(url)
  end

  def from_map(parts = %{}) do
    key_set =
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
      |> MapSet.difference(key_set)
      |> MapSet.to_list
    parts
    |> Map.drop(drop_fields)
    |> Enum.reduce(%FlexReq{}, fn ({field, val}, req) -> Map.put(req, field, val) end)
  end

  def from_uri(%URI{} = uri) do
    {user, pass} = Parse.userinfo(uri.userinfo)
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
    |> Parse.path
    |> Parse.query
    |> Parse.fragment
  end

  def to_string(%FlexReq{} = req) do
    Render.url(req)
  end

  def send(%FlexReq{} = req) do
    FlexReq.send(@handler, req)
  end
  def send(handler_module, req) do
    case handler_module.prepare_request(req) do
      {:ok, prepped} -> handler.send_request(prepped)
      err -> err
    end
  end

  def add_headers(%FlexReq{} = req, []) do
    req
  end
  def add_headers(%FlexReq{} = req, [ header | rest ]) do
    req
    |> add_headers(header)
    |> add_headers(rest)
  end
  def add_headers(%FlexReq{} = req, {key, val}) do
    %{ req | headers: [ {key, val} | req.headers ] }
  end
  def add_headers(%FlexReq{} = req, key, value) when key |> is_binary and value |> is_binary do
    add_headers(req, {key, value})
  end

  def add_query(%FlexReq{} = req, key, value) do
    qmap =
      req
      |> Parse.query
      |> Map.get(:query)
    %{ req | query: Map.put(qmap, key, value) }
  end

  def merge_query(%FlexReq{} = req, other) do
    qmap =
      req
      |> Parse.query
      |> Map.get(:query)
    %{ req | query: Map.merge(qmap, other) }
  end

  def append_path(%FlexReq{} = req, other) when other |> is_binary do
    append_path(req, [other])
  end
  def append_path(%FlexReq{} = req, other) when other |> is_list do
    path =
      req
      |> Parse.path
      |> Map.get(:path)
    %{ req | path: path ++ other }
  end

end

defimpl String.Chars, for: FlexReq do
  def to_string(%FlexReq{} = req) do
    FlexReq.to_string(req)
  end
end
