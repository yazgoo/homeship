#!/usr/bin/ruby
require 'yaml'
require 'open-uri'
project = ARGV[0]
if ARGV[1].nil?
    path = "https://raw.githubusercontent.com/#{project}/master/.travis.yml"
else
    path = ARGV[1]
end
dockerfile = ""
open(path) do |f|
    travis = YAML.load(f)
    dockerfile += "from #{travis['build_image']}\n"
    dockerfile += "ENV SHIPPABLE TRUE\n"
    dockerfile += "run groupadd homeship\n"
    dockerfile += "run useradd --home /home/homeship homeship -g homeship\n"
    dockerfile += "run sudo usermod -a -G sudo homeship\n"
    dockerfile += "run echo homeship:homeship | chpasswd\n"
    dockerfile += "run sed -i 's/^.sudo.*/%sudo  ALL=(ALL) NOPASSWD:ALL/' /etc/sudoers\n"
    dockerfile += "run cat /etc/sudoers\n"
    dockerfile += "run adduser homeship sudo\n"
    dockerfile += "run mkdir -p /home/homeship\n"
    dockerfile += "run chown -R homeship:homeship /home/homeship\n"
    dockerfile += "user homeship\n"
    dockerfile += "workdir /home/homeship\n"
    dockerfile += "run ls -ld .\n"
    dockerfile += "run pwd\n"
    dockerfile += "run git clone https://github.com/#{project}.git\n"
    dockerfile += "workdir #{project.split("/")[1]}\n"
    ['before_install', 'install', 'script'].each do |section|
        travis[section].each do |cmd|
            if cmd == "ulimit -c unlimited -S"
                cmd = "ulimit -Sc unlimited"
            end
            dockerfile += "run #{cmd}\n"
        end
    end
end
puts dockerfile
