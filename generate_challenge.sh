#!/bin/bash

# --- Configuration ---

# 1. Source the API key from the separate file.
# The file api_key.txt must contain the line: API_KEY="YOUR_ACTUAL_KEY"
source api_key.txt

# Check if API_KEY was successfully loaded
if [ -z "$API_KEY" ]; then
  echo "Error: API_KEY variable is not set. Please ensure api_key.txt exists and contains API_KEY=\"YOUR_KEY\"."
  exit 1
fi

ENDPOINT="https://api.api-ninjas.com/v1/exercises?type=plyometrics"
NUM_EXERCISES=3
MAX_REPS=200

# Function to generate a random number between 1 and MAX_REPS
get_random_reps() {
  echo $((1 + $RANDOM % $MAX_REPS))
}

# 2. Send Request and Filter JSON using curl and jq
echo "Fetching and filtering exercises..."

# Send the request, filter the results for equipment="body_only",
FILTERED_EXERCISES=$(
  curl -s -X GET "$ENDPOINT" \
  -H "X-Api-Key: $API_KEY" |
  jq -r '.[] | select(.equipment == "body_only") | tostring + "\n"'
)

# Check if the result is empty
if [ -z "$FILTERED_EXERCISES" ]; then
  echo "Error: Could not retrieve exercises or no exercises found with equipment='body_only'."
  exit 1
fi

# 3. Randomly Select Three Exercises
echo "Selecting $NUM_EXERCISES random exercises..."

# Count the number of available exercises (lines in the string)
TOTAL_AVAILABLE=$(echo "$FILTERED_EXERCISES" | wc -l)

if [ "$TOTAL_AVAILABLE" -lt "$NUM_EXERCISES" ]; then
  echo "Warning: Only $TOTAL_AVAILABLE exercises found. Selecting all of them."
  NUM_TO_SELECT="$TOTAL_AVAILABLE"
else
  NUM_TO_SELECT="$NUM_EXERCISES"
fi

# Use shuf (shuffle) to randomly select lines (exercises) and limit to NUM_TO_SELECT
SELECTED_EXERCISES=$(echo "$FILTERED_EXERCISES" | shuf -n "$NUM_TO_SELECT")

# 4. Process and Print Results
echo -e "\n--- Workout Plan ---\n"

# Loop through each selected exercise string
echo "$SELECTED_EXERCISES" | while IFS= read -r exercise_json_string; do
  # Convert the single string back into a JSON object for easier parsing
  exercise_object=$(echo "$exercise_json_string" | jq '.')

  # Extract the name and target for a clean display
  name=$(echo "$exercise_object" | jq -r '.name')
  target=$(echo "$exercise_object" | jq -r '.target')

  # 5. Select Rep Range
  reps=$(get_random_reps)

  # 6. Print out the result in the specified format
  echo "$name (Target: $target): $reps reps"
done

echo -e "\n--------------------"
