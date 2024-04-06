ARG base_image=fedora-38

FROM registry.fedoraproject.org/fedora:38@sha256:6349d2df6b4322c5690df1bb7743c45c356e20471dda69f27218cd9ba4a6c3c7 AS fedora-38
FROM registry.fedoraproject.org/fedora:39@sha256:c070b080a64c2dcb07b4090389d929e538cf0925fe02bdd4431bd6cac3e70867 AS fedora-39
FROM registry.fedoraproject.org/fedora:40@sha256:9461fef95a007d05a6e34567d8edab5a216084d481c695f9c0b61ae13aaf80cb AS fedora-40
FROM quay.io/centos/centos:stream9@sha256:0f013e7138073c775c8b0188b707342ff67337abdae1ccb050d28e1d00da3920 AS centos-9

FROM ${base_image}

RUN if grep -i centos /etc/os-release; then dnf install -y epel-release --nodocs --setopt install_weak_deps=False; fi && \
    dnf install -y gnome-session-xsession gnome-extensions-app gjs gdm vte291 \
                   xorg-x11-server-Xvfb mesa-dri-drivers wl-clipboard \
                   PackageKit PackageKit-glib libhandy \
                   --nodocs --setopt install_weak_deps=False && dnf clean all -y

COPY common /

RUN systemctl set-default gnome-session-x11.target && \
    systemctl --global disable dbus-broker && \
    systemctl --global enable dbus-daemon && \
    systemctl mask systemd-oomd low-memory-monitor rtkit-daemon udisks2 && \
    systemctl --global mask org.gnome.SettingsDaemon.Subscription && \
    adduser -m -U -G users,adm gnomeshell && \
    mkdir -p /var/lib/systemd/linger && \
    touch /var/lib/systemd/linger/gnomeshell && \
    su -l gnomeshell -c ' \
        mkdir -p $HOME/.config/systemd/user/sockets.target.wants/ && \
        ln -s /etc/xdg/systemd/user/dbus-proxy@.socket $HOME/.config/systemd/user/sockets.target.wants/dbus-proxy@1234.socket \
    ' && \
    truncate --size 0 /etc/machine-id && \
    dconf update

# dbus port
EXPOSE 1234
LABEL user-dbus-port=1234

# X11 port
EXPOSE 6099
LABEL x11-port=6099 x11-display-number=99

HEALTHCHECK CMD busctl --watch-bind=true status && systemctl is-system-running --wait

CMD [ "/usr/sbin/init", "systemd.unified_cgroup_hierarchy=0" ]
