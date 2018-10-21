open OUnit2
open ANSITerminal
open Board
open Player
open Board_state

(* General note to all those concerned.

   I am using laziness here so that unexpected exceptions raised by
   functions in tests will be traced correctly to the test that
   caused them. This approach lets us use the helper functions
   [gen_comp] and [except_comp] instead of making anonymous functions
   for every test.

   You use this by making every [actual] in a test a [lazy 'a]. If
   an [actual] requires the use of a previously defined [actual], then
   the function [(~$)] (shorthand for [Lazy.force]) can be used to
   expand the lazy within another lazy. *)

(* for brevity *)
let (~$) = Lazy.force

(** [gen_comp test_name actual expected printer] compares [actual] and 
    [expected] and prints with [printer]. *)
let gen_comp
    (test_name : string)
    (actual : 'a Lazy.t)
    (expected : 'a)
    (printer : 'a->string) =
  test_name >::
  (fun _ -> assert_equal expected (~$ actual) ~printer:printer)

(** [except_comp test_name actual except] tests to see that forcing
    [actual] produces exception [except]. *)
let except_comp
    (test_name : string)
    (actual : 'a Lazy.t)
    except =
  test_name >:: (fun _ -> assert_raises except (fun () -> (~$ actual)))

(* printers *)
let null _ = ""
let str s = s
let bool = string_of_bool
let int = string_of_int
let coord (x, y) = "{x: " ^ (int x) ^ "; y: " ^ (int y) ^ "}"
let player_p player = Player.player_name player
let opt p = function
  | Some x -> p x
  | None -> "none"

(** [pp_list pp_elt lst] pretty-prints list [lst], using [pp_elt]
    to pretty-print each element of [lst]. *)
let pp_list pp_elt lst =
  let pp_elts lst =
    let rec loop n acc = function
      | [] -> acc
      | [h] -> acc ^ pp_elt h
      | h1 :: (h2 :: t as t') ->
        if n = 100 then acc ^ "..."  (* stop printing long list *)
        else loop (n + 1) (acc ^ (pp_elt h1) ^ "; ") t'
    in loop 0 "" lst
  in "[" ^ pp_elts lst ^ "]"

(* test boards *)
let map_schema = lazy (from_json (Yojson.Basic.from_file "mapSchema.json"))

let board_tests = [
  gen_comp "board name" (lazy (board_name (~$ map_schema))) "Cornell" str;
  gen_comp "board ascii" (lazy (board_ascii (~$ map_schema))) "" str;
  gen_comp "nodes" (lazy (nodes (~$ map_schema)))
    (List.sort Pervasives.compare ["RPCC"; "JAM"; "LR7"; "HR5"; "Keeton"; "Rose"]) (pp_list str);
  gen_comp "has node" (lazy (has_node (~$ map_schema) "RPCC")) true bool;
  gen_comp "doesn't have node" (lazy (has_node (~$ map_schema) "foo")) false bool;
  gen_comp "node name" (lazy (node_name (~$ map_schema) "JAM")) "Just About Music" str;
  except_comp "invalid node" (lazy (node_name (~$ map_schema) "foo")) (UnknownNode "foo");
  gen_comp "node coords" (lazy (node_coords (~$ map_schema) "RPCC")) (4, 5) coord;
  gen_comp "node borders" (lazy (node_borders (~$ map_schema) "JAM"))
    (List.sort Pervasives.compare ["LR7"; "RPCC"]) (pp_list str);
  gen_comp "conts" (lazy (conts (~$ map_schema)))
    (List.sort Pervasives.compare ["North"; "West"]) (pp_list str);
  gen_comp "has cont" (lazy (has_cont (~$ map_schema) "North")) true bool;
  gen_comp "doesn't have cont" (lazy (has_cont (~$ map_schema) "foo")) false bool;
  gen_comp "cont name" (lazy (cont_name (~$ map_schema) "North")) "North Campus" str;
  except_comp "invalid cont" (lazy (cont_name (~$ map_schema) "foo")) (UnknownCont "foo");
  gen_comp "cont nodes" (lazy (List.sort Pervasives.compare (cont_nodes (~$ map_schema) "North")))
    (List.sort Pervasives.compare ["RPCC"; "JAM"; "LR7"]) (pp_list str);
]

let player_a = lazy (Player.create "player_a" Red)
let player_b = lazy (Player.create "player_b" Green)
let player_c = lazy (Player.create "player_c" Blue)

let player_tests = [
  gen_comp "player name" (lazy (player_name (~$ player_a))) "player_a" str;
  gen_comp "player color" (lazy (player_color (~$ player_a))) Red null;
]

let demo_players = lazy [
  ~$ player_a;
  ~$ player_b;
  ~$ player_c;
]

let false_player = lazy (Player.create "foo" Black)

let init_board_state = lazy (Board_state.init (~$ map_schema) (~$ demo_players))

let set_armies_state = lazy (set_army (~$ init_board_state) "JAM" 2)
let add_armies_state = lazy (place_army (place_army (~$ set_armies_state) "RPCC" 5) "JAM" 2)



let board_state_tests = [
  (* initial board state *)
  gen_comp "board state board"
    (lazy (board (~$ init_board_state))) (~$ map_schema) null;
  gen_comp "board state init node owner"
    (lazy (node_owner (~$ init_board_state) "RPCC")) None (opt player_p);
  gen_comp "board state init node army"
    (lazy (node_army (~$ init_board_state) "RPCC")) 0 int;
  gen_comp "board state init cont owner"
    (lazy (cont_owner (~$ init_board_state) "North")) None (opt player_p);
  gen_comp "board state init player nodes"
    (lazy (player_nodes (~$ init_board_state) (~$ player_a))) [] (pp_list str);
  gen_comp "board state init player conts"
    (lazy (player_conts (~$ init_board_state) (~$ player_a))) [] (pp_list str);
  gen_comp "board state init player army"
    (lazy (player_army (~$ init_board_state) (~$ player_a))) 0 int;

  (* exceptions *)
  except_comp "board state invalid node"
    (lazy (node_owner (~$ init_board_state) "foo")) (UnknownNode "foo");
  except_comp "board state invalid cont"
    (lazy (cont_owner (~$ init_board_state) "foo")) (UnknownCont "foo");
  except_comp "board state invalid player"
    (lazy (player_nodes (~$ init_board_state) (~$ false_player)))
    (UnknownPlayer (~$ false_player));

  (* armies *)

  gen_comp "board state set armies jam"
    (lazy (node_army (~$ set_armies_state) "JAM")) 2 int;
  gen_comp "board state set armies lr7"
    (lazy (node_army (~$ set_armies_state) "LR7")) 0 int;

  gen_comp "board state add armies jam"
    (lazy (node_army (~$ add_armies_state) "JAM")) 4 int;
  gen_comp "board state add armies rpcc"
    (lazy (node_army (~$ add_armies_state) "RPCC")) 5 int;
  gen_comp "board state add armies lr7"
    (lazy (node_army (~$ add_armies_state) "LR7")) 0 int;
]

let suite =
  "test suite for A678" >::: List.flatten [
    board_tests;
    player_tests;
    board_state_tests;
  ]

let () = run_test_tt_main suite
