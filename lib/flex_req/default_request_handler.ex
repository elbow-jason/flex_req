defmodule FlexReq.DefaultRequestHandler do
  @behaviour FlexReq.RequestHandler

  def send_request(%FlexReq{} = req) do
    HTTPoison.request(req.method, req |> FlexReq.Render.url, req.body, req.headers, req.options)
  end

  def prepare_request(req, opts \\ [])
  def prepare_request(%FlexReq{} = req, _opts) do
    with :ok <- :ok,
      {:ok, req} <- prepare_body(req),
      {:ok, req} <- prepare_headers(req),
      {:ok, req} <- prepare_method(req)
    do
      {:ok, req}
    else
      {:error, _} = err -> err
    end
  end

  defp prepare_headers(%FlexReq{headers: headers} = req) when headers |> is_list do
    {:ok, %{ req | headers: headers |> Enum.uniq }}
  end
  defp prepare_headers(_) do
    {:error, :invalid_headers}
  end

  defp prepare_body(%FlexReq{body: {:multipart, _}} = req) do
    {:ok, req}
  end
  defp prepare_body(%FlexReq{body: body} = req) when body |> is_list or body |> is_map do
    case Poison.encode(body) do
      {:ok, rendered} ->
        updated_req =
          req
          |> FlexReq.add_headers({"Content-Type", "application/json"})
          |> Map.put(:body, rendered)
        {:ok, updated_req}
      {:error, _} = err ->
        err
    end
  end
  defp prepare_body(%FlexReq{body: body} = req) do
    {:ok, %{ req | body: body |> Kernel.to_string }}
  end

  @atom_methods ~w(
    get post put patch delete options head
  )a

  @string_methods ~w(
    get post put patch delete options head
    GET POST PUT PATCH DELETE OPTIONS HEAD
  )

  defp prepare_method(%{method: method} = req) do
    {:ok, %{ req | method: do_prepare_method(method) }}
  end
  defp do_prepare_method(method) when method in @atom_methods do
    method
  end
  defp do_prepare_method(method) when method in @string_methods do
    method
    |> String.downcase
    |> String.to_existing_atom
  end
  defp do_prepare_method(_) do
    {:error, :invalid_method}
  end


end
