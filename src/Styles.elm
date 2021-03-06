module Styles exposing (..)

import Color as C
import Css exposing (..)
import Element as E exposing (Attribute, Color)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Svg
import Svg.Attributes as SA



---- COLORS ----


black : C.Color
black =
    C.black


white : Color
white =
    E.rgb255 255 255 255


backgroundColor : Color
backgroundColor =
    E.rgb255 24 36 43


primaryColor : Color
primaryColor =
    E.rgb255 87 22 206



--- GRID COLORS ----


occupiedColor : C.Color
occupiedColor =
    C.rgb255 221 95 53


unOccupiedColor : C.Color
unOccupiedColor =
    C.rgb255 98 99 112



----


explain =
    E.explain <| Debug.todo


container : List (Attribute msg)
container =
    [ E.height E.fill
    , E.width E.fill
    , Background.color backgroundColor
    ]


layout : List (Attribute msg)
layout =
    [ E.height E.fill
    , E.width E.fill
    ]


sidebarStyles : List (Attribute msg)
sidebarStyles =
    [ E.height <| E.fill
    , E.spaceEvenly
    , Border.widthEach { bottom = 0, right = 1, top = 0, left = 0 }
    , Border.color primaryColor
    , E.paddingXY 10 10
    , Border.shadow { offset = ( 2.0, 2.0 ), size = 2.0, blur = 10.0, color = primaryColor }
    ]


gridContainer : List (Attribute msg)
gridContainer =
    [ E.spaceEvenly
    , E.centerX
    , E.centerY
    , E.width E.fill
    , E.height E.fill
    ]


gridLayout : List (Attribute msg)
gridLayout =
    [ E.centerY
    , E.centerX
    , E.width E.fill
    , E.height E.fill
    ]


gridStyles : List (Attribute msg)
gridStyles =
    [ E.centerY
    , E.centerX
    ]


bookStyles : List (Attribute msg)
bookStyles =
    [ E.spaceEvenly
    , E.paddingXY 30 10
    , Border.width 10
    , E.width E.fill
    , E.height E.fill
    , Background.color <| E.rgb255 123 123 123
    ]



---- ICON STYLES ----


iconStyles : List (Svg.Attribute msg)
iconStyles =
    [ SA.color "#ffffff"
    ]


hiddenIcon : List (Attribute msg)
hiddenIcon =
    [ E.transparent True ]


patternDisplayStyles : List (Attribute msg)
patternDisplayStyles =
    [ E.centerY
    , E.centerX
    , Font.color white
    ]
