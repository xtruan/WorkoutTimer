using Toybox.Application as App;
using Toybox.System as Sys;
using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.Timer as Timer;
using Toybox.Attention as Attn;
using Toybox.Time.Gregorian as Cal;
using Toybox.Time as Time;

// globals
var m_timer;
var m_timerDefaultCount;
var m_timerCount;
var m_timerRunning = false;
var m_timerReachedZero = false;
var m_invertColors = false;
var m_repeat;
var m_repeatNum;
var m_savedClockMins;

var m_customTimeObj = {};

class WorkoutTimerView extends Ui.View
{
	function initialize() {
		View.initialize();
	}
	
    function onUpdate(dc)
    {
        var min = 0;
        var sec = m_timerCount;
        
        // convert secs to mins and secs
        while (sec > 59) {
            min += 1;
            sec -= 60;
        }
    
        // make the secs pretty (heh heh)
        var string;
        if (sec > 9) {
            string = "" + min + ":" + sec;
        } else {
            string = "" + min + ":0" + sec;
        }
        
        // flip background colors based on invert colors boolean
        if (!m_invertColors) {
            dc.setColor( Gfx.COLOR_TRANSPARENT, Gfx.COLOR_BLACK );
        } else {
            dc.setColor( Gfx.COLOR_TRANSPARENT, Gfx.COLOR_WHITE );
        }
        dc.clear();
        
        // display clock
	    if (!m_invertColors) {
        	dc.setColor( Gfx.COLOR_LT_GRAY, Gfx.COLOR_TRANSPARENT );
        } else {
        	dc.setColor( Gfx.COLOR_DK_GRAY, Gfx.COLOR_TRANSPARENT );
        }
        dc.drawText( (dc.getWidth() / 2), Gfx.getFontHeight(Gfx.FONT_MEDIUM), Gfx.FONT_MEDIUM, getClockTime(), Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER );
        
        // flip foreground based on invert colors boolean
        if (!m_invertColors) {
            dc.setColor( Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT );
        } else {
            dc.setColor( Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT );
        }

        // display timer
        dc.drawText( (dc.getWidth() / 2), (dc.getHeight() / 2), Gfx.FONT_NUMBER_THAI_HOT, string, Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER );
        
        // display status
        if (m_timerReachedZero) {
            dc.drawText( (dc.getWidth() / 2), dc.getHeight() - Gfx.getFontHeight(Gfx.FONT_MEDIUM), Gfx.FONT_MEDIUM, "COMPLETE", Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER );
            m_invertColors = !m_invertColors;
        } else if (!m_timerRunning) {
            dc.drawText( (dc.getWidth() / 2), dc.getHeight() - Gfx.getFontHeight(Gfx.FONT_MEDIUM), Gfx.FONT_MEDIUM, "PAUSED", Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER );
        } else if (m_repeat) {
            dc.setColor( Gfx.COLOR_YELLOW, Gfx.COLOR_TRANSPARENT );
            dc.drawText( (dc.getWidth() / 2), dc.getHeight() - Gfx.getFontHeight(Gfx.FONT_MEDIUM), Gfx.FONT_MEDIUM, "REP " + m_repeatNum, Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER );
	    }
    }
    
    function getClockTime() {
        var clockTime = Sys.getClockTime();
        var hours = clockTime.hour;
        if (!Sys.getDeviceSettings().is24Hour) {
            if (hours > 12) {
                hours = hours - 12;
            }
        }
        var timeString = Lang.format("$1$:$2$", [hours.format("%02d"), clockTime.min.format("%02d")]);
        return timeString;
    }

}

class WorkoutTimerDelegate extends Ui.BehaviorDelegate {

    // ctor
    function initialize() {
    	BehaviorDelegate.initialize();
        // init timer
        m_timer = new Timer.Timer();
        // load default timer count
        m_timerDefaultCount = App.getApp().getDefaultTimerCount();
        m_timerCount = m_timerDefaultCount;
        m_customTimeObj[:TimerCount] = m_timerDefaultCount;
        m_customTimeObj[:PickerUpdated] = false;
        // load default repeat state
        m_repeat = App.getApp().getRepeat();
        m_repeatNum = 1;
        // save off current clock minutes
        m_savedClockMins = Sys.getClockTime().min;
        // start timer
        m_timer.start( method(:timerCallback), 1000, true );
    }

    function onMenu() {
        if (!m_timerReachedZero) {
            m_timerRunning = false;
        } else {
            resetTimer();
        }
        var menu = new Rez.Menus.WorkoutTimerMenu();
        menu.setTitle("Setup");
        Ui.pushView(menu, new WorkoutTimerMenuDelegate(), Ui.SLIDE_IMMEDIATE);
        return true;
    }
    
    // tap to start/stop timer
    function onTap(evt) {
        startStop();
    }
    
    // hold to reset timer
    function onHold(evt) {
    	m_repeatNum = 1;
    	resetTimer();
    	if (Attn has :VibeProfile) {
            var vibe = [new Attn.VibeProfile(  50, 100 )];
            Attn.vibrate(vibe);
        }
    }
    
    function onKey(key) {
        if (key.getKey() == Ui.KEY_ENTER) {
            startStop();
        } else if (key.getKey() == Ui.KEY_UP) {
            onMenu();
        } else if (key.getKey() == Ui.KEY_DOWN) {
        	m_repeatNum = 1;
            resetTimer();
            if (Attn has :VibeProfile) {
                var vibe = [new Attn.VibeProfile(  50, 100 )];
        	    Attn.vibrate(vibe);
        	}
        }
    }
    
