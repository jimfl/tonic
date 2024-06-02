defmodule Tonic.Transform do
  alias Tonic.Transform
  alias Tonic.Grid

  defstruct type: :none,
            coords: nil,
            use_grid_coords: false,
            magnitude: nil

  def rotate(shape, degrees) do
    %Transform{type: :rotate, magnitude: degrees}
    |> add_to_shape(shape)
  end

  def rotate(shape, degrees, origin) do
    %Transform{type: :rotate, coords: origin, magnitude: degrees}
    |> add_to_shape(shape)
  end

  def grid_rotate(shape, degrees, origin) do
    %Transform{type: :rotate, coords: origin, magnitude: degrees}
    |> with_grid()
    |> add_to_shape(shape)
  end

  def translate(shape, x, y) do
    %Transform{type: :translate, magnitude: {x, y}}
    |> add_to_shape(shape)
  end

  def grid_translate(shape, by) do
    %Transform{type: :translate, magnitude: by}
    |> with_grid()
    |> add_to_shape(shape)
  end

  def skew(shape, x, y) do
    %Transform{type: :skew, magnitude: {x, y}}
    |> add_to_shape(shape)
  end

  def scale(shape, x, y) do
    %Transform{type: :scale, magnitude: {x, y}}
    |> add_to_shape(shape)
  end

  def matrix(shape, a, b, c, d, e, f) do
    %Transform{type: :matrix, magnitude: {a, b, c, d, e, f}}
    |> add_to_shape(shape)
  end

  def grid_resolve(transforms, canvas, acc \\ [])

  def grid_resolve([], _, acc), do: acc |> Enum.reverse()

  def grid_resolve([tfm | rest], canvas, acc) do
    grid_resolve(rest, canvas, [do_resolve(tfm, canvas) | acc])
  end

  defp do_resolve(%{use_grid_coords: false} = tfm, _), do: tfm

  defp do_resolve(%{type: :rotate} = tfm, canvas) do
    %{tfm | coords: tfm.coords |> Grid.resolve(canvas)}
  end

  defp do_resolve(%{type: :translate} = tfm, canvas) do
    %{tfm | magnitude: tfm.magnitude |> Grid.resolve(canvas)}
  end

  defp add_to_shape(tfm, shape) do
    %{shape | transforms: [tfm | shape.transforms]}
  end

  defp with_grid(tfm), do: %{tfm | use_grid_coords: true}
end
