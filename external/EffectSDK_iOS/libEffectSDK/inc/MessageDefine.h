//
// Created by lizhiqi on 2018/4/27.
//

#ifndef EFFECT_SDK_MESSAGEDEFINE_H
#define EFFECT_SDK_MESSAGEDEFINE_H

// Message type, corresponding to the unMsgID parameter in the msgProc interface
#define RENDER_MSG_TYPE_RESOURCE               0x00000011
#define RENDER_MSG_TYPE_2D_ANIMATION_CYCLE     0x00000012 // End of sequence frame playback
#define RENDER_MSG_TYPE_BODY_DANCE             0x00000013
#define RENDER_MSG_TYPE_EFFECT                 0x00000014
#define RENDER_MSG_TYPE_AUDIO_PLAYER           0x00000015
#define RENDER_MSG_TYPE_APP_STATUS             0x00000016
#define RENDER_MSG_TYPE_ALGORITHM_CHANGE       0x00000017
#define RENDER_MSG_TYPE_ENIGMA                 0x00000018
#define RENDER_MSG_TYPE_MONITOR                0x00000019
#define RENDER_MSG_TYPE_PAGE                   0x00000020

#define RENDER_MSG_TYPE_ARSCAN                 0x0000001A // AR scan triggers egg or jump message
#define RENDER_MSG_TYPE_ALGO_SCENE             0x0000001B
#define RENDER_MSG_TYPE_STICKER_LOCATION       0x0000001C // Sticker location information
#define RENDER_MSG_TYPE_FACE_INFO              0x0000001D

#define RENDER_MSG_TYPE_PIXELLOOP_START        0x0000001E
#define RENDER_MSG_TYPE_PIXELLOOP_FINISH       0x0000001F
#define RENDER_MSG_TYPE_3DV3                   0x00000020
#define RENDER_MSG_TYPE_AVATAR_DISTANCE_TOO_CLOSE   0x00000021

#if BEF_ALGORITHM_CONFIG_NOT_USE_MEMEFIT || BEF_ALGORITHM_CONFIG_NOT_USE_MEMEFIT_SAFE
#define RENDER_MSG_TYPE_MEMOJI_SCAN_INFO       0x00002000
#endif

#ifdef BEF_FEATURE_CONFIG_AMAZING_MEME_FIT
// memoji to memefit
#define RENDER_MSG_TYPE_MEMEFIT_SCAN_INFO       0x00002000
#define RENDER_MSG_TYPE_MEMEFIT_SCAN_BEGIN                   0x00001
#define RENDER_MSG_TYPE_MEMEFIT_SCAN_NORMAL                  0x00002
#define RENDER_MSG_TYPE_MEMEFIT_SCAN_NO_FACE                 0x00003
#define RENDER_MSG_TYPE_MEMEFIT_SCAN_TOO_MANY_FACE           0x00004
#define RENDER_MSG_TYPE_MEMEFIT_SCAN_FACE_NEED_CORRECT       0x00005
#define RENDER_MSG_TYPE_MEMEFIT_SCAN_FACE_CHANGE             0x00006
#define RENDER_MSG_TYPE_MEMEFIT_SCAN_COMPLETE                0x00007
#define RENDER_MSG_TYPE_MEMEFIT_SCAN_FACE_UNKNOW_ERROR       0x00008
#define RENDER_MSG_TYPE_MEMEFIT_SCAN_MERGE_END               0x00009
#endif

#define RENDER_MSG_TYPE_TWISTER_INFO           0x00000026
#define RENDER_MSG_TYPE_TWISTER_END            0x00000027

