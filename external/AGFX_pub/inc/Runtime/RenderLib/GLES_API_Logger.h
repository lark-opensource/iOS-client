//
//  GLES_API_Logger.hpp
//  Pods-RenderDemo
//
//  Created by Benny LIU on 2019/3/27.
//

#ifndef GLES_API_Logger_hpp
#define GLES_API_Logger_hpp

#include "Runtime/RenderLib/logger_player_env.h"
#if GLES_WRAPPER_ENABLE

#include <stdio.h>
#include "RendererDevice.h"

class GLES_API_Logger
{
public:
    static GLES_API_Logger* instance();
    ~GLES_API_Logger() = default;
    bool start(std::string file_path = "",
               enum LoggerPlayerOutputMethod outputMethod = LOGGERPLAYER_OUTMETHOD_TO_FILE,
               enum LoggerPlayerLogType logType = LOGGERPLAYER_LOGTYPE_BINARY);
    bool stop();

    bool frameBegin();
    bool logTexture(DeviceTexture texId, bool readData = false, AmazingEngine::RendererDevice* device = nullptr, int minification = 1);

    bool frameEnd(DeviceTexture outTex);
    bool pause();
    bool resume();

private:
    GLES_API_Logger() = default;
    bool m_Logging = false;
    std::string m_file_path;
    enum LoggerPlayerLogType m_LogType = LOGGERPLAYER_LOGTYPE_BINARY;
    enum LoggerPlayerOutputMethod m_OutputMethod = LOGGERPLAYER_OUTMETHOD_TO_FILE;
    bool m_ThreadIdEnabled = true;
};

#endif

#endif /* GLES_API_Logger_hpp */
