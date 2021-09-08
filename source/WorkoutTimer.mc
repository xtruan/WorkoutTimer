using Toybox.Application as App;
using Toybox.WatchUi as Ui;

class WorkoutTimer extends App.AppBase {

    // get default timer count from properties, if not set return default
    function getDefaultTimerCount() {
        var time = getProperty("time");
        if (time != null) {
            return time;
        } else {
            return 60; // 1 min default timer count
        }
    }
    
    // set default timer count in properties
    function setDefaultTimerCount(time) {
        setProperty("time", time);
    }
    
    // get repeat boolean from properties, if not set return default
    function getRepeat() {
        var repeat = getProperty("repeat");
        if (repeat != null) {
            return repeat;
        } else {
            return false; // repeat off by default
        }
    }
    
    // set repeat boolean in properties
    function setRepeat(repeat) {
        setProperty("repeat", repeat);
    }

    // onStart() is called on application start up
    function onStart(state) {
    }

    // onStop() is called on application shutdown
    function onStop(state) {
    }

    // Return the initial view of your application here
    function getInitialView() {
        return [ new WorkoutTimerView(), new WorkoutTimerDelegate() ];
    }

}