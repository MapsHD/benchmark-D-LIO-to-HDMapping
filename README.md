## Hint

Please change branch to [Bunker-DVI-Dataset-reg-1](https://github.com/MapsHD/benchmark-D-LIO-to-HDMapping/tree/Bunker-DVI-Dataset-reg-1) for quick experiment.

## Example Dataset:

Download the dataset from [Bunker DVI Dataset](https://charleshamesse.github.io/bunker-dvi-dataset/)

# benchmark-D-LIO-to-HDMapping

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
git clone https://github.com/MapsHD/benchmark-D-LIO-to-HDMapping.git --recursive
cd benchmark-D-LIO-to-HDMapping
```

## Step 2 — Build the Docker image

```bash
docker build -t d-lio_humble .
```

This installs:
- Ubuntu 22.04 + ROS 2 Humble
- Ceres Solver 2.1.0 (built from source)
- ANN library (built from source)
- Eigen3, PCL, Boost, OpenMP
- D-LIO (compiled from submodule)
- ROS 2 workspace with `D-LIO` and `D-LIO-to-hdmapping`

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

The script opens a Docker container with a tmux session containing five panes
and a control window:

| Pane | Role |
|------|------|
| 0 | D-LIO node + static TF publishers — reads point cloud + IMU topics, publishes `/odometry_pose` + `/cloud` |
| 1 | RViz2 — live visualization of the D-LIO map and trajectory |
| 2 | `ros2 bag record` — captures the two published topics |
| 3 | `ros2 bag play` — plays your input bag with simulated clock |
| 4 | diagnostics — shows active topics and publishing rates |
| control | auto-shutdown — waits for playback to finish, then stops all nodes |

After playback completes, the control window automatically stops the recorder,
kills all nodes, and exits tmux. A second Docker run then converts the recorded
bag into the HDMapping session format.

## Step 4 — Open in HDMapping

Output files appear in `<output_dir>/output_hdmapping-D-LIO/`:

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
| `in_cloud` | Input PointCloud2 topic | `/livox/pointcloud` |
| `in_imu` | Input IMU topic | `/livox/imu` |
| `hz_cloud` | LiDAR frequency (Hz) | `10.0` |
| `hz_imu` | IMU frequency (Hz) | `200.0` |
| `lidar_type` | Sensor type (`ouster`, `hesai`, `livox`) | `livox` |
| `min_range` / `max_range` | Distance filter (m) | `1.0` / `100.0` |
| `calibration_time` | Static calibration time (s) | `1.0` |

## Contact

januszbedkowski@gmail.com