#define RENDER_MSG_TYPE_LIVE_INTERACTION       0x00000028
#define RENDER_MSG_TYPE_CLIENT_INTERACTION     0x00000029
#define RENDER_MSG_TYPE_GAME_DATA              0x0000002A     //client <-> effect: game data
#define RENDER_MSG_TYPE_AUDIO_RECORD           0x0000002B     //effect -> livecore: record control
#define RENDER_MSG_TYPE_GAME_MUSIC_END         0x0000002C     //client -> effect: game music play end
#define RENDER_MSG_TYPE_GAME_REQ               0x0000002D     //effect -> client: game req
#define RENDER_MSG_TYPE_GAME_NTF               0x0000002E     //client -> effect: game ntf
#define RENDER_MSG_TYPE_GAME_MUSIC_REQ         0x0000002F     //effect -> client: game music req
#define RENDER_MSG_TYPE_START_RECORD           0x00000030     //effect -> client: game start record
#define RENDER_MSG_TYPE_STOP_RECORD            0x00000031     //effect -> client: game stop record
#define RENDER_MSG_TYPE_STICKER_LOAD_CNT       0x00000032     //client -> effect: game load cnt
#define RENDER_MSG_TYPE_STICKER_ASK_LOAD_CNT   0x00000033     //effect -> client: ask for load cnt message

#define RENDER_MSG_TYPE_ARSCAN_STICKER         0x00000035 // effect -> client: AR scan to switch sticker messages
#define RENDER_MSG_TYPE_VRBRUSH_STICKER        0x00000036 // effect -> client: VR brush sticker message
#define RENDER_MSG_TYPE_LIVE_MAGIC_GESTURE_INFO 0x00000037    //effect -> ieslivekit: magic gesture info
#define RENDER_MSG_TYPE_LIVE_ACTIVITY_INFO      0x00000038    //effect <-> ieslivekit: live activity info

#define RENDER_MSG_TYPE_LIVE_GIFT_NOTIFY       0x00000039    //effect -> ieslivekit: gift notify

#define RENDER_MSG_TYPE_LIVE_OGC_INFO          0x00000040    //effect -> ieslivekit: ogc info (bullet request, player status notify)
#define RENDER_MSG_TYPE_M10N_INFO              0x00000042    //effect <-> m10n: interaction data

#define RENDER_MSG_TYPE_FACE_MAKEUP_INFO       0x00000041    // client -> effect: face makeup info

#define RENDER_MSG_TYPE_GENERAL_AUDIO          0x0000003A    // sdk --> VE, general audio
#define RENDER_MSG_TYPE_VE_AUDIO               0x0000003B    // VE --> sdk, general audio

//green screen layout
#define RENDER_MSG_TYPE_FOREGROUND_DURATION     0x0000003C    // effect -> client: foreground appearance duration
#define RENDER_MSG_TYPE_FOREGROUND_ENOUGH       0x0000003D    // effect -> client: foreground appears long enough
#define RENDER_MSG_TYPE_RED_ENVELOPE_BORDER     0x0000003E    // effect -> client : red envelope border notification

// performance msg
#define RENDER_MSG_TYPE_EFFECT_PERF                  0x0000003F // effect -> VE/client

// performance msg arg1
#define RENDER_MSG_TYPE_EFFECT_PERF_FIRSTFRAME_COST  0x000001 // effect first frame rendering time


// AR scan to switch sticker message arg1
#define RENDER_MSG_TYPE_ARSCAN_STICKER_RENDER   0x000001 // Rendering stickers
#define RENDER_MSG_TYPE_ARSCAN_STICKER_ENTRY    0x000002 // Entrance sticker (generally only contains various recognition algorithms)

// ar scan triggers egg or jump message arg1
#define RENDER_MSG_TYPE_ARSCAN_ALGORITHM        0x000001 // Algorithm recognition results
#define RENDER_MSG_TYPE_ARSCAN_OTHER            0x000002 // Other triggering methods (such as clicking stickers, etc.)

// ar scan triggers egg or jump message arg2
#define RENDER_MSG_TYPE_ARSCAN_UNAVAILABLE      0x000001
#define RENDER_MSG_TYPE_ARSCAN_MATCHING         0x000002
#define RENDER_MSG_TYPE_ARSCAN_TRACKED          0x000003
#define RENDER_MSG_TYPE_ARSCAN_LOSING           0x000004
#define RENDER_MSG_TYPE_ARSCAN_LOST             0x000005
#define RENDER_MSG_TYPE_ARSCAN_ERROR            0x000006

