defmodule Tonic.SVGTest do
  use ExUnit.Case

  alias Tonic.SVG

  test "render single minimized tag" do
    tag = SVG.render([%Tonic.Shape{name: :rect, coords: [{1, 2}], dimensions: [3, 4]}])
    assert tag =~ ~r(^<rect .*/>$)
    assert tag =~ ~r(y="2")
    assert tag =~ ~r(x="1")
    assert tag =~ ~r(width="3")
    assert tag =~ ~r(height="4")
  end

  test "extract ellipse attributes" do
    tag =
      SVG.render([
        %Tonic.Shape{
          name: :ellipse,
          coords: [{1, 2}],
          dimensions: [3, 4],
          attributes: %{fill: :black, stroke: :red}
        }
      ])

    assert tag =~ ~r(<ellipse .*/>)
    assert tag =~ ~r(cx="1")
    assert tag =~ ~r(cy="2")
    assert tag =~ ~r(rx="3")
    assert tag =~ ~r(ry="4")
    assert tag =~ ~r(fill="black")
    assert tag =~ ~r(stroke="red")
  end

  test "render polyline attributes" do
    tag =
      SVG.render([
        %Tonic.Shape{
          name: :polyline,
          coords: [{1, 2}, {3, 4}, {5, 6}],
          attributes: %{stroke: :black}
        }
      ])

    assert tag =~ ~r(<polyline .*/>)
    assert tag =~ ~r(points="1,2 3,4 5,6")
    assert tag =~ ~r(stroke="black")
  end

  test "render nested tags" do
    tag =
      [
        %Tonic.Shape{
          name: :group,
          attributes: %{id: "test"},
          children: [
            %Tonic.Shape{name: :rect, coords: [{1, 2}], dimensions: [3, 4]}
          ]
        }
      ]
      |> SVG.render()

    assert tag =~ ~r(^<group .*<rect .*/></group>$)
  end

  test "render nested tags preserves order" do
    tag =
      SVG.render([
        %Tonic.Shape{
          name: :group,
          children: [
            %Tonic.Shape{name: :rect, coords: [{1, 2}], dimensions: [3, 4]},
            %Tonic.Shape{name: :ellipse, coords: [{5, 6}], dimensions: [7, 8]}
          ]
        }
      ])

    assert tag =~ ~r(<group><ellipse .*/><rect)
  end

  test "render tag with transforms" do
    tag =
      SVG.render([
        %Tonic.Shape{
          name: :group,
          transforms: [
            %Tonic.Transform{type: :rotate, coords: {0, 1}, magnitude: 60},
            %Tonic.Transform{type: :translate, magnitude: {20, 30}}
          ]
        }
      ])

    # The transforms: member of %Tonic.Shape{} is a stack. The order of the 
    # transforms should be the same as the order they were added, the reverse 
    # of the list
    assert tag =~ ~r/<group transform="translate\(20 30\) rotate\(60 0 1\)"/
  end
end
