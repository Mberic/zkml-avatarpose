from os import environ
import logging
import requests
import subprocess

logging.basicConfig(level="INFO")
logger = logging.getLogger(__name__)

rollup_server = environ["ROLLUP_HTTP_SERVER_URL"]
logger.info(f"HTTP rollup_server url is {rollup_server}")


def handle_advance(data):
    logger.info(f"Received advance request data {data}")
    
    try:
        result = subprocess.run(
            ["ezkl", "verify"],
            check=True,
            capture_output=True,
            text=True
        )
        logger.info(f"ezkl verify output: {result.stdout}")
        return "accept"
    except subprocess.CalledProcessError as e:
        logger.error(f"ezkl verify failed: {e.stderr}")
        return "reject"


def handle_inspect(data):
    logger.info(f"Received inspect request data {data}")
    return "accept"


handlers = {
    "advance_state": handle_advance,
    "inspect_state": handle_inspect,
}

finish = {"status": "accept"}

while True:
    logger.info("Sending finish")
    response = requests.post(rollup_server + "/finish", json=finish)
    logger.info(f"Received finish status {response.status_code}")
    if response.status_code == 202:
        logger.info("No pending rollup request, trying again")
    else:
        rollup_request = response.json()
        data = rollup_request["data"]
        handler = handlers[rollup_request["request_type"]]
        finish["status"] = handler(rollup_request["data"])
