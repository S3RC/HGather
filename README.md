# HGather
This is a simple dig tracker for FFXI. This addon works with Ashita v4. 

# Fork
This is my personal fork which contains some cleanup of code and also some modifications and additions that I personallly like to have.

## Commands
/hgather or /hgather editor - Opens the configuration menu

/hgather open - Opens the window showing dig data

/hgather close - Closes the window showing dig data

/hgather update - Updates the pricing for items based on the itempricing.txt file

/hgather report - Prints the dig data to chatlog

/hgather reset - Resets the digging data

## Pricing
Pricing for items is listed under the configuration window under the Items tab. Make sure the format is as follows:

**Format**: itemname:itemprice

**Example:** pebble:100

This would price pebbles at 100g.  Make sure there are no spaces or commas in any of the lines.

If you update the prices while in game, make sure to use the **/hgather update** command to update the prices.

Note: The itemname in the file must match the lowercase full name of the item in-game, e.g. chunk of wyvern scales or handful of fish scales

