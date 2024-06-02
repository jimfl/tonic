# Tonic

Tonic is a 2-d graphics library for ELixir. Used in conjunction with Kino in LiveBook, it becomes an interactive graphics 
playground. 

## Features

* Outputs SVG 
* Grid based coordinate systems (square, triangle, rectangular)
* Non-imperitive - works by adding Elixir terms to a data structure.

## Example 

This example places randomly colored dots on a square grid with a spacing of 50 pixels.

```elixir
defmodule Sample do
  require Tonic

  alias Tonic.Canvas
  alias Tonic.Grid
  alias Tonic.Shape

  def rand_hex do
    Enum.random(0..255) |> Integer.to_string(16)
  end

  def random_color do
    ~s(##{rand_hex()}#{rand_hex()}#{rand_hex()})
  end

  def dots do

    dots_data = for x <- [1..9], y <- [1..9], into: [], do
      radius = Enum.random(13..19)
      Shape.circle({x, y}, radius, fill: random_color(), stroke: none)
    end

    %Canvas{width: 500, height: 500}  
    |> Grid.push(:square, 50)
    |> Shape.add(dots_data)
    |> Canvas.to_svg()
  end
  
end
```
