// Function to check if any checkboxes are selected
function anyCheckboxesSelected(containerSelector) {
  return jq(`${containerSelector} input[type="checkbox"]:checked`).length > 0;
}

/**
 * Updates the required attribute of the last checkbox in the given container.
 * @param {string} containerSelector - The selector for the container containing checkboxes.
 * @param {string} requiredMsgId - The selector for the element to display the required message.
 * @param {string} requiredMsg - The message to display when the last checkbox is required.
 * @returns {boolean} - Returns true if the last checkbox is required, false otherwise.
 */
function updateLastCheckboxRequired(containerSelector, requiredMsgId, requiredMsg) {
  // Initialize the flag to keep track of the last checkbox state.
  let islastCheckbox = false;

  // Function to update the required attribute of the last checkbox
  const updateLastCheckbox = function () {

    // Select the last checkbox within the container using the given selector
    let lastCheckbox = jq(`${containerSelector} input[type="checkbox"]`).last();

    // Clear and hide the required message
    jq(requiredMsgId).text('').hide()

    // Check if any checkboxes are selected within the container using the anyCheckboxesSelected function.
    if (!anyCheckboxesSelected(containerSelector)) {

      // Display the required message and focus on the last checkbox
      jq(requiredMsgId).text(requiredMsg).show()
      lastCheckbox.focus()
      islastCheckbox = false;

    } else {
      jq(requiredMsgId).text('').hide()
      islastCheckbox = true;
    }
    return islastCheckbox;
  }

  // Initial call to updateLastCheckboxRequired to set the required attribute on page load.
  updateLastCheckbox()

  // Attach event listeners to the checkboxes in the container to update the required attribute dynamically.
  jq(`${containerSelector} input[type="checkbox"]`).change(updateLastCheckbox)
  jq(`${containerSelector} input[type="checkbox"]`).keyup(updateLastCheckbox)

  // Add the updateLastCheckboxRequired function to the beforeSubmit array to call it before form submission.
  beforeSubmit.push(updateLastCheckbox);
}
