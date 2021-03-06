(*  Title:      Pure/Thy/latex.ML
    Author:     Markus Wenzel, TU Muenchen

LaTeX presentation elements -- based on outer lexical syntax.
*)

signature LATEX =
sig
  type text
  val string: string -> text
  val text: string * Position.T -> text
  val block: text list -> text
  val enclose_body: string -> string -> text list -> text list
  val output_text: text list -> string
  val output_positions: Position.T -> text list -> string
  val output_name: string -> string
  val output_ascii: string -> string
  val latex_control: Symbol.symbol
  val is_latex_control: Symbol.symbol -> bool
  val embed_raw: string -> string
  val output_symbols: Symbol.symbol list -> string
  val output_syms: string -> string
  val output_token: Token.T -> string
  val begin_delim: string -> string
  val end_delim: string -> string
  val begin_tag: string -> string
  val end_tag: string -> string
  val environment_block: string -> text list -> text
  val environment: string -> string -> string
  val isabelle_body: string -> text list -> text list
  val theory_entry: string -> string
  val latexN: string
end;

structure Latex: LATEX =
struct

(* text with positions *)

abstype text = Text of string * Position.T | Block of text list
with

fun string s = Text (s, Position.none);
val text = Text;
val block = Block;

fun output_text texts =
  let
    fun output (Text (s, _)) = Buffer.add s
      | output (Block body) = fold output body;
  in Buffer.empty |> fold output texts |> Buffer.content end;

