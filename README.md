Run in shell to install:

make

To use:

Note that the game border size is pre-defined to be 100 x 100.
The program gets the following command-line arguments (written in ASCII as usual):

N – number of drones
T - number of targest needed to destroy in order to win the game
K – how many drone steps between game board printings
β – angle of drone field-of-view
d – maximum distance that allows to destroy a target
seed - seed for initialization of LFSR shift register

> ass3 <N> <T> <K> <β> <d> <seed>
For example: > ass3 5 3 10 15 30 15019
