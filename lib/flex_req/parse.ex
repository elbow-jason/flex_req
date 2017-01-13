defmodule FlexReq.Parse do
  alias FlexReq.Parse

  def url(url) when url |> is_binary do
    url
    |> prepare_url
    |> URI.parse
    |> FlexReq.from_uri
  end

  defp prepare_url("http://" <> rest),  do: "http://"  <> rest
  defp prepare_url("https://" <> rest), do: "https://" <> rest
  defp prepare_url("//" <> rest),       do: "http://"  <> rest
  defp prepare_url(url),                do: "http://"  <> url

  def userinfo(nil), do: {nil, nil}
  def userinfo(info) when info |> is_binary do
    case String.split(info, ":") do
      [user, pass] -> {user, pass}
      _ -> raise "Invalid Url Userinfo"
    end
  end

  def query(%FlexReq{query: nil} = req) do
    %{ req | query: %{}}
  end
  def query(%FlexReq{query: q} = req) when q |> is_binary do
    %{ req | query: Parse.query(q) }
  end
  def query(%FlexReq{query: %{} = _a_map} = req) do
    req
  end
  def query("?" <> q) do
    Parse.query(q)
  end
  def query(q) when q |> is_binary do
    URI.decode_query(q)
  end

  def path(%FlexReq{path: p} = req) do
    %{ req | path: Parse.path(p) }
  end
  def path(p) do
    do_path_to_list(p)
  end

  def fragment(%FlexReq{fragment: f} = req) do
    %{ req | fragment: Parse.fragment(f) }
  end
  def fragment(f) do
    do_path_to_list(f)
  end

  defp do_path_to_list(p) when p |> is_nil,    do: []
  defp do_path_to_list(p) when p |> is_binary, do: p |> Path.split
  defp do_path_to_list(p) when p |> is_list,   do: p

end
