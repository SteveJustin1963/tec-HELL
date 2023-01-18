# TEC-1 Hellschreiber 
...see wiki

Hellschreiber is a machine-readable teleprinter communication that uses a combination of on and off dots to represent characters, similar to the way Morse code uses dots and dashes. It was invented in the 1920s and was commonly used in the 1930s and 1940s for telegraph communication. Instead of printing the characters on a sheet of paper, Hellschreiber displays the characters on a screen, making it a form of visual telegraphy. It was used in both point-to-point communication and for broadcasting messages over radio waves.

![](https://github.com/SteveJustin1963/tec-HELL/blob/master/pics/350px-Feldhell.jpg)

![](https://github.com/SteveJustin1963/tec-HELL/raw/master/pics/300px-Hellschreiber-schriftbild.gif)

![image](https://user-images.githubusercontent.com/58069246/213037768-53a5574c-3fd0-4efa-a273-16e327fc0925.png)


##  Project
- build the printer mechanism, the core
- code tec1 to controll tx and rx and printer/display system
  - tx/rx from 
    - MINT keypad 
    - Hex pad 
  - print to 
    - paper tape
    - 7seg
    - LCD matrix
    - small thermal printer  
- backup transmission to audio tape to print later 
 



# hell-tx 
## Pseudocode 
takes a string message as input and converts it to an 8x8 matrix of dots and sends them line by line like Hellschreiber.

The procedure iterates through each character in the input message, using the for loop. For each character, it retrieves the ASCII code of the character by calling the ASCII function. Then it enters two nested for loops, one for the rows and one for the columns of the 8x8 matrix, so that it can access each bit of the ASCII code.

The inner most for loop uses bitwise AND operator to check if the current bit of the ASCII code is 1 or 0. If the bit is 1, it prints a dot "." and if the bit is 0 it prints a blank " ".

After the innermost for loop, it goes to the next line to start printing the next row of the 8x8 matrix, this way it simulates the sending of the message line by line like Helscriber.

Please note that this is a high-level pseudocode, specific implementation details might vary depending on the programming language you use.

## Forth
This example defines a new Forth word called "convert-and-send", which takes the address and length of a message as input. It uses a "DO" loop to iterate through each character in the message and retrieves the ASCII code of the character using the "c@" operator. Then it uses another nested "DO" loop to iterate through each bit of the ASCII code and checks if the current bit is 1 or 0 using the "and" operator.

If the bit is 1, it prints a dot "." using the "." operator, and if the bit is 0 it prints a blank " " and then goes to the next line.

Please note that this is a high-level example and Forth 83 has many unique features and it's a low level language, specific implementation details might vary depending on the specific Forth interpreter you use.

## c
This C code defines a function called "convert_and_send" that takes a char pointer "message" as its first argument and an int "message_len" as its second argument. It uses two nested for loops, one for the rows and one for the columns of the 8x8 matrix, so that it can access each bit of the ASCII code.

The innermost for loop uses bitwise AND operator to check if the current bit of the ASCII code is 1 or 0. If the bit is 1, it prints a dot "." using the printf function and if the bit is 0 it prints a blank " " using the printf function


