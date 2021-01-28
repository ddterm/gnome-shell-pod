FROM ubuntu:latest

# Else the installation of GNOME Shell will ask interactively for our time zone.
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update -y &&                                                               \
    apt-get install systemd gnome-shell gnome-shell-extension-prefs xvfb xdotool -y && \
    apt-get clean

# This is required to make systemd-logind work.
RUN mkdir -p /etc/systemd/system/systemd-logind.service.d &&                           \
    { echo "[Service]";                                                                \
      echo "ProtectHostname=no";                                                       \
    } > /etc/systemd/system/systemd-logind.service.d/override.conf

# This makes sure that the gnomeshell user gets logged in automatically.
RUN mkdir -p /etc/systemd/system/console-getty.service.d &&                            \
    { echo "[Service]";                                                                \
      echo "ExecStart=";                                                               \
      echo "ExecStart=-/sbin/getty --autologin gnomeshell --noclear                    \
                                   --keep-baud console 115200,38400,9600 $TERM";       \
    } > /etc/systemd/system/console-getty.service.d/override.conf

# Add the gnomeshell user with no password and run GNOME Shell as soon as this user
# logs in. The framebuffer of xvfb will be mapped to /home/gnomeshell/Xvfb_screen0.
# We also set the DISPLAY environment variable in case we want to launch applications.
RUN adduser --disabled-password --gecos "" gnomeshell &&                              \
    echo "xvfb-run --server-args='-ac -screen 0 1600x900x24 -fbdir /home/gnomeshell'  \
                   gnome-shell &"    >> /home/gnomeshell/.bashrc &&                   \
    echo "export DISPLAY=:99"        >> /home/gnomeshell/.bashrc

# Add the script.
ADD enable-extension.sh /home/gnomeshell

# Do not attempt to boot into a graphical session.
RUN systemctl set-default multi-user.target

CMD [ "/usr/sbin/init" ]