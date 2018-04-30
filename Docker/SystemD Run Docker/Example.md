## Create a Systemd file to start docker
	
	[Unit]
	# Set it to your description
	Description=My Docker Container service
	# Make sure Docker and networking are set up before running this
	After=network.target docker.socket
	Requires=docker.socket

	[Service]
	# Equivalent of Docker's `restart_policy`
	RestartSec=10
	Restart=always
	# Give `docker pull` some time
	TimeoutStartSec=90
	# Use instance name as the container name
	Environment="CONTAINER_NAME=%i"
	# Set it to your image name
	Environment="IMAGE_NAME=alpine:latest"

	# Remove any stale containers
	ExecStartPre=-/usr/bin/docker rm -f $CONTAINER_NAME
	# Pull the image
	ExecStartPre=-/usr/bin/docker pull $IMAGE_NAME
	# Start the container in the foreground
	ExecStart=/usr/bin/docker run --rm --name ${CONTAINER_NAME} ${IMAGE_NAME}
	# Stop command
	ExecStop=/usr/bin/docker stop $CONTAINER_NAME

	[Install]
	WantedBy=multi-user.target