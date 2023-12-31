//
//  logger_player_env.hpp
//  amazing_engine
//
//  Created by wwb on 2019/3/9.
//

#ifndef logger_player_env_hpp
#define logger_player_env_hpp

#include "Gaia/Platform/AMGPlatformDef.h"

#if defined(_DEBUG) || (defined(DEBUG) && DEBUG)
#if AMAZING_PLATFORM == AMAZING_IOS
#define GLES_WRAPPER_ENABLE 0
#elif AMAZING_PLATFORM == AMAZING_ANDROID
#define GLES_WRAPPER_ENABLE 0
#endif
#endif
#ifndef GLES_WRAPPER_ENABLE
#define GLES_WRAPPER_ENABLE 0
#endif

#if GLES_WRAPPER_ENABLE

enum LoggerPlayerLogType
{
    LOGGERPLAYER_LOGTYPE_BINARY = 0,
    LOGGERPLAYER_LOGTYPE_EXPLICIT,
};
enum LoggerPlayerOutputMethod
{
    LOGGERPLAYER_OUTMETHOD_NO_OUTPUT = 0,
    LOGGERPLAYER_OUTMETHOD_TO_FILE,
    LOGGERPLAYER_OUTMETHOD_TO_CONSOLE,
};
#endif

#endif /* logger_player_env_hpp */
