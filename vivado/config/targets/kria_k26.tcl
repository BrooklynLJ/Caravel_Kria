# CLAUDED
# Starting point for the Kria SOM. Verify the strings in the Vivado console:
#   get_parts xck26*          get_board_parts *k26*   get_board_parts *kv260*
set target(part)        xck26-sfvc784-2LV-c
set target(board_part)  xilinx.com:k26c:part0:1.4
set target(top)         caravel
set target(constraints) {vivado/constraints/caravel_kria.xdc}
# The existing .xci files were made for a 7-series part; they get upgraded on
# import, but you may want per-target copies (vivado/ip/kria/...) once they diverge.
set target(ip)          {vivado/ip/bram/bram.xci vivado/ip/clk_fix_1/clk_fix.xci}