// VR brush sticker message
#define RENDER_MSG_TYPE_VRBRUSH_MODE_ROTATION     0x00000001 // Rotate view mode
#define RENDER_MSG_TYPE_VRBRUSH_MODE_STROKE       0x00000002 // Stroke mode
#define RENDER_MSG_TYPE_VRBRUSH_MODE_RECTANGLE    0x00000003 // Rectangle mode
#define RENDER_MSG_TYPE_VRBRUSH_MODE_CIRCLE       0x00000004 // Circle mode
#define RENDER_MSG_TYPE_VRBRUSH_MODE_ERASE        0x00000005 // Erase mode
#define RENDER_MSG_TYPE_VRBRUSH_MODE_UNDO         0x00000006 // Undo operator
#define RENDER_MSG_TYPE_VRBRUSH_MODE_REDO         0x00000007 // Redo operator
#define RENDER_MSG_TYPE_VRBRUSH_MODE_RESET        0x00000008 // Reset operator

#define RENDER_MSG_TYPE_VRBRUSH_UNDO_STACK        0x00000010 // Undo/Redo Stack depth
#define RENDER_MSG_TYPE_VRBRUSH_REDO_STACK        0x00000011

// RTC Cloud Render
#define BEF_MSG_TYPE_CLOUD_RENDERING                        0x00000060
// RTC arg1
// Client -> Effect
#define BEF_MSG_PARAM_CLOUD_RENDERING_INIT_INFO             0x00001
#define BEF_MSG_PARAM_CLOUD_RENDERING_EXTRA_INFO            0x00002
// Effect -> Client
#define BEF_MSG_PARAM_CLOUD_RENDERING_WAIT_INIT             0x00001
#define BEF_MSG_PARAM_CLOUD_RENDERING_INIT_OVERTIME         0x00002
#define BEF_MSG_PARAM_CLOUD_RENDERING_CATON_OVERTIME        0x00003
#define BEF_MSG_PARAM_CLOUD_RENDERING_SUCCESS               0x00004

#if BEF_ALGORITHM_CONFIG_NOT_USE_MEMEFIT || BEF_ALGORITHM_CONFIG_NOT_USE_MEMEFIT_SAFE
//memoji arg1
#define RENDER_MSG_TYPE_MEMOJI_SCAN_BEGIN                   0x00001
#define RENDER_MSG_TYPE_MEMOJI_SCAN_NORMAL                  0x00002
#define RENDER_MSG_TYPE_MEMOJI_SCAN_NO_FACE                 0x00003
#define RENDER_MSG_TYPE_MEMOJI_SCAN_TOO_MANY_FACE           0x00004
#define RENDER_MSG_TYPE_MEMOJI_SCAN_FACE_NEED_CORRECT       0x00005
#define RENDER_MSG_TYPE_MEMOJI_SCAN_FACE_CHANGE             0x00006
#define RENDER_MSG_TYPE_MEMOJI_SCAN_COMPLETE                0x00007
#define RENDER_MSG_TYPE_MEMOJI_SCAN_FACE_UNKNOW_ERROR       0x00008
#define RENDER_MSG_TYPE_MEMOJI_SCAN_MERGE_END               0x00009
#endif

#define RENDER_MSG_TYPE_NAVI_FIT_INFO    0x00002001
// navifit arg1
#define RENDER_MSG_TYPE_NAVI_FIT_SUCCESS                     0x00000
#define RENDER_MSG_TYPE_NAVI_FIT_ERROR_NO_FACE               0x00001
#define RENDER_MSG_TYPE_NAVI_FIT_ERROR_TOO_MANY_FACE         0x00002
#define RENDER_MSG_TYPE_NAVI_FIT_ERROR_BAD_POSE              0x00003
#define RENDER_MSG_TYPE_NAVI_FIT_ERROR_BAD_LIGHTING          0x00004
#define RENDER_MSG_TYPE_NAVI_FIT_ERROR_BAD_EXPRESSION        0x00005
#define RENDER_MSG_TYPE_NAVI_FIT_ERROR_ALGO_INIT_FAILED      0x00006
#define RENDER_MSG_TYPE_NAVI_FIT_ERROR_ALGO_RUNTIME_FAILED   0x00007

