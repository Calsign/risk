open ANSITerminal
open Board
open Board_state
open Game_state
open Player
open Interface

(** [format_2digit num] is the 2 digit string representation of [num]. 
    Requires: 0 <= [num] <= 99 *)
let format_2digit (i : int) : string =
  if i < 10 then "0" ^ (string_of_int i) else (string_of_int i)

(** [draw_str s x y color] prints [s] at terminal coordinates [x,y] 
    in [color]. *)
let draw_str (s : string) (x : int) (y : int) (f : style list) : unit =
  ANSITerminal.set_cursor x y;
  ANSITerminal.print_string f s

(** [draw_nodes gamestate] populates the screen with all node army values at
    their corresponding coordinates in [gamestate]. *)
let draw_nodes (st : Interface.t) : unit = 
  let brd_st = game_state st |> Game_state.board_st in
  let brd = brd_st |> Board_state.board in
  Board.fold_nodes brd 
    (fun id () ->
       (* only redraw if node is owned by a player *)
       let x = Board.node_coords brd id |> Board.x
       in let y = Board.node_coords brd id |> Board.y
       in let is_cursor = cursor_node st = id
       in let is_selected = 
            from_fortify_node st = Some id || attacking_node st = Some id
       in let style = 
            match (Board_state.node_owner brd_st id),is_cursor,is_selected with
            | None,true,_ -> [Foreground Black; Background White]
            | None,false,_ -> [Foreground White;Background Black]
            | Some player,false,false 
              -> [Foreground (player_color player);Background Black]
            | Some player,false,true 
              -> [Foreground (player_color player);Background White]
            | Some player,true,_ 
              -> [Foreground White;Background (player_color player)]
       in draw_str (Board_state.node_army brd_st id |> format_2digit)
         (x + 1) (y + 1) style 
    ) ()

(** [draw_turn gamestate] prints the current turn information based
    on [gamestate]. *)
let draw_turn (st : Interface.t) : unit = 
  let player = game_state st |> current_player
  in print_string [Foreground (player_color player)] (player_name player);
  print_string [] " -- ";
  print_string [] begin
    match game_state st |> turn with
    | Null -> "Picking territories"
    | Reinforce _ -> "Reinforce " ^
                     (game_state st |> remaining_reinforcements |> string_of_int)
    | Attack AttackSelectA -> "Attack Select"
    | Attack DefendSelectA -> "Defend"
    | Attack OccupyA -> "eh"
    | Fortify FromSelectF -> "Fortify Select"
    | Fortify ToSelectF -> "Fortify To"
    | Fortify CountF -> "singularity"
  end;
  print_string [] "\n"

(** [draw_board gamestate] prints the board ascii with the nodes populated
    with information from the board state corresponding to [gamestate]. *)
let draw_board (st : Interface.t) : unit = 
  (* clear screen *)
  ANSITerminal.erase Screen;
  (* print topleft corner *)
  ANSITerminal.set_cursor 1 1; 
  (* print static board *)
  ANSITerminal.print_string [Foreground White] 
    (game_state st |> Game_state.board_st |> Board_state.board |> Board.board_ascii);
  (* populate nodes *)
  draw_nodes st;
  (* move to bottom of board *)
  set_cursor 0 (game_state st |> board_st |> Board_state.board |> board_ascii_height);
  print_string [] "\n";
  (* print out current turn information *)
  draw_turn st
