clear -all

analyze -sv12 \
    rtl/fifo.sv \
    formal/fifo_sva.sv \
    formal/fifo_bind.sv

# DUT is the top; checker comes in through the bind
elaborate -top fifo

clock clk
reset -expression {!rst_n}

# proves asserts and checks reachability of covers
prove -all

report -summary
report -results
