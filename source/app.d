import std.string;
import std.datetime;

import info.mumble.plugin.MumblePlugin;

import blink1;

Blink1Device blink = null;

MumbleStringWrapper wrapMumbleString(string str) {
	MumbleStringWrapper wrapper = {
		data: str.toStringz(),
		size: str.length,
		needsReleasing: false
	};
	return wrapper;
}

struct PatternData {
	ubyte start;
	ubyte end;
}

enum Pattern {
	Connecting
}

PatternData[Pattern] patterns;
mumble_userid_t[mumble_connection_t] myUserIds;

void log(string message) {
	if (mumbleAPI.log(ownID, message.toStringz()) != MUMBLE_STATUS_OK) {
		// Logging failed -> usually you'd probably want to log things like this in your plugin's
		// logging system (if there is any)
	}
}

void setupPatterns() {
	blink.writePatternLine(0, PatternLine(RGB(128, 128, 128), 3.seconds, LED.ALL));
	blink.writePatternLine(1, PatternLine(RGB(64,  64,  64 ), 3.seconds, LED.ALL));
	patterns[Pattern.Connecting] = PatternData(0, 1);
}

void playPattern(Pattern pat, ubyte count = 0) {
	PatternData data = patterns[pat];
	blink.play(data.start, data.end, count);
}

extern(C):
	__gshared MumbleAPI_v_1_0_x mumbleAPI;
	__gshared mumble_plugin_id_t ownID;
	
	mumble_error_t mumble_init(mumble_plugin_id_t pluginID) {
		ownID = pluginID;

		try {
			blink = Blink1Device.open();
			log("Blink(1) device with FW version %s connected!".format(blink.getFwVersion()));
			setupPatterns();
			playPattern(Pattern.Connecting);
			return MUMBLE_STATUS_OK;
		} catch (Blink1NotFoundException e) {
			log("Blink(1) device not found: %s".format(e.message));
			return cast(Mumble_ErrorCode) Mumble_ErrorCode.MUMBLE_EC_GENERIC_ERROR;
		}
	}
	
	void mumble_shutdown() {
		if (mumbleAPI.log(ownID, "Goodbye Mumble") != MUMBLE_STATUS_OK) {
			// Logging failed -> usually you'd probably want to log things like this in your plugin's
			// logging system (if there is any)
		}
		blink.fadeToRGB(0,0,0);
		blink.stop();
	}
	
	MumbleStringWrapper mumble_getName() {
		return wrapMumbleString("Blink1");
	}
	
	mumble_version_t mumble_getAPIVersion() {
		// This constant will always hold the API version  that fits the included header files
		return mumble_version_t (1, 0, 3);
	}
	
	void mumble_registerAPIFunctions(void *apiStruct) {
		// Provided mumble_getAPIVersion returns MUMBLE_PLUGIN_API_VERSION, this cast will make sure
		// that the passed pointer will be cast to the proper type
		// #define MUMBLE_API_CAST(ptrName) (*((struct MUMBLE_API_STRUCT *) ptrName))
		mumbleAPI = *(cast(MumbleAPI_v_1_0_x *) apiStruct);
	}
	
	void mumble_releaseResource(const void *pointer) {
		// As we never pass a resource to Mumble that needs releasing, this function should never
		// get called
		import core.stdc.stdio;
		printf("Called mumble_releaseResource but expected that this never gets called -> Aborting");
		//abort();
	}
	
	MumbleStringWrapper mumble_getAuthor() {
		return wrapMumbleString("Chris Josten");
	}
	
	MumbleStringWrapper mumble_getDescription() {
		return wrapMumbleString("Controls a Blink1 device");
	}
	
	void mumble_onServerSynchronized(mumble_connection_t connection) {
		// Stop the connecting animation
		blink.stop();
		mumble_userid_t userID;
		mumbleAPI.getLocalUserID(ownID, connection, &userID);
		myUserIds[connection] = userID;
		
		// Set the led to the passive state
		blink.fadeToRGB(0, 255, 0,     250.msecs);
	}
	
	void mumble_onUserTalkingStateChanged(mumble_connection_t connection, mumble_userid_t userID,
	                                 mumble_talking_state_t talkingState) {
		if (connection in myUserIds && myUserIds[connection] == userID) {
			switch(cast(int) talkingState) {
			case Mumble_TalkingState.MUMBLE_TS_PASSIVE:
				blink.fadeToRGB(0, 255, 0,     250.msecs);
				break;
			case Mumble_TalkingState.MUMBLE_TS_TALKING:
				blink.fadeToRGB(0, 0,   255,   250.msecs);
				break;
			default:
				break;
			}
		}
	}
