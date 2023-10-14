#!/usr/bin/env bash

# Function to send a message to Discord via webhook
# Example usage:
# source discord.sh
# send_discord_message "${DISCORD_WEBHOOK}" "This is a test message!"
send_discord_message() {
    local webhook_url="$1"
    local message="$2"
    local max_retries="${3:-3}"  # Default value is 3
    local delay_between_retries=1  # 1 second delay by default

    # Check if the webhook URL is provided
    if [[ -z "${webhook_url}" ]]; then
        echo "Error: Discord webhook URL is missing" >&2
        return 1
    fi

    # Check if the message is provided
    if [[ -z "${message}" ]]; then
        echo "Error: Message content is missing" >&2
        return 1
    fi

    # Counter for the number of attempts
    local attempts=0

    # Use curl to send a POST request to the Discord webhook URL
    until curl -sS -H "Content-Type: application/json" -d "{\"content\": \"${message}\"}" "${webhook_url}"; do
        # Check if max retries have been reached
        ((attempts++))
        if [[ "${attempts}" -ge "${max_retries}" ]]; then
            echo "Error: Failed to send message to Discord after ${max_retries} attempts" >&2
            return 1
        fi

        # Wait before retrying
        echo "Retrying in ${delay_between_retries} seconds..."
        sleep "${delay_between_retries}"
    done

    echo "Message sent to Discord successfully"
}
