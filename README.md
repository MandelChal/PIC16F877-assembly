# PIC16F877-assembly

# Bingo Game for PIC16F877

## Overview

This assembly code implements a bingo-style game for the PIC16F877 microcontroller. The program uses multiple peripherals and features of the microcontroller to create an interactive game involving analog-to-digital conversion, square wave generation, and user input via a keypad.

---

## Features

1. **Square Wave Generation**:
   - Outputs a 5 kHz square wave on **PORTC pin 2** as background noise.
   - Frequency changes to 25 kHz upon a correct guess.

2. **Analog-to-Digital Conversion**:
   - Captures an analog voltage from **PORTA pin 0** when a button is pressed on **PORTA pin 5**.

3. **User Input**:
   - Allows the user to input a voltage guess (0–5) via a keypad on **PORTB**.
   - Input is finalized by pressing the `#` key.

4. **Feedback Mechanism**:
   - Displays a victory message if the guess is correct and an error message otherwise.

5. **Reset Functionality**:
   - Pressing the button at **PORTA pin 5** restarts the game.

6. **Interrupt Handling**:
   - **Timer 0** is used to generate square waves via interrupts.

---

## How It Works

1. **Game Start**:
   - The program initializes and starts generating a 5 kHz square wave.

2. **Analog Voltage Input**:
   - The user captures a voltage signal by pressing the button on **PORTA pin 5**.

3. **User Guess**:
   - The user enters a guess (0–5) using the keypad on **PORTB**.
   - The guess is confirmed by pressing the `#` key.

4. **Game Outcome**:
   - If the guess matches the actual voltage:
     - The square wave frequency changes to 25 kHz.
     - A victory message is displayed.
   - If the guess is incorrect:
     - An error message is displayed.

5. **Restart**:
   - Pressing the button on **PORTA pin 5** restarts the game for a new attempt.

---

## Notes

- Ensure proper hardware setup for the microcontroller and peripherals:
  - Keypad connected to **PORTB**.
  - Analog signal input at **PORTA pin 0**.
  - Button for voltage capture and reset at **PORTA pin 5**.
  - Square wave output at **PORTC pin 2**.

- Valid guesses are limited to integers between 0 and 5.

- Ensure the microcontroller is programmed with the correct configuration bits as specified in the code.

---

## License

This project is for educational and demonstration purposes only.
