//
//  GLES_API_Player.hpp
//  Pods-RenderDemo
//
//  Created by Benny LIU on 2019/3/27.
//

#ifndef GLES_API_Player_hpp
#define GLES_API_Player_hpp

#include "Runtime/RenderLib/logger_player_env.h"
#if GLES_WRAPPER_ENABLE

#include <stdio.h>
#include "RendererDevice.h"

class GLES_API_Player
{
public:
    static GLES_API_Player* instance();
    ~GLES_API_Player() = default;
    bool start(AmazingEngine::RendererDevice* rendererDevice,
               std::string = "",
               enum LoggerPlayerOutputMethod outputMethod = LOGGERPLAYER_OUTMETHOD_NO_OUTPUT,
               bool enableThreadId = true);
    bool stop();

    bool updateFrame(unsigned int output);

    void setLoopRange(int begin, int end);

private:
    GLES_API_Player() = default;
    void initFile(enum LoggerPlayerOutputMethod outputMethod, std::string const& logPath);
    FILE* fp = NULL;
    FILE* player_fp = NULL;
    int frame_end = 0;
    int frame_count = 0;
    int player_loop_begin = -1;
    int player_loop_end = -1;
    bool m_Playing = false;
    AmazingEngine::RendererDevice* m_RendererDevice = nullptr;
};

#endif

#endif /* GLES_API_Player_hpp */