fun output_positions file_pos texts =
  let
    fun position (a, b) = enclose "%:%" "%:%" (a ^ "=" ^ b);
    fun add_position p positions =
      let val s = position (apply2 Value.print_int p)
      in positions |> s <> hd positions ? cons s end;

    fun output (Text (s, pos)) (positions, line) =
          let
            val positions' =
              (case Position.line_of pos of
                NONE => positions
              | SOME l => add_position (line, l) positions);
            val line' = fold_string (fn c => fn n => if c = "\n" then n + 1 else n) s line;
          in (positions', line') end
      | output (Block body) res = fold output body res;
  in
    (case Position.file_of file_pos of
      NONE => ""
    | SOME file =>
        ([position (Markup.fileN, file), "\\endinput"], 1)
        |> fold output texts |> #1 |> rev |> cat_lines)
  end;

end;

fun enclose_body bg en body = string bg :: body @ [string en];


(* output name for LaTeX macros *)

val output_name =
  translate_string
    (fn "_" => "UNDERSCORE"
      | "'" => "PRIME"
      | "0" => "ZERO"
      | "1" => "ONE"
      | "2" => "TWO"
      | "3" => "THREE"
      | "4" => "FOUR"
      | "5" => "FIVE"
      | "6" => "SIX"
      | "7" => "SEVEN"
      | "8" => "EIGHT"
      | "9" => "NINE"
      | s => s);

fun enclose_name bg en = enclose bg en o output_name;


(* output verbatim ASCII *)

val output_ascii =
  translate_string
    (fn " " => "\\ "
      | "\t" => "\\ "
      | "\n" => "\\isanewline\n"
      | s =>
          if exists_string (fn s' => s = s') "\"#$%&',-<>\\^_`{}~"
          then enclose "{\\char`\\" "}" s else s);


(* output symbols *)

val latex_control = "\<^latex>";
fun is_latex_control s = s = latex_control;

val embed_raw = prefix latex_control o cartouche;

local

val char_table =
  Symtab.make
   [("\007", "{\\isacharbell}"),
    ("!", "{\\isacharbang}"),
    ("\"", "{\\isachardoublequote}"),
    ("#", "{\\isacharhash}"),
    ("$", "{\\isachardollar}"),
    ("%", "{\\isacharpercent}"),
    ("&", "{\\isacharampersand}"),
    ("'", "{\\isacharprime}"),
    ("(", "{\\isacharparenleft}"),
    (")", "{\\isacharparenright}"),
    ("*", "{\\isacharasterisk}"),
    ("+", "{\\isacharplus}"),
    (",", "{\\isacharcomma}"),
    ("-", "{\\isacharminus}"),
    (".", "{\\isachardot}"),
    ("/", "{\\isacharslash}"),
    (":", "{\\isacharcolon}"),
    (";", "{\\isacharsemicolon}"),
    ("<", "{\\isacharless}"),
    ("=", "{\\isacharequal}"),
    (">", "{\\isachargreater}"),
    ("?", "{\\isacharquery}"),
    ("@", "{\\isacharat}"),
    ("[", "{\\isacharbrackleft}"),
    ("\\", "{\\isacharbackslash}"),
    ("]", "{\\isacharbrackright}"),
    ("^", "{\\isacharcircum}"),
    ("_", "{\\isacharunderscore}"),
    ("`", "{\\isacharbackquote}"),
    ("{", "{\\isacharbraceleft}"),
    ("|", "{\\isacharbar}"),
    ("}", "{\\isacharbraceright}"),
    ("~", "{\\isachartilde}")];

fun output_chr " " = "\\ "
  | output_chr "\t" = "\\ "
  | output_chr "\n" = "\\isanewline\n"
  | output_chr c =
      (case Symtab.lookup char_table c of
        SOME s => s
      | NONE => if Symbol.is_ascii_digit c then enclose "{\\isadigit{" "}}" c else c);

fun output_sym sym =
  (case Symbol.decode sym of
    Symbol.Char s => output_chr s
  | Symbol.UTF8 s => s
  | Symbol.Sym s => enclose_name "{\\isasym" "}" s
  | Symbol.Control s => enclose_name "\\isactrl" " " s
  | Symbol.Malformed s => error (Symbol.malformed_msg s)
  | Symbol.EOF => error "Bad EOF symbol");

val scan_latex_length =
  Scan.many1 (fn (s, _) => Symbol.not_eof s andalso not (is_latex_control s))
    >> (Symbol.length o map Symbol_Pos.symbol) ||
  Scan.one (is_latex_control o Symbol_Pos.symbol) --
    Scan.option (Scan.permissive Symbol_Pos.scan_cartouche "") >> K 0;

val scan_latex =
  Scan.one (is_latex_control o Symbol_Pos.symbol) |--
    Symbol_Pos.scan_cartouche_content "Embedded LaTeX: " >> (implode o map Symbol_Pos.symbol) ||
  Scan.one (Symbol.not_eof o Symbol_Pos.symbol) >> (output_sym o Symbol_Pos.symbol);

fun read scan syms =
  Scan.read Symbol_Pos.stopper (Scan.repeat scan) (map (rpair Position.none) syms);

in

fun length_symbols syms =
  fold Integer.add (these (read scan_latex_length syms)) 0;

fun output_symbols syms =
  if exists is_latex_control syms then
    (case read scan_latex syms of
      SOME ss => implode ss
    | NONE => error ("Malformed embedded LaTeX: " ^ quote (Symbol.beginning 10 syms)))
  else implode (map output_sym syms);

val output_syms = output_symbols o Symbol.explode;

val output_syms_antiq =
  (fn Antiquote.Text ss => output_symbols (map Symbol_Pos.symbol ss)
    | Antiquote.Control {name = (name, _), body, ...} =>
        "\\isaantiqcontrol{" ^ output_symbols (Symbol.explode name) ^ "}" ^
        output_symbols (map Symbol_Pos.symbol body)
    | Antiquote.Antiq {body, ...} =>
        enclose "%\n\\isaantiq\n" "{}%\n\\endisaantiq\n"
          (output_symbols (map Symbol_Pos.symbol body)));

end;


(* output token *)

fun output_token tok =
  let
    val s = Token.content_of tok;
    val output =
      if Token.is_kind Token.Comment tok then ""
      else if Token.is_command tok then
        "\\isacommand{" ^ output_syms s ^ "}"
      else if Token.is_kind Token.Keyword tok andalso Symbol.is_ascii_identifier s then
        "\\isakeyword{" ^ output_syms s ^ "}"
      else if Token.is_kind Token.String tok then
        enclose "{\\isachardoublequoteopen}" "{\\isachardoublequoteclose}" (output_syms s)
      else if Token.is_kind Token.Alt_String tok then
        enclose "{\\isacharbackquoteopen}" "{\\isacharbackquoteclose}" (output_syms s)
      else if Token.is_kind Token.Verbatim tok then
        let
          val ants = Antiquote.read (Token.input_of tok);
          val out = implode (map output_syms_antiq ants);
        in enclose "{\\isacharverbatimopen}" "{\\isacharverbatimclose}" out end
      else if Token.is_kind Token.Cartouche tok then
        enclose "{\\isacartoucheopen}" "{\\isacartoucheclose}" (output_syms s)
      else output_syms s;
  in output end
  handle ERROR msg => error (msg ^ Position.here (Token.pos_of tok));


(* tags *)

val begin_delim = enclose_name "%\n\\isadelim" "\n";
val end_delim = enclose_name "%\n\\endisadelim" "\n";
val begin_tag = enclose_name "%\n\\isatag" "\n";
fun end_tag tg = enclose_name "%\n\\endisatag" "\n" tg ^ enclose "{\\isafold" "}%\n" tg;


(* theory presentation *)

fun environment_delim name =
 ("%\n\\begin{" ^ output_name name ^ "}%\n",
  "%\n\\end{" ^ output_name name ^ "}");

fun environment_block name = environment_delim name |-> enclose_body #> block;
fun environment name = environment_delim name |-> enclose;

fun isabelle_body name =
  enclose_body
   ("%\n\\begin{isabellebody}%\n\\setisabellecontext{" ^ output_syms name ^ "}%\n")
   "%\n\\end{isabellebody}%\n";

fun theory_entry name = "\\input{" ^ name ^ ".tex}\n\n";


(* print mode *)

val latexN = "latex";

fun latex_output str =
  let val syms = Symbol.explode str
  in (output_symbols syms, length_symbols syms) end;

fun latex_markup (s, _) =
  if s = Markup.commandN orelse s = Markup.keyword1N orelse s = Markup.keyword3N
  then ("\\isacommand{", "}")
  else if s = Markup.keyword2N
  then ("\\isakeyword{", "}")
  else Markup.no_output;

fun latex_indent "" _ = ""
  | latex_indent s _ = enclose "\\isaindent{" "}" s;

val _ = Output.add_mode latexN latex_output embed_raw;
val _ = Markup.add_mode latexN latex_markup;
val _ = Pretty.add_mode latexN latex_indent;

end;
