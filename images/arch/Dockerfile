FROM docker.io/library/archlinux:base
RUN pacman -Syu --noconfirm zsh sudo && \
    useradd -m -g users -G wheel -s /bin/zsh user && \
    echo "%wheel ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
USER user
WORKDIR /home/user
COPY . .
