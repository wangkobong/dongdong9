import * as functions from "firebase-functions";

/**
 * A simple callable function for testing.
 * Returns a greeting message.
 */
export const helloWorld = functions.https.onCall((data, context) => {
  console.log("helloWorld function was called!");
  return { message: "Hello from Firebase!" };
});