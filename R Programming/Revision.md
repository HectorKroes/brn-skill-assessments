# R Programming Tic Tac Toe Revision



## The Game

>1. The error doesn't display immediately after the user types an invalid row or column. Instead, it takes all the inputs and then returns an error. It'd be more useful if the game checks the validity of the user's input immediately.



>2. The waiting time for the board is a little bit longer, it can be optimized by reducing the amount of ```Sys.sleep(1) ``` arguments.

I inserted some of those sleep commands because I thought the game moved a bit too fast for me. But since you prefer it faster, I removed the time between the round enunciation and the exhibition of the current board and reduced the duration of the remaining sleep commands by half. By doing so, I think it should achieve a more optimized time while still not going too fast.
1
>3. After the game is finalized, it returns warnings. This may be due to initial *NA* placements while setting the board.
```
Thank you for playing! Until next time!Warning messages:
1: In player_move(board, player_symbol) : NAs introduced by coercion
2: In player_move(board, player_symbol) : NAs introduced by coercion
```

Upon a closer inspection, it seems this warning message occurs when you use as.numeric() to convert a vector in R to a numeric vector and there happen to be non-numerical values in the original vector. In the player_move function there are two lines which take the user input to determine the coordinates of their move. If the input is blank, the program would prompt the user to input other value, but not before using the as.numeric() with an NA value as argument, raising a warning. To avoid this, I changed the player_move and is_coord_valid to only transform the input to integer after it is verified as a valid input ('1', '2' or '3'), so it shouldn't raise warnings anymore. Other solution I initially considered was to use suppressWarnings() to bypass the warning, but this in not an ideal solution as it's not usually good practice to suppress meritous warnings.

>4. ``` Thank you for playing! Until next time!``` argument is a good example for user friendly software! Thank you.



## Code

>1. It's usually recommended to use *for loops* instead of ```repeat - break``` structures. Because ```repeat - break``` can act outer than desired in some cases. For a more detailed explanation, please [see.](https://stackoverflow.com/questions/3922599/is-it-a-bad-practice-to-use-break-in-a-for-loop)

While it may be generally recommended the use of for loops over repeat-break structures, in this situation for loops are not really a good alternative as repetition may be needed indefinitely until the player make a correct input. So to avoid the use of repeat-break, I substituted all repeats and whiles for self-calling functions.

>2. ```message("input")``` can also be used instead of ```cat("input")```.



>3. There is additional ```break``` statement [present.](https://github.com/HectorKroes/brn-skill-assessments/blob/main/R%20Programming/Tic_Tac_Toe.R#L267)

I just noticed there were two break statements one right after the other. I removed the extra one.

>4. The code is separated into functional chunks which is a great way to program a simple game as tic-tac-toe.



Keep up the good work! **- BRN SA Team**


