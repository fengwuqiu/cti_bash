#!/bin/expect

set robotNUM [lindex $argv 0]
set robotPASS "c$robotNUM"
# set taskCycle "cd cti_ade_home"
set taskCycle "cd cti_bash && git pull origin master && ./taskCycle.bash $robotNUM"

spawn sshpass -p "$robotPASS" ssh -p 2$robotNUM neousys@frp.ctirobot.com
expect {
"neousys" { send "$taskCycle\r" }
}
interact
# expect eof　／　exp_continue
