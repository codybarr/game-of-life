module Main exposing (..)

import Browser
import CellGrid as CG
import CellGrid.Render as CGR
import Color
import Dict exposing (Dict)
import Element as E exposing (Attribute, Element)
import Element.Input as Input
import FeatherIcons
import Html exposing (Html)
import List.Extra exposing (andThen)
import Maybe.Extra exposing (isJust)
import Patterns
    exposing
        ( BoxStatus(..)
        , Coordinates
        , Pattern(..)
        , getPattern
        , maybePatternToString
        , patternList
        )
import Styles exposing (black, bookStyles, container, gridContainer, gridLayout, gridStyles, hiddenIcon, iconStyles, layout, occupiedColor, patternDisplayStyles, sidebarStyles, unOccupiedColor)
import Time


type Mode
    = Init
    | Play
    | Pause


type BookStatus
    = Open
    | Closed


type Rule
    = Rule Born Survive


type alias Born =
    List Int


type alias Survive =
    List Int



---- SPEED ----


type Speed
    = Slow
    | Normal
    | Fast


increaseSpeed : Speed -> Speed
increaseSpeed spd =
    case spd of
        Slow ->
            Normal

        Normal ->
            Fast

        Fast ->
            Fast


decreaseSpeed : Speed -> Speed
decreaseSpeed spd =
    case spd of
        Fast ->
            Normal

        Normal ->
            Slow

        Slow ->
            Slow


speedToString : Speed -> String
speedToString spd =
    case spd of
        Slow ->
            "Slow"

        Normal ->
            "Normal"

        Fast ->
            "Fast"


speedToValue : Speed -> Int
speedToValue speed =
    case speed of
        Slow ->
            10

        Normal ->
            20

        Fast ->
            30



---- MODEL ----


type alias Model =
    { height : Int
    , width : Int
    , cellSize : Float
    , pattern : Maybe Pattern
    , boxes : Dict Coordinates BoxStatus
    , mode : Mode
    , speed : Speed
    , bookStatus : BookStatus
    }


init : Int -> ( Model, Cmd Msg )
init initialWidth =
    ( { width = initialWidth
      , height = 70
      , cellSize = 10.0
      , pattern = Just Patterns.defaultPattern
      , boxes = Patterns.default initialWidth 70
      , mode = Init
      , speed = Normal
      , bookStatus = Closed
      }
    , Cmd.none
    )



---- UPDATE ----


type Msg
    = NoOp
    | CellGridMsg CGR.Msg
    | Tick Time.Posix
    | ChangeMode Mode
    | IncreaseSpeed
    | DecreaseSpeed
    | ChangePattern Pattern
    | ChangeWidth Int
    | ChangeHeight Int
    | ToggleBookStatus
    | Reset


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        CellGridMsg cellMsg ->
            if model.mode == Init then
                let
                    coordinates =
                        ( cellMsg.cell.row, cellMsg.cell.column )

                    updatedDict =
                        updateCell coordinates model.boxes
                in
                ( { model | boxes = updatedDict, pattern = Nothing }, Cmd.none )

            else
                ( model, Cmd.none )

        Tick _ ->
            ( { model | boxes = applyGameOfLifeRules model.boxes }, Cmd.none )

        IncreaseSpeed ->
            ( { model | speed = increaseSpeed model.speed }, Cmd.none )

        DecreaseSpeed ->
            ( { model | speed = decreaseSpeed model.speed }, Cmd.none )

        ChangeMode prevMode ->
            let
                newMode =
                    case prevMode of
                        Init ->
                            Play

                        Play ->
                            Pause

                        Pause ->
                            Play
            in
            ( { model | mode = newMode }, Cmd.none )

        ChangePattern ptr ->
            ( { model | pattern = Just ptr, boxes = getPattern ptr model.width model.height, bookStatus = Closed }, Cmd.none )

        Reset ->
            let
                ptr =
                    Maybe.withDefault Patterns.defaultPattern model.pattern
            in
            ( { model
                | mode = Init
                , boxes = getPattern ptr model.width model.height
                , pattern = Just Patterns.defaultPattern
              }
            , Cmd.none
            )

        ChangeWidth n ->
            ( { model | width = model.width + n }, Cmd.none )

        ChangeHeight n ->
            ( { model | height = model.height + n }, Cmd.none )

        ToggleBookStatus ->
            ( { model | bookStatus = toggleBookStatus model.bookStatus }, Cmd.none )



---- VIEW ----


