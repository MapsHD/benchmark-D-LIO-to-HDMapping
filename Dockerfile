FROM ubuntu:22.04

SHELL ["/bin/bash", "-c"]
ENV DEBIAN_FRONTEND=noninteractive

# ── Base tools ────────────────────────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    gnupg2 \
    lsb-release \
    software-properties-common \
    build-essential \
    git \
    apt-transport-https \
    ca-certificates \
    wget \
    libeigen3-dev \
    libboost-all-dev \
    libomp-dev \
    libpcl-dev \
    libyaml-cpp-dev \
    nlohmann-json3-dev \
    tmux \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# ── ROS 2 Humble ─────────────────────────────────────────────────────────────
RUN curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key \
    | gpg --dearmor -o /usr/share/keyrings/ros-archive-keyring.gpg && \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] \
    http://packages.ros.org/ros2/ubuntu $(lsb_release -cs) main" \
    > /etc/apt/sources.list.d/ros2.list && \
    apt-get update && apt-get install -y --no-install-recommends \
    ros-humble-desktop \
    ros-humble-tf2-ros \
    ros-humble-tf2-eigen \
    ros-humble-pcl-conversions \
    ros-humble-pcl-ros \
    ros-humble-message-filters \
    ros-humble-geometry-msgs \
    ros-humble-nav-msgs \
    ros-humble-sensor-msgs \
    ros-humble-std-srvs \
    ros-humble-rosbag2-cpp \
    ros-humble-rosbag2-storage \
    ros-humble-rosbag2-storage-default-plugins \
    python3-colcon-common-extensions \
    python3-rosdep \
    && rm -rf /var/lib/apt/lists/*

# ── rosbags (Python tool to convert ROS 1 bags to ROS 2 format) ──────────────
RUN pip3 install --no-cache-dir rosbags

# ── Ceres Solver 2.1.0 (required by D-LIO) ───────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgoogle-glog-dev \
    libsuitesparse-dev \
    libgflags-dev \
    libatlas-base-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /tmp
RUN git clone https://github.com/ceres-solver/ceres-solver.git && \
    cd ceres-solver && \
    git checkout 2.1.0 && \
    mkdir build && cd build && \
    cmake .. -DBUILD_EXAMPLES=OFF && \
    make -j$(nproc) && make install && \
    ldconfig && \
    cd / && rm -rf /tmp/ceres-solver

# ── ANN library (required by D-LIO) ──────────────────────────────────────────
WORKDIR /tmp
RUN git clone https://github.com/dials/annlib.git && \
    mkdir -p annlib/lib && \
    cd annlib/src && \
    make linux-g++ && \
    cp ../lib/libANN.a /usr/local/lib/ && \
    cp -r ../include/ANN /usr/local/include/ && \
    ldconfig && \
    cd / && rm -rf /tmp/annlib

# ── Build colcon workspace ────────────────────────────────────────────────────
WORKDIR /ros2_ws

COPY ./src/D-LIO              ./src/D-LIO
COPY ./src/dlio-to-hdmapping  ./src/dlio-to-hdmapping

RUN source /opt/ros/humble/setup.bash && \
    colcon build --cmake-args -DCMAKE_BUILD_TYPE=Release

# ── Non-root user ─────────────────────────────────────────────────────────────
ARG UID=1000
ARG GID=1000
RUN groupadd -g $GID ros && \
    useradd -m -u $UID -g $GID -s /bin/bash ros

RUN echo "source /opt/ros/humble/setup.bash"    >> /root/.bashrc && \
    echo "source /ros2_ws/install/setup.bash"    >> /root/.bashrc && \
    echo "source /opt/ros/humble/setup.bash"    >> /home/ros/.bashrc && \
    echo "source /ros2_ws/install/setup.bash"    >> /home/ros/.bashrc

CMD ["bash"]
