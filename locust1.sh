#!/bin/sh

#----make sure this is run as root
user=`id -u`
if [ $user -ne 0 ]; then
    echo "This script requires root permissions. Please run this script with sudo."
    exit
fi

#----ascii art!
echo " _   _ _           _     _                 _       _                   "
echo "| | (_) |         | |   | |               | |     | |                  "
echo "| |_ _| |__   ___ | |_  | |__   ___   ___ | |_ ___| |_ _ __ __ _ _ __  "
echo "| __| | '_ \ / _ \| __| | '_ \ / _ \ / _ \| __/ __| __| '__/ _\` | '_ \ "
echo "| |_| | |_) | (_) | |_  | |_) | (_) | (_) | |_\__ \ |_| | | (_| | |_) |"
echo " \__| |_.__/ \___/ \__| |_.__/ \___/ \___/ \__|___/\__|_|  \__,_| .__/ "
echo "   _/ |                                                         | |    "
echo "  |__/                                                          |_|    "

#----intro message
echo ""
echo "-----------------------------------------------------------------------"
echo "Welcome! Let's set up your Raspberry Pi with the TJBot software."
echo ""
echo "Important: This script was designed for setting up a Raspberry Pi after"
echo "a clean install of Raspbian. If you are running this script on a"
echo "Raspberry Pi that you've used for other projects, please take a look at"
echo "what this script does BEFORE running it to ensure you are comfortable"
echo "with its actions (e.g. performing an OS update, installing software"
echo "packages, removing old packages, etc.)"
echo "-----------------------------------------------------------------------"

#----setting TJBot name
CURRENT_HOSTNAME=`cat /etc/hostname | tr -d " \t\n\r"`
echo ""
echo "Please enter a name for your TJBot. This will be used for the hostname of"
echo "your Raspberry Pi."
echo "Setting DNS hostname to $CURRENT_HOSTNAME"
echo "$CURRENT_HOSTNAME" | tee /etc/hostname >/dev/null 2>&1
sed -i "s/127.0.1.1.*$CURRENT_HOSTNAME/127.0.1.1\t$CURRENT_HOSTNAME/g" /etc/hosts

#----setting local to US
echo ""
echo "Forcing locale to en-US. Please ignore any errors below."
export LC_ALL="en_US.UTF-8"
echo "en_US.UTF-8 UTF-8" | tee -a /etc/locale.gen
locale-gen en_US.UTF-8

#----update raspberry
echo ""
echo "TJBot requires an up-to-date installation of your Raspberry Pi's operating"
echo "system software. If you have never done this before, it can take up to an"
echo "hour or longer."
echo "Updating apt repositories [apt-get update]"
apt-get update
echo "Upgrading OS distribution [apt-get dist-upgrade]"
apt-get -y dist-upgrade

#----nodejs install
NODE_VERSION=$(node --version 2>&1)
NODE_LEVEL=$(node --version 2>&1 | cut -d '.' -f 1 | cut -d 'v' -f 2)

# Node.js version 6 for Jessie
if [ $RASPIAN_VERSION_ID -eq 8 ]; then
    RECOMMENDED_NODE_LEVEL="6"
# Node.js version 9 for Stretch
elif [ $RASPIAN_VERSION_ID -eq 9 ]; then
    RECOMMENDED_NODE_LEVEL="9"
# Node.js version 10 for Buster
elif [ $RASPIAN_VERSION_ID -eq 10 ]; then
    RECOMMENDED_NODE_LEVEL="10"
# Node.js version 10 for anything else
else
    RECOMMENDED_NODE_LEVEL="10"
fi

echo ""
if [ $NODE_LEVEL -ge $RECOMMENDED_NODE_LEVEL ]; then
    echo "Node.js version $NODE_VERSION is installed, which is the recommended version for"
    echo "Raspian $RASPIAN_VERSION. Congratulations!"
