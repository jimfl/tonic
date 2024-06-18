defmodule Tonic.CanvasTest do
  use ExUnit.Case

  alias Tonic.Canvas

  test "canvas with default origin" do
    canvas = Canvas.new(height: 50, width: 50)
    %{height: 50, width: 50, origin: {0, 0}} = canvas
    svg = canvas |> Canvas.to_svg()
    assert svg =~ ~r(view-box="0 0 50 50")
  end

  test "canvas with shifted origin" do
    canvas = Canvas.new(height: 50, width: 50, origin: {25, 25})
    %{height: 50, width: 50, origin: {25, 25}} = canvas
    svg = canvas |> Canvas.to_svg()
    assert svg =~ ~r(view-box="-25 -25 25 25")
  end

  test "canvas with shifted origin, resized" do
    canvas = Canvas.new(height: 50, width: 50, origin: {25, 25})
    %{height: 50, width: 50, origin: {25, 25}} = canvas
    svg = canvas |> Canvas.to_svg({100, 250})
    assert svg =~ ~r(view-box="-25 -25 25 25")
    assert svg =~ ~r(height="250")
    assert svg =~ ~r(width="100")
  end
end
