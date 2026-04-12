## Hint

Please change branch to [Bunker-DVI-Dataset-reg-1](https://github.com/MapsHD/benchmark-DLIO-to-HDMapping/tree/Bunker-DVI-Dataset-reg-1) for quick experiment.

## Example Dataset:

Download the dataset from [Bunker DVI Dataset](https://charleshamesse.github.io/bunker-dvi-dataset/)

# benchmark-DLIO-to-HDMapping

Runs the [D-LIO](https://github.com/robotics-upo/D-LIO) LiDAR-Inertial odometry algorithm on a ROS 2 bag
file and converts the output to an [HDMapping](https://github.com/MapsHD/HDMapping) session.

D-LIO (Direct LiDAR-Inertial Odometry) is a real-time LiDAR-Inertial odometry system
based on Fast Truncated Distance Fields (FTDF), from Universidad Pablo de Olavide.

## Prerequisites

- Docker
- A ROS 2 bag containing a `sensor_msgs/msg/PointCloud2` topic and a `sensor_msgs/msg/Imu` topic
  (ROS 1 bags are automatically converted to ROS 2 format)

## Step 1 — Clone with submodules

```bash
git clone https://github.com/MapsHD/benchmark-DLIO-to-HDMapping.git --recursive
cd benchmark-DLIO-to-HDMapping
```

## Step 2 — Build the Docker image

```bash
docker build -t dlio_humble .
```

This installs:
- Ubuntu 22.04 + ROS 2 Humble
- Ceres Solver 2.1.0 (built from source)
- ANN library (built from source)
- Eigen3, PCL, Boost, OpenMP
- D-LIO (compiled from submodule)
- ROS 2 workspace with `dlio` and `dlio-to-hdmapping`

The build takes several minutes on first run.

## Step 3 — Run the pipeline

```bash
chmod +x docker_session_run-ros2-dlio.sh
./docker_session_run-ros2-dlio.sh /path/to/input.bag /path/to/output/dir
```

Or with no arguments to use a GUI file selector (requires `zenity`):

```bash
./docker_session_run-ros2-dlio.sh
```

**What happens:**

The script opens a Docker container with a tmux session containing four panes:

| Pane | Role |
|------|------|
| 0 | D-LIO node — reads point cloud + IMU topics, publishes `/odometry_pose` + `/cloud` |
| 1 | `ros2 bag record` — captures the two published topics |
| 2 | `ros2 bag play` — plays your input bag with simulated clock |
| 3 | diagnostics — shows active topics and publishing rates |

After playback completes, recording is stopped and a second Docker run converts
the recorded bag into the HDMapping session format.

## Step 4 — Open in HDMapping

Output files appear in `<output_dir>/output_hdmapping-dlio/`:

```
lio_initial_poses.reg
poses.reg
scan_lio_0.laz
scan_lio_1.laz
...
session.json
trajectory_lio_0.csv
trajectory_lio_1.csv
...
```

Open `session.json` with the
[multi_view_tls_registration_step_2](https://github.com/MapsHD/HDMapping) application.

## Notes on D-LIO

D-LIO requires both LiDAR point clouds and IMU data. Key parameters to adjust for your sensor:

| Parameter | Description | Default |
|-----------|-------------|---------|
| `in_cloud` | Input PointCloud2 topic | `/cloud` |
| `in_imu` | Input IMU topic | `/imu` |
| `hz_cloud` | LiDAR frequency (Hz) | `10.0` |
| `hz_imu` | IMU frequency (Hz) | `100.0` |
| `lidar_type` | Sensor type (`ouster`, `hesai`) | `ouster` |
| `min_range` / `max_range` | Distance filter (m) | `1.0` / `100.0` |
| `calibration_time` | Static calibration time (s) | `1.0` |

## Contact

januszbedkowski@gmail.com