    function startStop() {
        Ui.requestUpdate();
        if (!m_timerReachedZero) {
            if (!m_timerRunning) {
            	// vibe on start
            	if (Attn has :VibeProfile) {
            	    var vibe = [new Attn.VibeProfile(  100, 100 )];
        		    Attn.vibrate(vibe);
        		}
                // reset timer so the user doesn't only get a partial second to start
                m_timer.stop();
                m_timer.start( method(:timerCallback), 1000, true );
            }
            m_timerRunning = !m_timerRunning;
        } else {
            resetTimer();
        }
    }
    
    function timerCallback() {
    	if (m_customTimeObj[:PickerUpdated]) {
    		Sys.println("Timer: " + m_customTimeObj[:TimerCount]);
    		setCustomTimer(m_customTimeObj[:TimerCount]);
    		m_customTimeObj[:PickerUpdated] = false;
    	}
        if (!m_timerRunning) {
            // state 1: timer is not running
            // refresh the UI only if the minute has changed
            if (m_savedClockMins != Sys.getClockTime().min) {
                m_savedClockMins = Sys.getClockTime().min;
                Ui.requestUpdate();
            }
        } else if (!m_timerReachedZero) {
            // state 2: timer is running
            // decrement the timer until zero, refreshing the UI each time
            // when zero is reached, trigger alerts
            m_timerCount -= 1;
            if (m_timerCount > 0) {
                Ui.requestUpdate();
            } else  {
                reachedZero();
            }
        } else {
            // state 3: timer has completed
            // repeat or alert based on user configuration
            if (m_repeat) {
            	m_repeatNum++;
                resetTimer();
                startStop();
            } else {
                Ui.requestUpdate();
                alert();
            }
        }
    }
    
    function reachedZero() {
        m_timerReachedZero = true;
        m_invertColors = true;
        Ui.requestUpdate();
        alert();
    }
    
    function alert() {
        if (Attn has :VibeProfile) {
            var vibe = [new Attn.VibeProfile(  50, 125 ),
                        new Attn.VibeProfile( 100, 125 ),
                        new Attn.VibeProfile(  50, 125 ),
                        new Attn.VibeProfile( 100, 125 )];
            Attn.vibrate(vibe);
        }
        else if (Attn has :playTone) {
            Attn.playTone(Attn.TONE_TIME_ALERT); // 12
        }
    }
    
    function resetTimer() {
        m_timerReachedZero = false;
        m_timerRunning = false;
        m_timerCount = m_timerDefaultCount;
        m_invertColors = false;
        Ui.requestUpdate();
    }
    
    function setCustomTimer(time) {
        m_timerReachedZero = false;
        m_timerRunning = false;
        m_timerDefaultCount = time;
        App.getApp().setDefaultTimerCount(m_timerDefaultCount); // save new default to properties
        m_timerCount = m_timerDefaultCount;
        m_invertColors = false;
        Ui.requestUpdate();
    }

}

class WorkoutTimerMenuDelegate extends Ui.MenuInputDelegate {

	function initialize() {
        MenuInputDelegate.initialize();
    }

    function onMenuItem(item) {
    
    	// handle main menu
    
        if (item == :item_30) {
            setTimer(30);
        } else if (item == :item_60) {
            setTimer(60);
        } else if (item == :item_90) {
            setTimer(90);
        } else if (item == :item_120) {
            setTimer(120);
        } else if (item == :item_300) {
            setTimer(300);
        } else if (item == :item_1800) {
            setTimer(1800);
        } else if (item == :item_custom) {
            
            var deviceSettings = Sys.getDeviceSettings();
			var ver = deviceSettings.monkeyVersion;
			if (ver != null && ver[0] != null && ver[0] == 1) {
				// old school devices (1.x.x) get the deprecated number picker
				var customDuration = Cal.duration( {:minutes=>1} );
            	var customTimePicker = new Ui.NumberPicker(Ui.NUMBER_PICKER_TIME_MIN_SEC, customDuration);
            	Ui.popView(Ui.SLIDE_IMMEDIATE);
            	Ui.pushView(customTimePicker, new CustomTimePickerDelegate(), Ui.SLIDE_IMMEDIATE);
            	//Ui.switchToView(customTimePicker, new CustomTimePickerDelegate(), Ui.SLIDE_IMMEDIATE);
			} else {
            	// new school devices get to pick via the generic picker
            	Ui.popView(Ui.SLIDE_IMMEDIATE);
            	var gpd = new GenericPickerDialog(GENERIC_PICKER_Time, "Set Timer", m_customTimeObj, :TimerCount);
            }
            
        } else if (item == :item_repeat) {
            toggleRepeat();
        } 
        
    }
    
    function setTimer(time) {
        m_timerReachedZero = false;
        m_timerRunning = false;
        m_timerDefaultCount = time;
        App.getApp().setDefaultTimerCount(m_timerDefaultCount); // save new default to properties     
        m_timerCount = m_timerDefaultCount;
        m_invertColors = false;
        m_repeatNum = 1;
        Ui.requestUpdate();
    }
    
    function toggleRepeat() {
        m_repeat = !m_repeat;
        App.getApp().setRepeat(m_repeat); // save new repeat state to properties
    }
}

class CustomTimePickerDelegate extends Ui.NumberPickerDelegate {
	
	function initialize() {
        NumberPickerDelegate.initialize();
    }
    
    function onNumberPicked(value) {
        WorkoutTimerDelegate.setCustomTimer(value.value());
    }
    
}