#define RENDER_MSG_TYPE_FACE_ATTRIBUTIONS      0x00000022  // Face attributes
#ifndef TRANSPARENCY_CENTER_I18N
#define RENDER_MSG_TYPE_FACE_VERIFY            0x00000023  // Face feature vector
#endif
#define BEF_MSG_TYPE_WEATHER_INFO              0x00001010  // client -> effect: weather information

// Weather type, corresponding to arg3 parameter
#define BEF_MSG_TYPE_WEATHER_SUNNY              "sunny"
#define BEF_MSG_TYPE_WEATHER_CLOUDY             "cloudy"
#define BEF_MSG_TYPE_WEATHER_SUNLESS            "sunless"
#define BEF_MSG_TYPE_WEATHER_RAINY              "rainy"
#define BEF_MSG_TYPE_WEATHER_THUNDERSTORM       "thunderstorm"
#define BEF_MSG_TYPE_WEATHER_SNOW               "snow"
#define BEF_MSG_TYPE_WEATHER_HAZE               "haze"
#define BEF_MSG_TYPE_WEATHER_FOGGY              "foggy"
#define BEF_MSG_TYPE_WEATHER_SANDSTORM          "sandstorm"
#define BEF_MSG_TYPE_WEATHER_WINDY              "windy"
#define BEF_MSG_TYPE_WEATHER_OTHERS             "others"

///////////////////////arg1 parameter type/////////////////////////////////
#define RENDER_MSG_EVENT_EXIT_GAME       0x00000000  // RENDER_MSG_TYPE_GAME_REQ arg1: exit game
#define RENDER_MSG_EVENT_REPLAY_GAME     0x00000001  // RENDER_MSG_TYPE_GAME_REQ arg1: restart game
#define RENDER_MSG_EVENT_GAME_READY      0x00000002  // RENDER_MSG_TYPE_GAME_REQ arg1: game resource is ready
#define RENDER_MSG_EVENT_GAME_END        0x00000003  // RENDER_MSG_TYPE_GAME_REQ arg1: game end
#define RENDER_MSG_EVENT_STOP_GAME_BGM   0x00000000  // RENDER_MSG_TYPE_GAME_MUSIC_REQ arg1: stop playing bgm
#define RENDER_MSG_EVENT_PLAY_GAME_BGM   0x00000001 // RENDER_MSG_TYPE_GAME_MUSIC_REQ arg1: start playing bgm

#define RENDER_MSG_EVENT_AUDIO_RECORD_START      0x00000000  // RENDER_MSG_TYPE_AUDIO_RECORD arg1, effect->livecore
#define RENDER_MSG_EVENT_AUDIO_RECORD_STOP       0x00000001  // RENDER_MSG_TYPE_AUDIO_RECORD arg1, effect->livecore
#define RENDER_MSG_EVENT_AUDIO_RECORD_FILEPATH   0x00000002  // RENDER_MSG_TYPE_AUDIO_RECORD arg1, livecore->effect

// arg1 for RENDER_MSG_TYPE_GENERAL_AUDIO
#define RENDER_MSG_EVENT_AUDIO_INIT            0x00000001
#define RENDER_MSG_EVENT_AUDIO_FILE_WRITTEN    0x00000002
// arg1 for RENDER_MSG_TYPE_VE_AUDIO
#define RENDER_MSG_EVENT_RECORD_CLIP_KEY 0x00000002


#define BEF_MSG_TYPE_WEATHER_LEVEL1             0x00000001
#define BEF_MSG_TYPE_WEATHER_LEVEL2             0x00000002
#define BEF_MSG_TYPE_WEATHER_LEVEL3             0x00000003
#define BEF_MSG_TYPE_WEATHER_LEVEL4             0x00000004

#define RENDER_MSG_TYPE_ANIMATION_FINISH       0x00000101

// Background switching message type
#define RENDER_MSG_TYPE_APP_STATUS_PAUSE       0x0000000
#define RENDER_MSG_TYPE_APP_STATUS_RESUME      0x0000001

// Event status : initialization
#define RENDER_MSG_EVENT_LOAD_INIT             0x00000001
// Event status : loading
#define RENDER_MSG_EVENT_LOAD_LOADING          0x00000002
// Event status : Successfully loaded
#define RENDER_MSG_EVENT_LOAD_SUCCESS          0x00000003
// Event status : Failed to load
#define RENDER_MSG_EVENT_LOAD_FAIL             0x00000004

