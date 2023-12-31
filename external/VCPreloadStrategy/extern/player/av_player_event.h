//
// Created by teddy on 11/30/20.
//

#pragma once
#include "av_player_event_base.h"

PEV_NAMESPACE_BEGIN

typedef enum : int {
    PlayerEventPrepare = 1,
    PlayerEventPlay = 2,
    PlayerEventPause = 3,
    PlayerEventSeek = 4,
    PlayerEventSwitch = 5,
    PlayerEventBufferStart = 6,
    PlayerEventBufferEnd = 7,
    PlayerEventStop = 8,
    PlayerEventClose = 9,
    PlayerEventIORequest = 10,
    PlayerEventSidxUpdate = 11,
    PlayerEventPrepared = 12,
    PlayerEventRenderStart = 13,
    PlayerEventOpenVideoCodec = 14,

    PlayerEventMP4 = 1000,
    PlayerEventMdatOffset = 1001,
    ///
    PlayerEventDash = 2000,
    ///

} PlayerEventType;

typedef struct IOEventContext {
    char url[4096];
    uint64_t off;
    uint64_t end_off;
} IOEventContext;

typedef enum : int {
    TYPE_VIDEO = 0,
    TYPE_AUDIO,
} PlayerMediaType;

typedef struct SidxItem {
    int index;
    int64_t offset;
    int64_t timestamp;
    int64_t duration;
    int64_t size;
} SidxItem;

typedef struct SidxInfo {
    int media_type;  // see PlayerMediaType
    int total_num;   // total length of stream segment list
    int start_index; // start index of AVSidxItem window in AVSidxInfo
    int end_index;   // end index of AVSidxItem window in AVSidxInfo
    int64_t bitrate; // bitrate of this stream
    char *file_id;   // file hash id of this stream file
    SidxItem *items; // the windowed item
} SidxInfo;

class IPlayer;

class IPlayerEvent { /// callback
public:
    virtual ~IPlayerEvent() {}

    virtual void onPlayerEvent(IPlayer *player,
                               PlayerEventType eventType,
                               long eventParam,
                               long eventCode,
                               void *object = nullptr,
                               const char *extraInfo = nullptr) = 0;
};

PEV_NAMESPACE_END
