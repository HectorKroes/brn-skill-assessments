# R Programming Tic Tac Toe Revision

## The Game

>1. The error doesn't display immediately after the user types an invalid row or column. Instead, it takes all the inputs and then returns an error. It'd be more useful if the game checks the validity of the user's input immediately.

Change implemented! Now the program will inform immediately after each input if it wasn't valid and prompt the user for a valid input again. This was done by the fragmentation of the old determine_placement function and consequent creation of the coord_prompter function, which prompts and verifies the coordinates individually and returns a value only when the input was a valid coordinate.

>2. The waiting time for the board is a little bit longer, it can be optimized by reducing the amount of ```Sys.sleep(1) ``` arguments.

I inserted some of those sleep commands because I thought the game moved a bit too fast for me. But since you seem to prefer it faster, I removed the time between the round enunciation and the exhibition of the current board and reduced the duration of the remaining sleep commands by half. By doing so, I think it should achieve a more optimized time while still not going too fast.

```
Previously:
6 x 1 second sleeps

Now:
5 x 0.5 seconds sleeps
```

>3. After the game is finalized, it returns warnings. This may be due to initial *NA* placements while setting the board.
```
Thank you for playing! Until next time!Warning messages:
1: In player_move(board, player_symbol) : NAs introduced by coercion
2: In player_move(board, player_symbol) : NAs introduced by coercion
```

Upon a closer inspection, it seems that this warning message occurs when you use as.numeric() trying to convert a vector containing non-numeric values to a numeric vector. In the old player_move function there are two lines which take the user input to determine the coordinates of their move. If the input was blank, the program would prompt the user to input other value, but not before using the as.numeric() with an NA value as argument, raising a warning. To avoid this, I changed the player_move and is_coord_valid functions to only transform the input to integer after it is verified as a valid input ('1', '2' or '3'), so it shouldn't raise warnings anymore. Other solution I initially considered was to use suppressWarnings() to bypass the warning, but this is not an ideal solution as it's not usually good practice to suppress meritous warnings.

>4. ``` Thank you for playing! Until next time!``` argument is a good example for user friendly software! Thank you.

Friendliness was what I aimed at. I'm glad it showed.

## Code

>1. It's usually recommended to use *for loops* instead of ```repeat - break``` structures. Because ```repeat - break``` can act outer than desired in some cases. For a more detailed explanation, please [see.](https://stackoverflow.com/questions/3922599/is-it-a-bad-practice-to-use-break-in-a-for-loop)

While it may be generally recommended the use of for loops over repeat-break structures, in this situation for loops are not really a good alternative as repetition may be needed indefinitely until the player make a correct input. So to avoid the use of repeat-break, I substituted all repeats and whiles for self-calling functions.

>2. ```message("input")``` can also be used instead of ```cat("input")```.

Changed some cats into messages to highlight important information.

>3. There is additional ```break``` statement [present.](https://github.com/HectorKroes/brn-skill-assessments/blob/main/R%20Programming/Tic_Tac_Toe.R#L267)

I just noticed there were two break statements one right after the other. I removed the extra one while I removed the repeat-break structures.

>4. The code is separated into functional chunks which is a great way to program a simple game as tic-tac-toe.

When I started coding, I would usually write my programs as long blocks of code (multiple hundred lines long). As time passed and I learned more, it became clear to me that having a better code organization usually pays up.

## If there's anything more I should change, please let me know. Thank you very much for the thoughtful review!