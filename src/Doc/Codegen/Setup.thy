theory Setup
imports
  Complex_Main
  "HOL-Library.Dlist"
  "HOL-Library.RBT"
  "HOL-Library.Mapping"
  "HOL-Library.IArray"
begin

ML_file "../antiquote_setup.ML"
ML_file "../more_antiquote.ML"

no_syntax (output)
  "_constrain" :: "logic => type => logic"  ("_::_" [4, 0] 3)
  "_constrain" :: "prop' => type => prop'"  ("_::_" [4, 0] 3)

syntax (output)
  "_constrain" :: "logic => type => logic"  ("_ :: _" [4, 0] 3)
  "_constrain" :: "prop' => type => prop'"  ("_ :: _" [4, 0] 3)

declare [[default_code_width = 74]]

declare [[names_unique = false]]

end