else
    echo "Node.js version $NODE_VERSION is currently installed. We recommend installing"
    echo "Node.js version $RECOMMENDED_NODE_LEVEL for Raspian $RASPIAN_VERSION."

    curl -sL https://deb.nodesource.com/setup_${node_version}.9 | sudo bash -
    apt-get install -y nodejs
fi

#----install additional packages
echo ""
if [ $RASPIAN_VERSION_ID -eq 8 ]; then
    echo "Installing additional software packages for Jessie (alsa, libasound2-dev, git, pigpio)"
    apt-get install -y alsa-base alsa-utils libasound2-dev git pigpio
#elif [ $RASPIAN_VERSION -eq 9 ]; then
#    echo "Installing additional software packages for Stretch (libasound2-dev)"
#    apt-get install -y libasound2-dev
fi

wget https://nodejs.org/dist/v10.16.1/node-v10.16.1-linux-armv6l.tar.xz
tar -xJf node-v10.16.1-linux-armv6l.tar.xz
cd node-v10.16.1-linux-armv6l/
sudo cp -R * /usr/local/
cd ..

curl https://raw.githubusercontent.com/marthacryan/BugzBGone/master/locust2.sh -o locust2.sh

#----remove outdated apt packages
echo ""
echo "Removing unused software packages [apt-get autoremove]"
apt-get -y autoremove

#----enable camera on raspbery pi
echo ""
echo "If your Raspberry Pi has a camera installed, TJBot can use it to see."

if grep "start_x=1" /boot/config.txt
then
    echo "Camera is alredy enabled."
else
    echo "Enabling camera."
    if grep "start_x=0" /boot/config.txt
    then
        sed -i "s/start_x=0/start_x=1/g" /boot/config.txt
    else
        echo "start_x=1" | tee -a /boot/config.txt >/dev/null 2>&1
    fi
    if grep "gpu_mem=128" /boot/config.txt
    then
        :
    else
        echo "gpu_mem=128" | tee -a /boot/config.txt >/dev/null 2>&1
    fi
fi

#----clone tjbot
echo ""
echo "We are ready to clone the TJBot project."
TJBOT_DIR='/home/pi/Desktop/tjbot'

if [ ! -d $TJBOT_DIR ]; then
    echo "Cloning TJBot project to $TJBOT_DIR"
    sudo -u $SUDO_USER git clone https://github.com/ibmtjbot/tjbot.git $TJBOT_DIR
else
    echo "TJBot project already exists in $TJBOT_DIR, leaving it alone"
fi

#----blacklist audio kernel modules
echo ""
echo "On Raspberry Pi 3 models, there is a known conflict between the LED "
echo "and the built-in audio jack. In order for the LED to work, we need to"
echo "disable certain kernel modules to avoid this conflict. If you have "
echo "plugged in a speaker via HDMI, USB, or Bluetooth, this is a safe "
echo "operation and you will be able to play sound and use the LED at the "
echo "same time. If you plan to use the built-in audio jack, we recommend "
echo "NOT disabling the sound kernel modules."

if [ -f /etc/modprobe.d/tjbot-blacklist-snd.conf ]; then
    echo "Enabling the kernel modules for the built-in audio jack."
    rm /etc/modprobe.d/tjbot-blacklist-snd.conf
fi