//temp
#define RENDER_MSG_EVENT_WILL_SWITCH_EFFECT    0x00000005
#define RENDER_MSG_EVENT_DID_SWITCH_EFFECT     0x00000006

// Music path
#define RENDER_MSG_EVENT_MUSIC_PATH           0x00000007
// lua call
#define RENDER_MSG_EVENT_TRIGGER                0x00000008
// (Slot B) Event status : effect first frame message
#define RENDER_MSG_EVENT_EFFECT_FIRST_FRAME    0x00000009
// (Slot C) Event status : the first frame of composer resources change
#define RENDER_MSG_EVENT_EFFECT_COMPOSER_FIRST_FRAME    0x0000000a

#define RENDER_MSG_EVENT_2D_ANIMATION_CYCLE_FINISH    0x00000005 // End of sequence frame playback
// Error type : Configuration parsing error, it may be caused by incompatible configuration file format after upgrade
#define GPU_MSG_ERROR_TYPE_CONFIG           0x00001001

#define RENDER_MSG_TYPE_BODY_DANCE_CATEGORY_ADJUST              0x00000001
#define RENDER_MSG_TYPE_BODY_DANCE_CATEGORY_SCORE               0x00000002


#define RENDER_MSG_TYPE_AUDIO_PLAYER_START           0x00000001
#define RENDER_MSG_TYPE_AUDIO_PLAYER_END             0x00000002
#define RENDER_MSG_TYPE_AUDIO_PLAYER_PAUSE           0x00000003
#define RENDER_MSG_TYPE_AUDIO_PLAYER_RESUME          0x00000004

#define RENDER_MSG_TYPE_PAGE_PREVIEW                 0x00000001 // Preview status
#define RENDER_MSG_TYPE_PAGE_CAPTURE                 0x00000002 // Photo status
#define RENDER_MSG_TYPE_PAGE_RECORD                  0x00000003 // Recording status
#define RENDER_MSG_TYPE_PAGE_ALBUM                   0x00000004 // Album import
#define RENDER_MSG_TYPE_PAGE_VOIP                    0x00000005 // Video call

// Monitoring message type
#define RENDER_MSG_TYPE_MONITOR_END                 0x00000001



#define GAME_MSG_TYPE_START_NTF                    0x00001001  //client -> effect: Start game notification
#define GAME_MSG_TYPE_END_NTF                      0x00001002  //client -> effect: End game notification
#define GAME_MSG_TYPE_END_REQ                      0x00001003  //effect -> client: End game request
#define GAME_MSG_TYPE_PAUSE_NTF                    0x00001004  //client -> effect: Pause game notification
#define GAME_MSG_TYPE_RESUME_NTF                   0x00001005  //client -> effect: Resume game notification
#define GAME_MSG_TYPE_RESTART_NTF                  0x00001006  //client -> effect: Restart game notification
#define GAME_MSG_TYPE_CHALLENGE_NTF                0x00001007  //client -> effect: Challenge game notification, nArg1 is opponent's score
#define GAME_MSG_TYPE_RESOURCE_LOADED              0x00001008  //effect -> client: game resource is loaded


/// RENDER_MSG_TYPE_ALGORITHM_CHANGE
#define BEF_ALGORITHM_CHANGE_FACE_COUNT              0x00000001

#define RENDER_MSG_TYPE_ENIGMA_COMPLETE              0x00000001
#define RENDER_MSG_TYPE_ENIGMA_PARAM_ERROR           0x00000002

// Input keyboard
#define BEF_MSG_TYPE_SHOW_INPUT_KEYBOARD      0x0000020
#define BEF_MSG_TYPE_HIDE_INPUT_KEYBOARD      0x0000021

#define BEF_MSG_TYPE_DEBUG_INFO_GPU_MEMPORY      0x0000023 // effect -> client: Current GPU memory value (arg2)
#define BEF_MSG_TYPE_OPEN_DEBUG_INFO             0x0000024 // client -> effect: enable(arg2 = 1)/disable(arg2 = 0) GPU memory monitoring
#define BEF_MSG_TYPE_FEATURE_DEBUG_INFO          0x0000025 // feature debug infomation

