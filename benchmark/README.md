# Automatic benchmark pipeline
## Installing
1. install os packages listed in dependencies.txt
2. generate an SSH keypair for the stress machine without a password
3. copy the public key to Github repo -> Settings -> Deploy keys -> Add new and give it write permission (this is used for pushing the benchmark results)
4. create a .env file in "benchmark" folder and set the following:
XVFB_DISPLAY_NUM=:99
DISCORD_WEBHOOK=https://discord.com/api/webhooks/your-webhook-url-here
5. install xvfb service for virtual display (instructions in xvfb.service file)
6. set the watcher script to run periodically with "crontab -e":
*/1 * * * * /home/myuser/instanssi2024DemoKonso/benchmark/benchmark-new-changes.sh
7. Hopefully you're all set?
## Usage
benchmark-new-changes.sh will pull from the repo and overwrite all local changes  
Then it runs benchmark.sh
...add more later