#----installation complete
sleep_time=0.1
echo ""
echo ""
echo "                           .yNNs\`                           "
sleep $sleep_time
echo "                           :hhhh-                           "
sleep $sleep_time
echo "/ssssssssssssssssssssssssssssssssssssssssssssssssssssssssss+"
sleep $sleep_time
echo "yNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNy"
sleep $sleep_time
echo "yMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMy"
sleep $sleep_time
echo "yMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMy"
sleep $sleep_time
echo "yMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMy"
sleep $sleep_time
echo "yMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMy"
sleep $sleep_time
echo "yMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMy"
sleep $sleep_time
echo "yMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMy"
sleep $sleep_time
echo "yMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMy"
sleep $sleep_time
echo "yMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMy"
sleep $sleep_time
echo "yMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMy"
sleep $sleep_time
echo "yMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMy"
sleep $sleep_time
echo "yMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMy"
sleep $sleep_time
echo "yMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMy"
sleep $sleep_time
echo "yMMMMMMMMMMMMMNmmmNMMMMMMMMMMMMMMMMMMMMMMNmmmMMMMMMMMMMMMMMy"
sleep $sleep_time
echo "yMMMMMMMMMMMNd/\`\`\`.+NNMMMMMMMMMMMMMMMMNm+.\` \`/dNMMMMMMMMMMMy"
sleep $sleep_time
echo "yMMMMMMMMMMMNo     \`hMMMMMMMMMMMMMMMMMMy\`     oNMMMMMMMMMMMy"
sleep $sleep_time
echo "yMMMMMMMMMMMNm+.\`\`-sNMMMMMMMMMMMMMMMMMNNs-\`\`.+mNMMMMMMMMMMMy"
sleep $sleep_time
echo "yMMMMMMMMMMMMMMNmmMMMMMMMMMMMMMMMMMMMMMMMMmmNMMMMMMMMMMMMMMy"
sleep $sleep_time
echo "yNNNNNMMMMMMMMMMMMNNNNNNMMNNNNNNNNNNMMMMMMMMMMMMMMMMMMMNNNMy"
sleep $sleep_time
echo "-::::::::::::::::::::::::::::::::::::::::::::::::::::::::::-"
sleep $sleep_time
echo "                                                            "
sleep $sleep_time
echo "                     \`\`\`\`\`\`\`\`....--::::////++++ooossyyhhhhh/"
sleep $sleep_time
echo "//++ossssssyyyyhhddmmmmmmmmmmmmNNNNNMMNNNNNNMMMMMMMMMMMMMNNo"
sleep $sleep_time
echo "dMNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMy"
sleep $sleep_time
echo "sMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMd"
sleep $sleep_time
echo "oNMMMMMMMMMMMMMMMMNNNNNNNNMMMMMMNNNNNmmmmmmmmmddhhhhyyyyssss"
sleep $sleep_time
echo "+Nmmmddhhhhyyyyssoo++++/////:::---....\`\`\`\`\`\`\`\`        "
sleep $sleep_time
echo ""
sleep $sleep_time
echo "-------------------------------------------------------------------"
sleep $sleep_time
echo "Setup complete. Your Raspberry Pi is now set up as a TJBot! ;)"
sleep $sleep_time
echo "-------------------------------------------------------------------"
echo ""

#——instructions for watson credentials
echo ""
echo "Notice about Watson services: Before running any recipes, you will need"
echo "to obtain credentials for the Watson services used by those recipes."
echo "You can obtain these credentials as follows:"
echo ""
echo "1. Sign up for a free IBM Cloud account at https://cloud.ibm.com if you do
not have one already."
echo "2. Log in to IBM Cloud and create an instance of the Watson services you plan
to use. The Watson services are listed on the IBM Cloud dashboard, under
\"Catalog\". The full list of Watson services used by TJBot are:"
echo "Assistant, Language Translator, Speech to Text, Text to Speech,"
echo "Tone Analyzer, and Visual Recognition"
echo "3. For each Watson service, click the \"Create\" button on the bottom right
of the page to create an instance of the service."
echo "4. Click \"Service Credentials\" in the left-hand sidebar. Next, click
\"View Credentials\" under the Actions menu."
echo "5. Make note of the credentials for each Watson service. You will need to save
these in the config.js files for each recipe you wish to run."
echo "For more detailed guides on setting up service credentials, please see the
README file of each recipe, or search instructables.com for \"tjbot\"."
echo ""

#----tests
echo ""
echo "TJBot includes a set of hardware tests to ensure all of the hardware is"
echo "functioning properly. If you have made any changes to the camera or"
echo "sound configuration, we recommend rebooting first before running these"
echo "tests as they may fail. You can run these tests at anytime by running"
echo "the runTests.sh script in the tjbot/bootstrap folder."
echo ""

#----reboot
echo ""

reboot
