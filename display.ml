open ANSITerminal
open Board
open Board_state
open Game_state

(** TODO: make nicer ascii map for demo *)
(** TODO: make errors look nicer *)
(** TODO: display turn information *)
(** TODO: draw something nicer when node is not owned *)

(** [format_2digit num] is the 2 digit string representation of [num]. 
    Requires: 0 <= [num] <= 99 *)
let format_2digit (i : int) : string =
  if i < 10 then "0" ^ (string_of_int i) else (string_of_int i)

(** [draw_str s x y color] prints [s] at terminal coordinates [x,y] 
    in [color]. *)
let draw_str (s : string) (x : int) (y : int) (c : color) : unit =
  ANSITerminal.set_cursor x y;
  ANSITerminal.print_string [Foreground c] s

(** [draw_nodes gamestate] populates the screen with all node army values at
    their corresponding coordinates in [gamestate]. *)
let draw_nodes (gs : Game_state.t) : unit = 
  let brd_st = gs |> Game_state.board_st in
  let brd = brd_st |> Board_state.board in
  Board.fold_nodes brd 
    (fun id () -> 
       (* only redraw if node is owned by a player *)
       match (Board_state.node_owner brd_st id) with
       | Some player ->
         draw_str (Board_state.node_army brd_st id |> format_2digit)
           (Board.node_coords brd id |> Board.x |> ( * ) 2 |> (+) 1)
           (Board.node_coords brd id |> Board.y |> (+) 1)
           (Player.player_color player)
       | None -> ()
    ) ()

(** [draw_board gamestate] prints the board ascii with the nodes populated
    with information from the board state corresponding to [gs]. *)
let draw_board (gs : Game_state.t) : unit = 
  (* clear screen *)
  ANSITerminal.erase Screen;
  (* print topleft corner *)
  ANSITerminal.set_cursor 1 1; 
  (* print static board *)
  ANSITerminal.print_string [Foreground White] 
    (gs |> Game_state.board_st |> Board_state.board |> Board.board_ascii);
  (* populate nodes *)
  draw_nodes gs;
  (* add some extra space at bottom - fix this later *)
  let () = Printf.printf "\n" in ()

(** [draw_turn gamestate] prints the current turn information based
    on [gamestate]. *)
let draw_turn (gs : Game_state.t) : unit = 
  (* print current player *)
  Printf.printf "\n\nCurrent player: ";
  ANSITerminal.print_string 
    [Foreground (gs |> Game_state.current_player |> Player.player_color)]
    (gs |> Game_state.current_player |> Player.player_name);
  (* print turn type *)
  Printf.printf "\nTurn type: ";
  ANSITerminal.print_string (* todo: colors for turn type? *)
    [Foreground White] (Game_state.turn_to_str gs);
  (* print remaining reinforcements or attack info? *)
  match (gs |> turn) with
  | Reinforce -> Printf.printf "\nRemaining reinforcements: ";
    ANSITerminal.print_string 
      [Foreground (gs |> Game_state.current_player |> Player.player_color)]
      (gs |> Game_state.remaining_reinforcements |> string_of_int)
  | Attack ->
    Printf.printf "\ntodo: print attack info"