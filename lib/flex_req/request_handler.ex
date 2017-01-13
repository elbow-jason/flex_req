defmodule FlexReq.RequestHandler do
  use Behaviour

  defcallback send_request(%FlexReq{}) :: any
  defcallback prepare_request(%FlexReq{}, any) :: {:ok, %FlexReq{}} | {:error, any}

end
