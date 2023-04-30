#!/bin/sh

sudo apt install pip
pip install --upgrade google-auth google-cloud-logging google-cloud-pubsub google-cloud-storage

echo " "
read -p 'Please insert the GCP Project Id: ' projectId
gcloud auth login --no-launch-browser && gcloud iam service-accounts keys create ../Daemon/credentials.json --iam-account=pipico-programmer@${projectId}.iam.gserviceaccount.com

SCRIPT_PATH=`readlink -f "../Daemon/rpipicoprogrammerd.py"`
SERVICE_FILE="/etc/systemd/system/rpipicoprogrammer.service"
TMP_FILE="/tmp/srv_file"

cat <<EOF > "${TMP_FILE}"
[Unit]
Description=Raspberry Pi Pico Programmer Service
After=multi-user.target

[Service]
Type=simple
ExecStart=/usr/bin/python "${SCRIPT_PATH}"
Restart=always

[Install]
WantedBy=multi-user.target
EOF

sudo mv "${TMP_FILE}" "${SERVICE_FILE}"
sudo systemctl daemon-reload
sudo systemctl start rpipicoprogrammer.service
sudo systemctl enable rpipicoprogrammer.service
