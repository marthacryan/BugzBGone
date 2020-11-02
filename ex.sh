#!/usr/bin/expect

spawn ./tjbootstrap.sh 

expect {[Y/n]} { send "\n" }
expect {):} { send "\n" }
expect {[Y/n]} { send "\n" }
expect {[Y/n]:} { send "\n" }
expect {[Y/n]} { send "Y\n" }
expect {[Y/n]} { send "\n" }
expect {[Y/n]} { send "Y\n" }
expect {[Y/n]} { send "\n" }
expect {[Y/n]} { send "\n" }
expect {[Y/n]} { send "\n" }
expect {[Y/n]} { send "\n" }
expect {[Y/n]} { send "\n" }
expect {[Y/n]} { send "\n" }

interact
