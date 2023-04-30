#!/usr/bin/python

import json, subprocess
from threading import Semaphore
from google.oauth2 import service_account
from google.cloud import pubsub_v1, logging, storage

# Settings and constants
credentials = service_account.Credentials.from_service_account_file("credentials.json")
subscription_path = pubsub_v1.SubscriberClient.subscription_path(credentials.project_id, "pipico-program")
bucket_name = f"pipico-artifacts-{credentials.project_id}"

# Clients
logging_client = logging.Client(credentials=credentials)
subscriber_client = pubsub_v1.SubscriberClient(credentials=credentials)
storage_client = storage.Client(credentials=credentials)

logger = logging_client.logger("PiPicoProgrammer")
logger.labels = { "build_id": "" }
semaphore = Semaphore()

def do_job(buildId: str):
    file_name = "/tmp/pipico.elf"
    blobs = storage_client.list_blobs(bucket_name, prefix=buildId)
    blob = next(filter(lambda x: x.name.endswith('.elf') , blobs), None)

    if blob == None:
        logger.log("No .elf file found", severity="ERROR")
        print(f"No .elf file found in {buildId}")
        return False

    with open(file_name, "wb") as file:
        storage_client.download_blob_to_file(blob, file)

    openocd_proc = subprocess.run(["openocd",
                                    "-f", "interface/raspberrypi-swd.cfg",
                                    "-f", "target/rp2040.cfg",
                                    "-c", f"program {file_name} verify reset exit"],
                                   stdout=subprocess.PIPE,
                                   stderr=subprocess.PIPE,
                                   text=True)
    
    logger.log(openocd_proc.stdout, severity="INFO")
    print(openocd_proc.stdout)
    if openocd_proc.returncode == 0:
        return True

    logger.log(openocd_proc.stderr, severity="ERROR")
    print(openocd_proc.stderr)
    return False

def callback(message: pubsub_v1.subscriber.message.Message) -> None:
    logger.labels["build_id"] = ""
    try:
        message_text = message.data.decode('utf-8')
        print(f"Message received: {message_text}")
        buildId, deploy = message_text.strip("\"").split()
        logger.labels["build_id"] = buildId
        
        if deploy != "1":
            message.ack()
            logger.log("Done", severity="NOTICE" )
            print("Done")
            return
        if not semaphore.acquire(blocking=False):
            message.ack()
            logger.log("Busy", severity="ERROR")
            print("Busy")
            return
        
        try:
            message.ack()
            logger.log("Start", severity="INFO")
            print("Start")
            if do_job(buildId):
                logger.log("Done", severity="NOTICE")
                print("Done")
            else:
                logger.log("Failed", severity="ERROR")
                print("Failed")
        finally:
            semaphore.release()

    except Exception as err:
        message.ack()
        logger.log(f"Unexpected {err=}, {type(err)=}", severity="ERROR")
        print(f"Unexpected {err=}, {type(err)=}")

streaming_pull_future = subscriber_client.subscribe(subscription_path, callback=callback)
print(f"Listening for messages on {subscription_path}..\n")

with subscriber_client:
    try:
        streaming_pull_future.result()
    finally:
        streaming_pull_future.cancel()
        streaming_pull_future.result()
        print("Exit")