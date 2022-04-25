using Toybox.Application as App;
using Toybox.System as Sys;
using Toybox.WatchUi as Ui;

class WorkoutTimer extends App.AppBase {

    // get default timer count from properties, if not set return default
    function getDefaultTimerCount() {
        var time = getPropertySafe("time");
        if (time != null) {
            return time;
        } else {
            return 60; // 1 min default timer count
        }
    }
    
    // set default timer count in properties
    function setDefaultTimerCount(time) {
        setPropertySafe("time", time);
    }
    
    // get repeat boolean from properties, if not set return default
    function getRepeat() {
        var repeat = getPropertySafe("repeat");
        if (repeat != null) {
            return repeat;
        } else {
            return false; // repeat off by default
        }
    }
    
    function setPropertySafe(key, val) {
    	var deviceSettings = Sys.getDeviceSettings();
		var ver = deviceSettings.monkeyVersion;
    	if ( ver != null && ver[0] != null && ver[1] != null && 
    		( (ver[0] == 2 && ver[1] >= 4) || ver[0] > 2 ) ) {
    		// new school devices (>2.4.0) use Storage
    		App.Storage.setValue(key, val);
    	} else {
    		// old school devices use AppBase properties
    		setProperty(key, val);
    	}
    }
    
    function getPropertySafe(key) {
    	var deviceSettings = Sys.getDeviceSettings();
		var ver = deviceSettings.monkeyVersion;
    	if ( ver != null && ver[0] != null && ver[1] != null && 
    		( (ver[0] == 2 && ver[1] >= 4) || ver[0] > 2 ) ) {
    		// new school devices (>2.4.0) use Storage
    		return App.Storage.getValue(key);
    	} else {
    		// old school devices use AppBase properties
    		return getProperty(key);
    	}
    }
    
    // set repeat boolean in properties
    function setRepeat(repeat) {
        setPropertySafe("repeat", repeat);
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
    
    function initialize() {
        AppBase.initialize();
    }

}