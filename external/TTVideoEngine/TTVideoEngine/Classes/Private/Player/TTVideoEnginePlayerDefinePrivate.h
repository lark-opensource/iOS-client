//
//  TTVideoEnginePlayerDefine.h
//  Article
//
//  Created by guikunzhi on 16/12/2.
//
//


#import "TTVideoEnginePlayerDefine.h"

inline static BOOL TTVideoIsNullObject(id value)
{
    if (!value) return YES;
    if ([value isKindOfClass:[NSNull class]]) return YES;

    return NO;
}

// avoid float equal compare
inline static BOOL TTVideoIsFloatZero(float value)
{
    return fabsf(value) <= 0.00001f;
}

inline static BOOL TTVideoIsFloatEqual(float value1, float value2)
{
    return fabsf(value1 - value2) <= 0.00001f;
}

static inline NSString *RenderEngineGetName(TTVideoEngineRenderEngine engine) {
    switch (engine) {
        case TTVideoEngineRenderEngineOpenGLES:
            return @"OpenGLES";
            break;
        case TTVideoEngineRenderEngineMetal:
            return @"Metal";
            break;
        case TTVideoEngineRenderEngineOutput:
            return @"Output";
            break;
        case TTVideoEngineRenderEngineSBDLayer:
            return @"SBDL";
            break;
        default:
            break;
    }
    return @"";
}

NS_INLINE NSString *playbackStateString(TTVideoEnginePlaybackState state) {
    switch (state) {
        case TTVideoEnginePlaybackStateStopped:
            return @"Stopped";
        case TTVideoEnginePlaybackStatePlaying:
            return @"Playing";
        case TTVideoEnginePlaybackStatePaused:
            return @"Paused";
        case TTVideoEnginePlaybackStateError:
            return @"Error";
        default:
            return @"Undefine";
            break;
    }
}

inline static const char *loadStateGetName(TTVideoEngineLoadState state) {
    switch (state) {
        case TTVideoEngineLoadStateUnknown:
            return "TTVideoEngineLoadStateUnknown";
        case TTVideoEngineLoadStatePlayable:
            return "TTVideoEngineLoadStatePlayable";
        case TTVideoEngineLoadStateStalled:
            return "TTVideoEngineLoadStateStalled";
        case TTVideoEngineLoadStateError:
            return "TTVideoEngineLoadStateError";
            
        default:
            break;
    }
    return "";
}

inline static const char *stallReasonGetName(TTVideoEngineStallReason reason) {
    switch (reason) {
        case TTVideoEngineStallReasonNone:
            return "TTVideoEngineStallReasonNone";
        case TTVideoEngineStallReasonNetwork:
            return "TTVideoEngineStallReasonNetwork";
        case TTVideoEngineStallReasonDecoder:
            return "TTVideoEngineStallReasonDecoder";
            
        default:
            break;
    }
    return "";
}

// NSNumber (MPMovieFinishReason)
extern NSString *const TTVideoEnginePlaybackDidFinishReasonUserInfoKey;

typedef NS_ENUM(NSInteger,TTVideoEngineLogSource) {
    TTVideoEngineLogSourceEngine        = 0,
    TTVideoEngineLogSourcePlayer        = 1,
    TTVideoEngineLogSourceMDL           = 2,
};

NS_INLINE NSString *userActionString(TTVideoEngineUserAction action) {
    switch (action) {
        case TTVideoEngineUserActionInit:
            return @"init";
            break;
        case TTVideoEngineUserActionPrepare:
            return @"Prepare";
            break;
        case TTVideoEngineUserActionPlay:
            return @"Play";
            break;
        case TTVideoEngineUserActionPause:
            return @"Pause";
            break;
        case TTVideoEngineUserActionStop:
            return @"Stop";
            break;
        case TTVideoEngineUserActionClose:
            return @"Close";
            break;
        default:
            return @"Undefine";
            break;
    }
}

NS_INLINE NSString *stateString(TTVideoEngineState state) {
    switch (state) {
        case TTVideoEngineStateUnknown:
            return @"Unknown";
            break;
        case TTVideoEngineStateFetchingInfo:
            return @"FetchingInfo";
            break;
        case TTVideoEngineStateParsingDNS:
            return @"ParsingDNS";
            break;
        case TTVideoEngineStatePlayerRunning:
            return @"PlayerRunning";
            break;
        case TTVideoEngineStateError:
            return @"Error";
            break;
        default:
            return @"Undefine";
            break;
    }
}

