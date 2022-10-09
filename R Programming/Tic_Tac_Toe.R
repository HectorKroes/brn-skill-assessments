player_symbol_chooser <- function() {
  symbol <- NA
  repeat {
    cat("X or O? ")
    symbol <- toupper(readLines(con = con, n = 1))
    if(symbol %in% c("X", "O")) {
      break
    }
    cat("Invalid symbol. Make sure to input either X or O.\n\n")
  }
  cat('You successfully selected', symbol)
  return(symbol)
}

pc_symbol_chooser <- function(player_symbol) {
  if (player_symbol=="X"){
    return("O")
    ---
  }else{
    return("X")
  }
}

round_enunciator <- function(x) {
  central_line <- paste(strrep('#', 7), "Round", x, strrep('#', 8))
  cat('\n', strrep('#', 24), central_line, strrep('#', 24), sep = '\n')
  x <- x + 1
  return(x)
}

board_setup <- function() {
  board <- matrix(NA, nrow = 3, ncol = 3)
  return(board)
}

display_board <- function() {
  
}

if (interactive()) {
  con <- stdin()
} else {
  con <- "stdin"
}

player_symbol <- player_symbol_chooser()

pc_symbol <- pc_symbol_chooser(player_symbol)

round <- round_enunciator(1)

board <- board_setup()