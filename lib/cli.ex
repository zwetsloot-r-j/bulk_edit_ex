defmodule BulkEdit.CLI do

  def main([pattern, extension]) do
    {:ok, path} = File.cwd
    IO.inspect(path)
    BulkEdit.find_pattern(pattern, path, [extension])
    |> IO.inspect
  end

  def main([pattern, replacement, extension]) do
    {:ok, path} = File.cwd
    IO.inspect(path)
    BulkEdit.replace_pattern(pattern, replacement, path, [extension])
    |> IO.inspect
  end

end
