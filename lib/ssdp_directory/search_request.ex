defmodule SSDPDirectory.SearchRequest do
  def encode(service_type) when is_binary(service_type) do
    headers = [
      {"host", "239.255.255.250:1900"},
      {"man", "\"ssdp:discover\""},
      {"st", service_type},
      {"mx", "3"}
    ]

    [
      "M-SEARCH * HTTP/1.1\r\n",
      encode_headers(headers),
      "\r\n"
    ]
  end

  defp encode_headers(headers) do
    Enum.reduce(headers, "", fn {name, value}, acc ->
      [acc, name, ": ", value, "\r\n"]
    end)
  end
end
