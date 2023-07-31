defmodule BulkEdit do

  def replace_pattern(pattern, replacement, root, extensions) do
    IO.inspect(pattern)
    {:ok, regex} = Regex.compile(pattern)
    IO.inspect(regex)
    find_files_recursive(root, extensions)
    |> Task.async_stream(fn path ->
      with {:ok, content} <- File.read(path),
           true <- Regex.match?(regex, content)
      do
        content = Regex.replace(regex, content, replacement)
        result = File.write(path, content)
        {result, path}
      else
        _ ->
          {:no_change, path}
      end
    end)
    |> Stream.filter(fn
      {:ok, {:ok, _}} -> true
      _ -> false
    end)
    |> Stream.map(fn {:ok, path} -> path end)
    |> Enum.into([])
  end

  def find_pattern(pattern, root, extensions) do
    {:ok, regex} = Regex.compile(pattern)
    find_files_recursive(root, extensions)
    |> Task.async_stream(fn path ->
      {:ok, content} = File.read(path)
      match = Regex.match?(regex, content)
      {match, path, content}
    end)
    |> Stream.filter(fn
      {:ok, {true, _, _}} -> true
      _ -> false
    end)
    |> Stream.map(fn {:ok, {_, path, _}} -> path end)
    |> Enum.into([])
  end

  def find_files(root, extensions) do
    find_files_recursive(root, extensions)
  end

  defp find_files_recursive(root, extensions) do
    {:ok, files} = File.ls(root)
    {files, dirs} = Enum.reduce(files, {[], []}, fn file, {files, dirs} ->
      path = "#{root}/#{file}"
      if File.dir?(path) do
        {files, [path | dirs]}
      else
        if is_one_of_extensions?(file, extensions) do
          {[path | files], dirs}
        else
          {files, dirs}
        end
      end
    end)

    stream = Task.async_stream(dirs, fn dir -> find_files_recursive(dir, extensions) end)
             |> Stream.flat_map(fn {:ok, inner_stream} -> inner_stream end)
    Stream.concat(files, stream)
  end

  defp is_one_of_extensions?(file, extensions) do
    Enum.any?(extensions, fn extension -> is_extension?(file, extension) end)
  end

  defp is_extension?(file, extension) do
    String.ends_with?(file, extension)
  end

end
