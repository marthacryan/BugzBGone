curl https://raw.githubusercontent.com/marthacryan/BugzBGone/master/tjbootstrap.sh -o tjbootstrap.sh
chmod +x tjbootstrap.sh
curl https://raw.githubusercontent.com/marthacryan/BugzBGone/master/locust1.sh -o locust2.sh
chmod +x locust2.sh
yes | sudo apt-get install expect
curl -sL https://raw.githubusercontent.com/marthacryan/BugzBGone/master/ex.sh | sudo expect -d -