view : Model -> Html Msg
view { height, width, cellSize, mode, boxes, speed, bookStatus, pattern } =
    E.layout [] <|
        E.el container <|
            E.row layout
                [ sidebar mode speed bookStatus
                , E.column (gridContainer ++ [ E.inFront <| book bookStatus ]) <|
                    [ E.el patternDisplayStyles <| E.text <| ("Current Pattern: " ++ maybePatternToString pattern)
                    , E.el gridLayout <| E.el gridStyles <| drawGrid height width cellSize boxes mode
                    ]
                ]


drawGrid : Int -> Int -> Float -> Dict Coordinates BoxStatus -> Mode -> Element Msg
drawGrid height width cellSize boxes mode =
    let
        dimensions =
            { width = width * Basics.round cellSize
            , height = height * Basics.round cellSize
            }

        cellStyle =
            { cellWidth = cellSize
            , cellHeight = cellSize
            , toColor = toColor
            , gridLineWidth = 1
            , gridLineColor = black
            }

        cellGrid =
            CG.initialize { rows = height, columns = width } (getBoxStatus boxes)
    in
    E.html <|
        Html.map CellGridMsg <|
            CGR.asHtml
                dimensions
                cellStyle
                cellGrid


sidebar : Mode -> Speed -> BookStatus -> Element Msg
sidebar mode speed bookStatus =
    let
        toggleBookStatusButton =
            Input.button [ E.centerY ] { onPress = Just ToggleBookStatus, label = bookIcon bookStatus }
    in
    E.column sidebarStyles
        [ Input.button (sidebarButtonStyles bookStatus) { onPress = Just IncreaseSpeed, label = increaseSpeedIcon }
        , E.text <| speedToString speed
        , Input.button (sidebarButtonStyles bookStatus) { onPress = Just DecreaseSpeed, label = decreaseSpeedIcon }
        , toggleBookStatusButton
        , Input.button (sidebarButtonStyles bookStatus) { onPress = Just <| Reset, label = resetIcon }
        , Input.button (sidebarButtonStyles bookStatus) { onPress = Just <| ChangeMode mode, label = getModeButtonIcon mode }
        ]


sidebarButtonStyles : BookStatus -> List (Attribute Msg)
sidebarButtonStyles bookStatus =
    case bookStatus of
        Open ->
            hiddenIcon

        Closed ->
            []


decreaseSpeedIcon : Element Msg
decreaseSpeedIcon =
    FeatherIcons.chevronsDown
        |> FeatherIcons.toHtml iconStyles
        |> E.html


increaseSpeedIcon : Element Msg
increaseSpeedIcon =
    FeatherIcons.chevronsUp
        |> FeatherIcons.toHtml iconStyles
        |> E.html


book : BookStatus -> Element Msg
book bs =
    case bs of
        Closed ->
            E.none

        Open ->
            E.wrappedRow bookStyles
                (patternList
                    |> List.map
                        (\( name, pattern ) ->
                            E.column []
                                [ E.image [] { src = placeholderImage, description = "pattern" }
                                , Input.button []
                                    { onPress = Just <| ChangePattern pattern
                                    , label = E.text <| name
                                    }
                                ]
                        )
                )


bookIcon : BookStatus -> Element Msg
bookIcon bs =
    case bs of
        Closed ->
            FeatherIcons.menu
                |> FeatherIcons.toHtml iconStyles
                |> E.html

        Open ->
            FeatherIcons.x
                |> FeatherIcons.toHtml iconStyles
                |> E.html


resetIcon : Element Msg
resetIcon =
    FeatherIcons.refreshCw
        |> FeatherIcons.toHtml iconStyles
        |> E.html


getModeButtonIcon : Mode -> Element Msg
getModeButtonIcon mode =
    case mode of
        Init ->
            FeatherIcons.play
                |> FeatherIcons.toHtml iconStyles
                |> E.html

        Play ->
            FeatherIcons.pause
                |> FeatherIcons.toHtml iconStyles
                |> E.html

        Pause ->
            FeatherIcons.play
                |> FeatherIcons.toHtml iconStyles
                |> E.html



---- PROGRAM ----


main : Program Int Model Msg
main =
    Browser.element
        { view = view
        , init = init
        , update = update
        , subscriptions = subscriptions
        }


subscriptions : Model -> Sub Msg
subscriptions { mode, speed } =
    case mode of
        Init ->
            Sub.none

        Pause ->
            Sub.none

        Play ->
            Time.every (2000 / (Basics.toFloat <| speedToValue speed)) Tick



---- HELPERS ----


