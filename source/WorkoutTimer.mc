//!
//! Copyright 2015 by Garmin Ltd. or its subsidiaries.
//! Subject to Garmin SDK License Agreement and Wearables
//! Application Developer Agreement.
//!

using Toybox.Application as App;
using Toybox.WatchUi as Ui;

class WorkoutTimer extends App.AppBase {

    // onStart() is called on application start up
    function onStart() {
    }

    // onStop() is called when your application is exiting
    function onStop() {
    }

    // Return the initial view of your application here
    function getInitialView() {
        return [ new WorkoutTimerView(), new WorkoutTimerDelegate() ];
    }

}