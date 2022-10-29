# Symbol chooser functions
symbol_verifier <- function() {
  cat("X or O? ")
  symbol <- toupper(readLines(con = con, n = 1))
  if (symbol %in% c("X", "O")) {
    return(symbol)
  }
  cat("Invalid symbol. Make sure to input either 'X' or 'O.'\n\n")
  symbol_verifier()
}

player_symbol_chooser <- function() {
  symbol <- symbol_verifier()
  cat("You successfully selected", symbol)
  return(symbol)
}

pc_symbol_chooser <- function(player_symbol) {
  if (player_symbol == "X") {
    return("O")
  } else {
    return("X")
  }
}

# Round declaration function
round_enunciator <- function(round_num) {
  central_line <- paste(strrep("#", 7), "Round", round_num, strrep("#", 8))
  cat("\n", strrep("#", 24), central_line, strrep("#", 24), "", sep = "\n")
  round_num <- round_num + 1
  return(round_num)
}

# Board setup and display functions
board_setup <- function() {
  board <- matrix(NA, nrow = 3, ncol = 3)
  return(board)
}

display_board <- function(board) {
  separator <- paste(strrep("~", 25), "\n")
  cat("Current board:\n")
  cat(separator)
  print(board)
  cat(separator)
}

# Coordinate validation functions
is_coord_valid <- function(coord) {
  if (coord %in% c("1", "2", "3")) {
    return(TRUE)
  } else {
    return(FALSE)
  }
}

is_coord_unnocupied <- function(board, row, column) {
  if (is.na(board[row, column])) {
    return(TRUE)
  } else {
    return(FALSE)
  }
}

# Player move prompt function

determine_placement <- function(board) {
  cat("Which row? ")
  row <- readLines(con = con, n = 1)
  cat("Which column? ")
  column <- readLines(con = con, n = 1)
  row_valid <- is_coord_valid(row)
  column_valid <- is_coord_valid(column)
  if (row_valid & column_valid) {
    row <- as.numeric(row)
    column <- as.numeric(column)
    coord_unnocupied <- is_coord_unnocupied(board, row, column)
    if (coord_unnocupied) {
      return(c(row, column))
    } else {
      cat("\nOccupied coordinate. Please select another one.\n\n")
    }
  } else {
    cat("\nInvalid coordinate. Make sure to input either 1, 2 or 3.\n\n")
  }
  determine_placement()
}

confirm_placement <- function(prompt, player_symbol, row, column, board) {
  cat("Place ", player_symbol, " at row ", row, ", column ", column, "? [y/n] ", sep = "")
  confirmation <- toupper(readLines(con = con, n = 1))
  if (confirmation == "Y") {
    board[row, column] <- player_symbol
    prompt <- FALSE
    return(c(prompt, board))
  } else if (confirmation == "N") {
    return(c(prompt, board))
  } else {
    cat("\nInvalid input. Make sure to input either 'y' or 'n'.\n\n")
  }
  confirm_placement(prompt, player_symbol, row, column, board)
}

prompt_move <- function(prompt, board, player_symbol) {
  coordinates <- determine_placement(board)
  row <- coordinates[1]
  column <- coordinates[2]
  res <- confirm_placement(prompt, player_symbol, row, column, board)
  prompt <- res[1]
  board <- matrix(res[2:10], nrow = 3, ncol = 3)
  if (prompt) {
    prompt_move(prompt, board, player_symbol)
  } else {
    return(board)
  }
}

player_move <- function(board, player_symbol) {
  prompt <- TRUE
  message("\nPlayer ", player_symbol, " turn\n")
  board <- prompt_move(prompt, board, player_symbol)
  cat("\nMove placed!\n\n")
  return(board)
}

# PC move prompt functions
check_line_for_opportunity <- function(line) {
  coord <- NA
  if (NA %in% line) {
    if (length(unique(line)) == 2) {
      if (sum(is.na(line)) == 1) {
        coord <- which(is.na(line))
        return(coord)
      }
    }
  }
  return(coord)
}

random_move <- function(board) {
  rand_row <- sample(1:3, 1)
  rand_col <- sample(1:3, 1)
  if (is_coord_unnocupied(board, rand_row, rand_col)) {
    move <- c(rand_row, rand_col)
    return(move)
  }
  random_move(board)
}

