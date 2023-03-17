# Importing required libraries

import random
import time

# Symbol determination functions


def player_symbol_selector():
    symbol = input("X or O? ").upper()
    if symbol in ["X", "O"]:
        print("You successfully selected", symbol)
        return symbol
    else:
        print("Invalid symbol. Make sure to input either 'X' or 'O'.\n")
        return player_symbol_selector()


def pc_symbol_chooser(player_symbol):
    if player_symbol == "X":
        return "O"
    else:
        return "X"


# Round declaration function


def round_enunciator(round_num):
    central_line = f"{7*'#'} Round {str(round_num)} {8*'#'}"
    print(f"\n{24*'#'}\n{central_line}\n{24*'#'}")
    round_num += 1
    return round_num


# Defining board functionality


def board_setup():
    board = [["." for i in range(3)] for i in range(3)]
    return board


def display_board(board):
    separator = f"\n{24*'~'}\n"
    horizontal_divide = f"{5*'-'}+{5*'-'}+{+5*'-'}+{5*'-'}"
    print(
        f"\nCurrent board:\n{separator}\n{5*' '}|  1  |  2  |  3\n{horizontal_divide}"
    )
    for i in range(3):
        print(f"  {i+1}  |  {board[i][0]}  |  {board[i][1]}  |  {board[i][2]}")
        if i < 2:
            print(horizontal_divide)
        else:
            print(separator)


# Basic move verifications


def is_coord_valid(coord):
    if coord in ["1", "2", "3"]:
        return True
    else:
        return False


def is_coord_unnocupied(board, row, column):
    if board[row][column] == ".":
        return True
    else:
        return False


# Player move functions


def coord_prompter(coord_name):
    coord = input(f"Which {coord_name}? ")
    if is_coord_valid(coord):
        coord = int(coord) - 1
        return coord
    else:
        print("\nInvalid coordinate. Make sure to input either 1, 2 or 3.\n\n")
        return coord_prompter(coord_name)


def determine_placement(board):
    row = coord_prompter("row")
    column = coord_prompter("column")
    if is_coord_unnocupied(board, row, column):
        return row, column
    else:
        print("\nOccupied coordinate. Please select another one.\n\n")
        return determine_placement(board)


def confirm_placement(prompt, player_symbol, row, column, board):
    confirmation = input(
        f"Place {player_symbol} at row {row+1}, column {column+1}? [y/n] "
    ).upper()
    if confirmation == "Y":
        board[row][column] = player_symbol
        prompt = False
        return prompt, board
    elif confirmation == "N":
        return prompt, board
    else:
        print("\nInvalid input. Make sure to input either 'y' or 'n'.\n\n")
        return confirm_placement(prompt, player_symbol, row, column, board)


def prompt_move(prompt, board, player_symbol):
    row, column = determine_placement(board)
    prompt, board = confirm_placement(prompt, player_symbol, row, column, board)
    if prompt:
        prompt_move(prompt, board, player_symbol)
    else:
        return board


def player_move(board, player_symbol):
    prompt = True
    print(f"\nPlayer {player_symbol} turn\n")
    board = prompt_move(prompt, board, player_symbol)
    print("\nMove placed!\n\n")
    return board


# PC move functions


def check_line_for_opportunity(line):
    coord = None
    if "." in line:
        if len(list(set(line))) == 2:
            if line.count(".") == 1:
                coord = line.index(".")
                return coord
    return coord


def random_move(board):
    rand_row = random.choice(range(0, 3))
    rand_col = random.choice(range(0, 3))

    if is_coord_unnocupied(board, rand_row, rand_col):
        print(rand_row, rand_col)
        return rand_row, rand_col
    else:
        return random_move(board)


def pc_move_choice(board):
    for i in range(3):
        col = check_line_for_opportunity(board[i])
        if col is not None:
            return i, col
    for i in range(3):
        row = check_line_for_opportunity([board[0][i], board[1][i], board[2][i]])
        if row is not None:
            return row, i
    coord = check_line_for_opportunity([board[0][0], board[1][1], board[2][2]])
    if coord is not None:
        return coord, coord
    coord = check_line_for_opportunity([board[0][2], board[1][1], board[2][0]])
    if coord is not None:
        return coord, 3 - coord
    rand_row, rand_col = random_move(board)
    return rand_row, rand_col


def pc_move(board, pc_symbol):
    print(f"\nPlayer {pc_symbol} turn\n")
    row, col = pc_move_choice(board)
    board[row][col] = pc_symbol
    print("PC Move registered!\n\n")
    return board


# Win conditions checker functions


def check_line_for_win(line, player_symbol):
    if "." not in line:
        if len(list(set(line))) == 1:
            if line[0] == player_symbol:
                print("You won!")
                return True
            else:
                print("You lost!")
                return True
    return False


def check_win(board, player_symbol, pc_symbol):
    win = False
    for i in range(3):
        line_check = check_line_for_win(board[i], player_symbol)
        if line_check:
            return True
    for i in range(3):
        line_check = check_line_for_win(
            [board[0][i], board[1][i], board[2][i]], player_symbol
        )
        if line_check:
            return True
    if board[1][1] != ".":
        if (
            len(list(set([board[0][0], board[1][1], board[2][2]]))) == 1
            or len(list(set([board[0][2], board[1][1], board[2][0]]))) == 1
        ):
            if board[1][1] == player_symbol:
                print("You won!")
                return True
            elif board[1][1] == pc_symbol:
                print("You lost!")
                return True
        elif not any("." in line for line in board):
            print("Game over, no more space left!")
            return True
    return False


# Main game mechanisms


def turn(round_num, board, player_symbol, pc_symbol, win):
    round_num = round_enunciator(round_num)
    display_board(board)
    if player_symbol == "X":
        time.sleep(0.5)
        board = player_move(board, player_symbol)
        time.sleep(0.5)
        display_board(board)
        win = check_win(board, player_symbol, pc_symbol)
        if win:
            return win
        else:
            time.sleep(0.5)
            board = pc_move(board, pc_symbol)
    else:
        board = pc_move(board, pc_symbol)
        time.sleep(0.5)
        display_board(board)
        win = check_win(board, player_symbol, pc_symbol)
        if win:
            return win
        else:
            time.sleep(0.5)
            board = player_move(board, player_symbol)
    display_board(board)
    win = check_win(board, player_symbol, pc_symbol)
    if win:
        return win
    turn(round_num, board, player_symbol, pc_symbol, win)


def replay():
    confirmation = input("\n\nWant to play again? [y/n] ").upper()
    if confirmation == "Y":
        print("\n")
        game()
    elif confirmation == "N":
        print("\nThank you for playing! Until next time!")
    else:
        print("\nInvalid input. Make sure to input either 'y' or 'n'.")
        replay()


# Main function


def game():
    player_symbol = player_symbol_selector()
    pc_symbol = pc_symbol_chooser(player_symbol)
    board = board_setup()
    round_num = 1
    win = False
    turn(round_num, board, player_symbol, pc_symbol, win)
    replay()


game()