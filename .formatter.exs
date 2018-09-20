# Used by "mix format"
[
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"],
  line_length: 120,
  locals_without_parens: [
    # Kernel
    inspect: 1,
    inspect: 2
  ]
]
