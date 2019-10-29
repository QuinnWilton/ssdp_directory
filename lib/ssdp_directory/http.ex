defmodule SSDPDirectory.HTTP do
  @type start_line :: {method :: binary, target :: binary, version}
  @type version :: {major :: non_neg_integer, minor :: non_neg_integer}
  @type header :: {name :: binary, value :: binary}

  @spec decode_start_line(binary) :: {:ok, {start_line, binary}} | :error
  def decode_start_line(data) do
    case :erlang.decode_packet(:http_bin, data, []) do
      {:ok, {:http_request, method, target, version}, rest} ->
        {:ok, {{method, target, version}, rest}}

      _ ->
        :error
    end
  end

  @spec decode_headers(binary, [header]) :: {:ok, [header], binary} | :error
  def decode_headers(data, headers) do
    case :erlang.decode_packet(:httph_bin, data, []) do
      {:ok, {:http_header, _unused, name, _reserved, value}, rest} ->
        headers = [{header_name(name), value} | headers]
        decode_headers(rest, headers)

      {:ok, :http_eoh, rest} ->
        {:ok, headers, rest}

      _ ->
        :error
    end
  end

  defp header_name(name) when is_atom(name), do: name |> Atom.to_string() |> header_name()
  defp header_name(name) when is_binary(name), do: downcase_ascii(name)

  # Lowercases an ASCII string more efficiently than String.downcase/1.
  defp downcase_ascii(string),
    do: for(<<char <- string>>, do: <<downcase_ascii_char(char)>>, into: "")

  defp downcase_ascii_char(char) when char in ?A..?Z, do: char + 32
  defp downcase_ascii_char(char) when char in 0..127, do: char
end
