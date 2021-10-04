using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.Timer as Timer;
using Toybox.Attention as Attn;
using Toybox.Time.Gregorian as Cal;
using Toybox.ActivityRecording as Record;
using Toybox.Position as Position;
using Toybox.System as Sys;


class SailingApp extends App.AppBase {

    var session;
    var sailingView;

    var gpsSetupTimer;


    // get default timer count from properties, if not set return default
    function getDefaultTimerCount() {
        var time = getProperty("time");
        if (time != null) {
            return time;
        } else {
            return 300; // 5 min default timer count
        }
    }

    // set default timer count in properties
    function setDefaultTimerCount(time) {
        setProperty("time", time);
    }

    function initialize() {
        Sys.println("app : initialize");
        AppBase.initialize();
    }

    function onStart(state) {
        Sys.println("app : onStart");
        gpsSetupTimer = new Timer.Timer();
        gpsSetupTimer.start(method(:startActivityRecording), 1000, true);

        Position.enableLocationEvents(Position.LOCATION_CONTINUOUS, method(:onPosition));
    }

    //! onStop() is called when your application is exiting
    function onStop(state) {
        Sys.println("app: onStop");
        sailingView = null;
        gpsSetupTimer.stop();
        gpsSetupTimer = null;

        Position.enableLocationEvents(Position.LOCATION_DISABLE, method(:onPosition));
    }

    function saveAndClose() {
        Sys.println("stop pressed");
        stopRecording(true);
        Sys.exit();
    }

    function discardAndClose() {
        Sys.println("stop pressed");
        stopRecording(false);
        Sys.exit();
    }

    function startTimer() {
        Sys.println("app : start timer");
        sailingView.startTimer();
    }

    function fixTimeUp() {
        Sys.println("app : fixTimeUp");
        if (sailingView.isTimerRunning() == true){
            sailingView.fixTimeUp();
        }
    }

    function fixTimeDown() {
        Sys.println("app : fixTimeDown");
        if (sailingView.isTimerRunning() == true){
            sailingView.fixTimeDown();
        }
    }

    function refreshUi() {
        sailingView.refreshUi();
    }

    //! Return the initial view of your application here
    function getInitialView() {
        sailingView = new SailingView();
        return [ sailingView, new SailingDelegate() ];
    }

    function onPosition(info) {
        sailingView.onPosition(info);
    }

    function startActivityRecording() {
        if (Position.getInfo().accuracy > 2.0){
            gpsSetupTimer.stop();
            if( Toybox has :ActivityRecording ) {
                if( ( session == null ) || ( session.isRecording() == false ) ) {
                    Sys.println("start ActivityRecording");
                    var mySettings = Sys.getDeviceSettings();
                    var version = mySettings.monkeyVersion;

                    if(version[0] >= 3) {
                        session = Record.createSession({:name=>"Sailing", :sport=>Record.SPORT_SAILING});
                     }else{
                        session = Record.createSession({:name=>"Sailing", :sport=>Record.SPORT_GENERIC});
                    }
                    session.start();
                }
            }
        }
    }

    function addLap() {
        if( ( session != null ) && session.isRecording() ) {
            session.addLap();
        }
    }

     //! Stop the recording if necessary
    function stopRecording(save) {
        if( Toybox has :ActivityRecording ) {
            if( session != null && session.isRecording() ) {
                session.stop();
                if (save) {
                    session.save();
                } else {
                    session.discard();
                }
                session = null;
            }
        }
    }

}
