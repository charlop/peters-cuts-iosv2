# Peter's 816 Cuts

## Overview

This is the iOS component of Peter's 816 Barber Shop App. This app is a fork from the original, created with Spandan [Previous Peter's 816 Repository](https://github.com/spandanj/petersios). I forked the project to perform a major overhaul, while learning iOS development concurrently while not destroying the existing project for several months. The previous version allowed users to get a number and would occassionally send a notification when their haircut was up next. The current version has refactored a significant portion of the code and added a reservation option, so users can request a specific appointment time.

## Other Components
[Android Repository](https://github.com/charlop/peters816-android)

[PHP Repository](https://github.com/charlop/peters816-php/)

## TODOs:

* **Notifications** 
  * Currently not working correctly, users receive notifications at random times. Based on a timer event, that sends the notification based on the original ETA received. This code has not been modified from the original, but should be simpler and more reliable since v2 relies on set times, as opposed to an arbitrary reference point (unscheduled).
  * Users should be prompted to accept notifications the first time they launch the app.
* **Error Handling** 
  * **Multiple Reservations:** There is a limitation that users can only make a maximum of 4 reservations per day. The app currently gives a "please try again" message if the user has reached their limit, instead of letting them know.
 * **Connection Timeout:** The app currently checks if the device has an internet connection and should handle that fairly well. However, if no response is received from the server, the connection times out after 20 seconds and the app crashes.
* **Input Validation:** The phone number should be validated through regex to make sure a valid number was entered.
* **Closed Message:** The administrator can set a closed message that should be checked when checking whether the shop is open. The messages would be something like "Closed for the long weekend, opening again on December 19th".
