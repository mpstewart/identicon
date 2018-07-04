defmodule Identicon do
  @moduledoc """
    Generate an identicon for a given string
  """

  def main(input) do
    input
    |> hash_input
    |> pick_color
    |> build_grid
    |> filter_odd_squares
    |> build_pixel_map
    |> draw_image
    |> save_image(input)
  end

  @doc """
    Creates a 25-byte hex value from the given input
  """
  def hash_input(input) do
    hex =
      :crypto.hash(:md5, input)
      |> :binary.bin_to_list()

    %Identicon.Image{hex: hex}
  end

  @doc """
    Picks the color from the first 3 bytes of the hash
  """
  def pick_color(%Identicon.Image{hex: [r, g, b | _tail]} = image) do
    %Identicon.Image{image | color: {r, g, b}}
  end

  @doc """
    Builds a grid structure to represent more or less a bitmap
  """
  def build_grid(%Identicon.Image{hex: hex} = image) do
    grid =
      hex
      |> Enum.chunk(3)
      |> Enum.map(&mirror_row/1)
      |> List.flatten
      |> Enum.with_index

    %Identicon.Image{image | grid: grid}
  end

  @doc """
    Generate a palidromic, 5 item list out of a 3 item list
    
  ## Examples

  iex> Identicon.mirror_row([1, 2, 3])
  [1, 2, 3, 2, 1]

  """
  def mirror_row(row) do
    [first, second | _tail] = row

    row ++ [second, first]
  end

  @doc """
    Filters odd bytes out of an Identicon.Image's grid
  """
  def filter_odd_squares(%Identicon.Image{grid: grid} = image) do
    grid =
      Enum.filter(grid, fn {byte, _index} ->
        rem(byte, 2) == 0
      end)

    %Identicon.Image{image | grid: grid}
  end

  @doc """
    Build the pixel map that we'll give to EGD
  """
  def build_pixel_map(%Identicon.Image{grid: grid} = image) do
    pixel_map = Enum.map grid, fn({_code, i}) ->
      x1 = rem(i, 5) * 50
      y1 = div(i, 5) * 50

      x2 = x1 + 50
      y2 = y1 + 50

      {{x1, y1}, {x2, y2}}
    end

    %Identicon.Image{image | pixel_map: pixel_map}
  end

  @doc """
    Generate the image binary using EGD
  """
  def draw_image(%Identicon.Image{color: color, pixel_map: pixel_map}) do
    image = :egd.create(250, 250)
    fill = :egd.color(color)

    Enum.each pixel_map, fn({start, stop}) ->
      :egd.filledRectangle(image, start, stop, fill)
    end

    :egd.render(image)
  end

  @doc """
    Write the image binary to disk
  """
  def save_image(image, filename) do
    File.write("#{filename}.png", image)
  end

end