pc_move_choice <- function(board) {
  move <- NA
  for (i in 1:nrow(board)) {
    col <- check_line_for_opportunity(board[i, ])
    if (!is.na(col)) {
      move <- c(i, col)
      return(move)
    }
  }
  for (i in 1:ncol(board)) {
    row <- check_line_for_opportunity(board[, i])
    if (!is.na(row)) {
      move <- c(row, i)
      return(move)
    }
  }
  first_horizontal <- c(board[1, 1], board[2, 2], board[3, 3])
  coord <- check_line_for_opportunity(first_horizontal)
  if (!is.na(coord)) {
    move <- c(coord, coord)
    return(move)
  }
  second_horizontal <- c(board[1, 3], board[2, 2], board[3, 1])
  coord <- check_line_for_opportunity(second_horizontal)
  if (!is.na(coord)) {
    move <- c(coord, 4 - coord)
    return(move)
  }
  move <- random_move(board)
  return(move)
}

pc_move <- function(board, pc_symbol) {
  cat("\nPlayer", pc_symbol, "turn\n")
  move <- pc_move_choice(board)
  row <- move[1]
  col <- move[2]
  board[row, col] <- pc_symbol
  cat("PC Move registered!\n\n")
  return(board)
}

# Win conditions checker functions
check_line_for_win <- function(line, player_symbol) {
  if (!(NA %in% line)) {
    if (length(unique(line)) == 1) {
      if (unique(line) == player_symbol) {
        cat("You won!")
        return(TRUE)
      } else {
        cat("You lost!")
        return(TRUE)
      }
    }
  }
  return(FALSE)
}

check_win <- function(board, player_symbol, pc_symbol) {
  win <- FALSE
  for (i in 1:ncol(board)) {
    line_check <- check_line_for_win(board[, i], player_symbol)
    if (line_check) {
      return(TRUE)
    }
  }
  for (i in 1:nrow(board)) {
    line_check <- check_line_for_win(board[i, ], player_symbol)
    if (line_check) {
      return(TRUE)
    }
  }
  if (!is.na(board[2, 2])) {
    if (length(unique(c(board[1, 1], board[2, 2], board[3, 3]))) == 1 || length(unique(c(board[3, 1], board[2, 2], board[1, 3]))) == 1) {
      if (board[2, 2] == player_symbol) {
        cat("You won!")
        return(TRUE)
      } else if (board[2, 2] == pc_symbol) {
        cat("You lost!")
        return(TRUE)
      }
    } else if (!any(is.na(board))) {
      cat("Game over, no more space left!")
      return(TRUE)
    }
  }
  return(FALSE)
}

if (interactive()) {
  con <- stdin()
} else {
  con <- "stdin"
}

turn <- function(round, board, player_symbol, pc_symbol, win) {
  round <- round_enunciator(round)
  display_board(board)
  if (player_symbol == "X") {
    Sys.sleep(0.5)
    board <- player_move(board, player_symbol)
    Sys.sleep(0.5)
    display_board(board)
    win <- check_win(board, player_symbol, pc_symbol)
    if (win) {
      return(win)
    } else {
      Sys.sleep(0.5)
      board <- pc_move(board, pc_symbol)
    }
  } else {
    board <- pc_move(board, pc_symbol)
    Sys.sleep(0.5)
    display_board(board)
    win <- check_win(board, player_symbol, pc_symbol)
    if (win) {
      return(win)
    } else {
      Sys.sleep(0.5)
      board <- player_move(board, player_symbol)
    }
  }
  display_board(board)
  win <- check_win(board, player_symbol, pc_symbol)
  turn(round, board, player_symbol, pc_symbol, win)
}

replay <- function() {
  cat("\n\nWant to play again? [y/n] ")
  confirmation <- toupper(readLines(con = con, n = 1))
  if (confirmation == "Y") {
    cat("\n")
    game()
  } else if (confirmation == "N") {
    cat("\nThank you for playing! Until next time!")
    break
  } else {
    cat("\nInvalid input. Make sure to input either 'y' or 'n'.")
    replay()
  }
}

# Main function
game <- function() {
  player_symbol <- player_symbol_chooser()
  pc_symbol <- pc_symbol_chooser(player_symbol)
  board <- board_setup()
  round <- 1
  win <- FALSE
  turn(round, board, player_symbol, pc_symbol, win)
  replay()
}

game()
