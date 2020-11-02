#!/usr/bin/expect

set timeout 120

spawn ./tjbootstrap.sh 

expect {[Y/n]} { send "\n" }
expect {):} { send "\n" }
expect {[y/N]} { send "\n" }
expect {[y/N]} { send "\n" }
expect {[y/N]} { send "Y\n" }
expect {[Y/n]} { send "\n" }
expect {[Y/n]} { send "Y\n" }
expect {[Y/n]} { send "\n" }
expect {[Y/n]} { send "\n" }
expect {[Y/n]} { send "\n" }
expect {[Y/n]} { send "\n" }
expect {[Y/n]} { send "\n" }
expect {[Y/n]} { send "\n" }

interact