#define BEF_MSG_TYPE_LOG_MONITOR                0x0000040
// arg1
#define BEF_MSG_TYPE_LOG_MONITOR_LOAD_STICKER           0x0000001
#define BEF_MSG_TYPE_LOG_MONITOR_LOAD_MODEL             0x0000002
#define BEF_MSG_TYPE_LOG_MONITOR_LOAD_VIDEO_FEATURE     0x0000003

#define BEF_MSG_TYPE_VIDEO_CONTROL              0x00000034 // effect -> client: Control video background
// Control video background: arg1
#define BEF_MSG_TYPE_VIDEO_CONTROL_PLAY         0x0000001 // Play
#define BEF_MSG_TYPE_VIDEO_CONTROL_PAUSE        0x0000002 // Pause
#define BEF_MSG_TYPE_VIDEO_CONTROL_RESTART      0x0000003 // restart

// XT Message
#define BEF_MSG_TYPE_XT_PHOTO_FRAME             0x00001011 // client -> effect: XT frame&background
#define RENDER_MSG_TYPE_XT_PHOTO_FRAME_BGCOLOR  0x0000001  // background color
#define RENDER_MSG_TYPE_XT_PHOTO_FRAME_TRS      0x0000002  // trs info

// Live Message
#define BEF_MSG_TYPE_LIVE_INFO                  0x00000043 // effect <-> client: message communication

// livecore audio recognize sticker arg1 
#define BEF_MSG_TYPE_AUDIO_RECOGNIZE            0x3F3F // 16191 base10

#define BEF_MSG_TYPE_IMAGE_CAPTURE              0x00000045 // effect -> client: image captured
#define BEF_MSG_TYPE_GENERAL_STATUS             0x00000046 // effect -> client: send in lua generally, expose various status information to client, used to manage, etc.

// camera status
#define BEF_MSG_TYPE_SWITCH_CAMERA_POSITION     0x00000047 // effect -> client:
#define RENDER_MSG_EVENT_CAMERA_TO_FRONT        0x00000001 // arg1 to front
#define RENDER_MSG_EVENT_CAMERA_TO_BACK         0x00000002 // arg1 to back
#define RENDER_MSG_EVENT_CAMERA_SWITCH          0x00000003 // arg1 switch
//

// record video
#define BEF_MSG_TYPE_RECORD_VIDEO               0x00000048 // effect -> VE/client

#define BEF_MSG_TYPE_SWITCH_TO_AR_MODE          0x00000050 // effect -> ve: ntf ve to open ARCore with the config

//replay pb msg
#define BEF_MSG_TYPE_PB_FAKE_ALGORITHM     0x00003636

#define BEF_MSG_TYPE_PREFAB_OPERATION           0x00000052 // effect <-> ve: Message for prefab interactive operation

#define BEF_MSG_TYPE_SPEECH_CAPT                0x00000054
#define BEF_MSG_TYPE_RECREATE_EFFECT            0x00000070  // effect <-> client: Message for whether to recreate effect

#if BEF_ALGORITHM_CONFIG_RAWDATA_REPLAY
#define BEF_MSG_TYPE_ALGORITHM_REPLAY           0x00000055 //client -> effect: send rawData algorithm replay message
#define BEF_MSG_TYPE_ALGORITHM_REPLAY_SETPATH   0x00000001 //client -> effect: send new data path
#endif


#if BEF_FEATURE_CONFIG_EFFECT_EDITOR_SDK
// Effect Editor
#define BEF_MSG_TYPE_EDITOR_EXPORT_RESOURCE            0x00008000     // effect -> VE/client: export resource
#define BEF_MSG_TYPE_EDITOR_UPDATE_VALUE_TO_EFFECT     0x00008001     // VE/client -> effect: update sticker's values
#define BEF_MSG_TYPE_EDITOR_UPDATE_FINISHED            0x00008011     // effect -> effect: notify effect update finished
#define BEF_MSG_TYPE_EDITOR_UPDATE_VALUE_TO_CLIENT     0x00008111     // effect -> VE/client: update sticker's values
#endif

#endif //EFFECT_SDK_MESSAGEDEFINE_H