toColor : BoxStatus -> Color.Color
toColor box =
    case box of
        Occupied ->
            occupiedColor

        _ ->
            unOccupiedColor


toggleStatus : BoxStatus -> BoxStatus
toggleStatus b =
    case b of
        Occupied ->
            UnOccupied

        UnOccupied ->
            Occupied


getBoxColor : Dict Coordinates BoxStatus -> Int -> Int -> Color.Color
getBoxColor boxes i j =
    let
        foundBox =
            Dict.get ( i, j ) boxes
    in
    case foundBox of
        Just status ->
            toColor status

        Nothing ->
            toColor UnOccupied


getBoxStatus : Dict Coordinates BoxStatus -> Int -> Int -> BoxStatus
getBoxStatus boxes i j =
    let
        foundBox =
            Dict.get ( i, j ) boxes
    in
    case foundBox of
        Just status ->
            status

        Nothing ->
            UnOccupied


updateCell : Coordinates -> Dict Coordinates BoxStatus -> Dict Coordinates BoxStatus
updateCell coords dict =
    let
        updateFunc : Maybe BoxStatus -> Maybe BoxStatus
        updateFunc currentStatus =
            case currentStatus of
                Nothing ->
                    Just Occupied

                Just _ ->
                    Nothing
    in
    Dict.update coords updateFunc dict


getNewBoxDict : Dict Coordinates BoxStatus -> Dict Coordinates BoxStatus -> Dict Coordinates BoxStatus
getNewBoxDict occupied dict =
    Dict.foldr
        (\k v acc ->
            case getNewStatus2 v << getCount k <| occupied of
                Occupied ->
                    Dict.insert k Occupied acc

                _ ->
                    acc
        )
        Dict.empty
        dict


getCount : Coordinates -> Dict Coordinates BoxStatus -> Int
getCount coords =
    Dict.foldr
        (\ok ov acc ->
            if isNeighbour coords ok then
                acc + 1

            else
                acc
        )
        0


applyGameOfLifeRules : Dict Coordinates BoxStatus -> Dict Coordinates BoxStatus
applyGameOfLifeRules boxes =
    boxes
        --     -- |> Debug.log "boxes"
        |> getNeighbourDict
        |> getNewBoxDict boxes


isNeighbour : Coordinates -> Coordinates -> Bool
isNeighbour ( i, j ) ( m, n ) =
    (i - 1 == m && j - 1 == n)
        || (i - 1 == m && j == n)
        || (i - 1 == m && j + 1 == n)
        || (i == m && j - 1 == n)
        || (i == m && j + 1 == n)
        || (i + 1 == m && j - 1 == n)
        || (i + 1 == m && j == n)
        || (i + 1 == m && j + 1 == n)


getNeighbourDict : Dict Coordinates BoxStatus -> Dict Coordinates BoxStatus
getNeighbourDict occupied =
    Dict.foldr (\k _ acc -> Dict.union acc (getNeighbours k)) occupied occupied


getNeighbourCoords : Coordinates -> List Coordinates
getNeighbourCoords ( r, c ) =
    [ ( r - 1, c - 1 )
    , ( r - 1, c )
    , ( r - 1, c + 1 )
    , ( r, c - 1 )
    , ( r, c + 1 )
    , ( r + 1, c - 1 )
    , ( r + 1, c )
    , ( r + 1, c + 1 )
    ]


getNeighbours : Coordinates -> Dict Coordinates BoxStatus
getNeighbours coords =
    coords
        |> getNeighbourCoords
        |> List.map (\n -> ( n, UnOccupied ))
        |> Dict.fromList



-- get new status of a box based on the count of its neighbours


getNewStatus : ( BoxStatus, Int ) -> BoxStatus
getNewStatus ( prevStatus, n ) =
    case prevStatus of
        Occupied ->
            if n == 2 || n == 3 then
                Occupied

            else
                UnOccupied

        UnOccupied ->
            if n == 3 then
                Occupied

            else
                UnOccupied


getNewStatus2 : BoxStatus -> Int -> BoxStatus
getNewStatus2 prevStatus n =
    case prevStatus of
        Occupied ->
            if n == 2 || n == 3 then
                Occupied

            else
                UnOccupied

        UnOccupied ->
            if n == 3 then
                Occupied

            else
                UnOccupied


toggleBookStatus : BookStatus -> BookStatus
toggleBookStatus bs =
    case bs of
        Open ->
            Closed

        Closed ->
            Open


placeholderImage =
    "https://via.placeholder.com/300"
