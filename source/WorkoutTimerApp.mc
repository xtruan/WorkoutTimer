using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.Timer as Timer;
using Toybox.Attention as Attn;
using Toybox.Time.Gregorian as Cal;

// inits
var m_timer;
var m_timerDefaultCount;
var m_timerCount;
var m_timerRunning = false;
var m_timerReachedZero = false;
var m_invertColors = false;
var m_repeat;

class WorkoutTimerView extends Ui.View
{

    function onLayout(dc)
    {
        // init timer
        m_timer = new Timer.Timer();
        // load default timer count
        m_timerDefaultCount = App.getApp().getDefaultTimerCount();
        m_timerCount = m_timerDefaultCount;
        // load default repeat state
        m_repeat = App.getApp().getRepeat();
    }

    function onUpdate(dc)
    {
        var min = 0;
        var sec = m_timerCount;
        
        while (sec > 59) {
            min += 1;
            sec -= 60;
        }
    
        var string;
        if (sec > 9) {
            string = "" + min + ":" + sec;
        } else {
            string = "" + min + ":0" + sec;
        }
        
        // flip foreground and background colors based on invert colors boolean
        if (!m_invertColors) {
            dc.setColor( Gfx.COLOR_TRANSPARENT, Gfx.COLOR_BLACK );
        } else {
            dc.setColor( Gfx.COLOR_TRANSPARENT, Gfx.COLOR_WHITE );
        }
        dc.clear();
        if (!m_invertColors) {
            dc.setColor( Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT );
        } else {
            dc.setColor( Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT );
        }

        // display time
        dc.drawText( (dc.getWidth() / 2), (dc.getHeight() / 2) - 60, Gfx.FONT_NUMBER_THAI_HOT, string, Gfx.TEXT_JUSTIFY_CENTER );
        
        // display status
        if (m_timerReachedZero) {
            dc.drawText( (dc.getWidth() / 2), 2 * (dc.getHeight() / 3) + 10, Gfx.FONT_MEDIUM, "COMPLETE", Gfx.TEXT_JUSTIFY_CENTER );
            m_invertColors = !m_invertColors;
        } else if (!m_timerRunning) {
            dc.drawText( (dc.getWidth() / 2), 2 * (dc.getHeight() / 3) + 10, Gfx.FONT_MEDIUM, "PAUSED", Gfx.TEXT_JUSTIFY_CENTER );
        } else if (m_repeat) {
            dc.setColor( Gfx.COLOR_YELLOW, Gfx.COLOR_TRANSPARENT );
            dc.drawText( (dc.getWidth() / 2), 2 * (dc.getHeight() / 3) + 10, Gfx.FONT_MEDIUM, "REPEAT ON", Gfx.TEXT_JUSTIFY_CENTER );
        }
    }

}

class WorkoutTimerDelegate extends Ui.BehaviorDelegate {

    function onMenu() {
        if (!m_timerReachedZero) {
            m_timer.stop();
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
        //System.println(evt.getCoordinates());
        startStop();
    }
    
    // hold to reset timer
    function onHold(evt) {
        var vibe = [new Attn.VibeProfile(  50, 100 )];
        Attn.vibrate(vibe);
        resetTimer();
    }
    
    function onKey(key) {
        //System.println(key.getKey());
        if (key.getKey() == Ui.KEY_ENTER) {
            startStop();
        } else if (key.getKey() == Ui.KEY_UP) {
            onMenu();
        } else if (key.getKey() == Ui.KEY_DOWN) {
            resetTimer();
        }
    }
    
    function startStop() {
        Ui.requestUpdate();
        if (!m_timerReachedZero) {
            if (m_timerRunning) {
                m_timer.stop();
            } else {
                m_timer.start( method(:timerCallback), 1000, true );
            }
            m_timerRunning = !m_timerRunning;
        } else {
            resetTimer();
        }
    }
    
    function timerCallback() {
        if (!m_timerReachedZero) {
            m_timerCount -= 1;
            if (m_timerCount == 0) {
                reachedZero();
            } else  {
                Ui.requestUpdate();
            }
        } else {
            if (m_repeat) {
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
        var vibe = [new Attn.VibeProfile(  50, 125 ),
                    new Attn.VibeProfile( 100, 125 ),
                    new Attn.VibeProfile(  50, 125 ),
                    new Attn.VibeProfile( 100, 125 )];
        Attn.vibrate(vibe);
         
        // removed because vivoactive crashes
        //Attn.playTone(Attn.TONE_TIME_ALERT); // 12
    }
    
    function resetTimer() {
        m_timer.stop();
        m_timerReachedZero = false;
        m_timerRunning = false;
        m_timerCount = m_timerDefaultCount;
        m_invertColors = false;
        Ui.requestUpdate();
    }

}

class WorkoutTimerMenuDelegate extends Ui.MenuInputDelegate {

    function onMenuItem(item) {
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
            var customDuration = Cal.duration( {:minutes=>1} );
            var customTimePicker = new Ui.NumberPicker(Ui.NUMBER_PICKER_TIME_MIN_SEC, customDuration);
            Ui.popView(Ui.SLIDE_IMMEDIATE);
            Ui.pushView(customTimePicker, new CustomTimePickerDelegate(), Ui.SLIDE_IMMEDIATE);
            //Ui.switchToView(customTimePicker, new CustomTimePickerDelegate(), Ui.SLIDE_IMMEDIATE);
        } else if (item == :item_repeat) {
            toggleRepeat();
        }
    }
    
    function setTimer(time) {
        m_timer.stop();
        m_timerReachedZero = false;
        m_timerRunning = false;
        m_timerDefaultCount = time;
        App.getApp().setDefaultTimerCount(m_timerDefaultCount); // save new default to properties     
        m_timerCount = m_timerDefaultCount;
        m_invertColors = false;
        Ui.requestUpdate();
    }
    
    function toggleRepeat() {
        m_repeat = !m_repeat;
        App.getApp().setRepeat(m_repeat); // save new repeat state to properties
    }
}

class CustomTimePickerDelegate extends Ui.NumberPickerDelegate {
    function onNumberPicked(value) {
        setCustomTimer(value.value());
    }
    
    function setCustomTimer(time) {
        m_timer.stop();
        m_timerReachedZero = false;
        m_timerRunning = false;
        m_timerDefaultCount = time;
        App.getApp().setDefaultTimerCount(m_timerDefaultCount); // save new default to properties
        m_timerCount = m_timerDefaultCount;
        m_invertColors = false;
        Ui.requestUpdate();
    }
}