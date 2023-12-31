#pragma once
#include <stdlib.h>
#include <stdint.h>
#include <memory.h>
#include <string.h>
#include "av_config.h"
#include "av_namespace.h"

#define S_END 0xfffffff
#define S_LOOPED 0xf000000
#define S_OWNER 100
#define S_RESET 101
#define S_PARA  102
#define S_PICTURE_OK 103
#define S_CODEC_FAIL 104
#define S_BUSY  105
#define S_SEEK_FAIL 106
#define S_OK 0
#define S_FAIL -1
#define S_DETACHED -2
#define S_INACTIVE -3
#define S_WINDOW_FAIL -4
#ifdef __LICENSE__
#define S_AUTH_FAIL -30001
#endif
#define S_TRUE 1
#define S_BLOCK 2
#define S_FALSE 0
#define S_CHNAGED 3
#define S_EAGAIN 4
#define S_PARAMETER 5
#define S_SKIP 6
#define S_NEXT 7
#define S_NO_CODEC 110


#define S_TIMEDOUT -0xf1
#define MEM_VALID_VALUE (0x55555555)
#define UNLOCK_VALUE (MEM_VALID_VALUE)
#define LOCK_VALUE   (MEM_VALID_VALUE+1)
#define BASH_STREAM_CHANGED (0x0008)

#define SPADE_METHOD_TOB "2"

#ifndef UINT64_C
#define UINT64_C(c) (c ## ULL)
#endif
//----------------set get key value-----------
#define getKeyValueBegin()                   switch((key&0xffff)){
#define getKeyValueInt(dst_key,member)                  case dst_key:{\
return member;\
}
#define getKeyValueIntFromSource(dst_key,source)  case dst_key:{\
if(source){\
return source->getIntValue(key,dValue);}\
else{\
return dValue;}\
}

#define getKeyValueIntFromMoreSource(dst_key,first,second) case dst_key:{\
int value = dValue;\
const AVValue* source = first;\
if(source != nullptr) {\
    value = source->getIntValue(dst_key,dValue);\
    if(value != dValue){\
        return value;\
    }\
}\
source = second;\
if(source != nullptr) {\
    return source->getIntValue(dst_key,dValue);\
}\
return dValue;\
}

#define getKeyValueIntFromSourceTo(dst_key,target_key,source) \
case dst_key:{\
if(source != nullptr){\
return source->getIntValue(target_key|(key&0xffff0000),dValue);}\
else{\
return dValue;}\
}

#define getKeyValueInt64FromSource(dst_key,source)  case dst_key:{\
if(source){\
return source->getInt64Value(key,dValue);}\
else{\
return dValue;}\
}

#define getKeyValueFun(dst_key,fun,value,size)          case dst_key:{\
return fun(value,size);\
}

#define getKeyValueFunWithKey(dst_key,target_key,fun,value,size)          case dst_key:{\
return fun(target_key|(key&0xffff0000),value,size);\
}

#define getKeyValueFromSource(dst_key,source,value,size)   case dst_key:{\
if(source != nullptr){\
return source->getValue(key,value,size);}\
else{\
return S_FAIL;}\
}

#define getKeyValuePtr(dst_key,ptr)                     case dst_key:{\
return reinterpret_cast<intptr_t>(ptr);\
}

#define getKeyValueStrongFromBox(dst_key,sp)             case dst_key:{ \
strong.reset(sp.strong());\
return S_OK;\
}

#define getKeyValueStrongFromSource(dst_key,source) \
case dst_key:{\
if(source){\
return source->getStrong(dst_key,strong);}\
else{\
return S_OK;}\
}

#define getKeyValueStrong(dst_key,sp)             case dst_key:{ \
strong.reset(sp);\
return S_OK;\
}

#define getKeyValueStrongNull(dst_key) \
case dst_key: {                        \
strong.drop();                         \
return S_OK;                           \
}

#define getKeyValueStrongFunWithKey(dst_key,fun)             case dst_key:{ \
fun(dst_key,strong);\
return S_OK;\
}

#define getKeyValueStrongFromSourceTo(dst_key,target_key,source) \
case dst_key:{\
if(source){\
return source->getStrong(target_key|(key&0xffff0000), strong);}\
else{\
return S_OK;}\
}

#define setKeyValueStrong(dst_key,sp)          case dst_key: {\
sp.reset(strong);\
return S_OK;\
}

#define getKeyValuePtrFromSource(dst_key,source) \
case dst_key:{\
if(source){\
return source->getPtrValue(key);}\
else{\
    return reinterpret_cast<intptr_t>(nullptr);}\
}

#define getKeyValuePtrFromSourceTo(dst_key,target_key,source) \
case dst_key:{\
if(source != nullptr){\
return source->getPtrValue(target_key|(key&0xffff0000));}\
else{\
return S_OK;}\
}
#define getKeyValue(type,key,member)     case key:{\
if(sizeof(type) > size){\
return -1;}\
type* pValue =  static_cast<type*>(value);\
*pValue = member;\
return S_OK;\
}
#define getKeyValueST(key,type,member) case key:{\
if(value == nullptr || size == 0 || sizeof(type) != size) {\
return S_FAIL;\
}\
memcpy(value,member,sizeof(type));\
return S_OK;\
}
#define getKeyValueFloat(key,member) case key:{\
if(value == nullptr || sizeof(float) != size ){\
return -1;}\
*((float*)value) = member;\
return S_OK;\
}

#define getKeyValueFloatFun(key,fun) case key:{\
if (value == nullptr || sizeof(float) != size){\
return S_FAIL;}\
*((float*)value) = fun();\
return S_OK;\
}

#define getKeyValueIntFun(key,fun)   case key:{\
return fun(dValue);\
}
#define getKeyValueIntKeyFun(dst_key,fun)   case dst_key:{\
return fun(key,dValue);\
}
#define getKeyValueIntKeyFunWithOutKV(dst_key,fun)   case dst_key:{\
return fun();\
}
#define getKeyValuePtrKeyFunWithOutKV(dst_key, fun)   case dst_key:{\
return fun();\
}
#define getKeyValuePtrKeyFun(dst_key, fun)   case dst_key:{\
return fun(dst_key);\
}
#define getKeyValueEnd(name)         default:{\
return name::getValue(key,value,size);\
}\
}
#define getKeyValueInt32End(name)  default:{\
return name::getIntValue(key,dValue);\
}\
}
#define getKeyValueInt64End(name)  default:{\
return name::getInt64Value(key,dValue);\
}\
}

#define getKeyValueInt32DefaultEnd(dValue)    default:{\
return dValue;\
}\
}
#define getKeyValuePtrEnd(name)                 default:{\
return name::getPtrValue(key);\
}\
}
#define getKeyValueStrongEnd(name)                 default:{\
return name::getStrong(key, strong);\
}\
}
#define setKeyValueStrongEnd(name)                 default:{\
return name::setStrong(key, strong);\
}\
}
#define getKeyValueBreakEnd()                       default:{\
break;\
}\
}
#define setKeyValueBegin()                   switch((key&0xffff)){

#define setKeyValue(type,key,member)     case key:{\
const type* pValue =  static_cast<const type*>(value);\
member = *pValue;\
return 0;\
}
#define setKeyValueString(key,member)    case key:{\
const char* pValue =  static_cast<const char*>(value);\
if(member != nullptr) {\
delete [] member;\
member = nullptr;\
}\
if(size <= 0){return S_FAIL;}\
member = new char[size+1];\
memcpy(member,pValue,size);\
member[size] = 0;\
return 0;\
}
#define setKeyValueFloat(key,member) case key:{\
if(value == nullptr || size != sizeof(float)) {\
return -1;\
}\
member = *((float*)value);\
return 0;\
}
#define setKeyValueInt(key,member)            case key:{\
member = value;\
return 0;\
}
#define setKeyValueIntEstimate(key,member)            case key:{\
if(value != member) {member = value;}\
return 0;\
}
#define setKeyValueIntWithValue(key,member,uvaule)            case key:{\
member = uvaule;\
return 0;\
}
#define setKeyValueInt32FromSource(key,source)   case key:{\
if(source){\
return source->setIntValue(key,value);}\
else{\
return S_FAIL;}\
}

#define setKeyValueInt32FromStrong(key,source) case key:{ \
auto sp = source;                                      \
if(sp) {\
    return sp->setIntValue(key,value);}\
else{\
return S_FAIL;}\
}

#define setKeyValueIntFromSource(key,source) case key:{\
AVValue* pointer = source;\
if(pointer != nullptr) {\
    return pointer->setIntValue(key,value);}\
else{\
return S_FAIL;}\
}\

#define setKeyValueIntFromStrong(key,strong) case key:{\
if(strong) {\
    return strong->setIntValue(key,value);}\
else{\
return S_FAIL;}\
}
#define setKeyValueStrongFun(key,fun)          case key:{\
return fun(strong);\
}
#define setKeyValueInt64FromSource(key,source)   case key:{\
if(source != nullptr){\
return source->setInt64Value(key,value);}\
else{\
return S_FAIL;}\
}

#define setKeyValueIntKeyFun(key,fun)          case key:{\
return fun(key,value);\
}
#define setKeyValueIntFun(key,fun)          case key:{\
return fun(value);\
}
#define setKeyValueParamFun(key,fun,param)          case key:{\
return fun(value,param);\
}
#define setKeyValueFromSource(key,source)   case key:{\
if(source != nullptr){\
return source->setValue(key,value,size);}\
else{\
return S_FAIL;}\
}
#define setKeyValueFun(key,fun)          case key:{\
return fun(value,size);\
}
#define setKeyValueKeyFun(key,fun)          case key:{\
return fun(key,value,size);\
}
#define setKeyValueST(key,type,dst)          case key:{\
if(value == nullptr || size == 0 || sizeof(type) != size || dst == nullptr) {\
return S_FAIL;\
}\
memcpy((void*)dst,value,size);\
return S_OK;\
}
#define setKeyValuePtrCast(key,member,dst_type) case key:{\
    member = (dst_type)value;\
    return S_OK;\
}
#define setKeyValueInt32End(name)         default:{\
return name::setIntValue(key,value);\
}\
}
#define setKeyValueInt64End(name)         default:{\
return name::setInt64Value(key,value);\
}\
}
#define setKeyValuePtrEnd(name)           default:{\
return name::setPtrValue(key,value);\
}\
}
#define setKeyValueEnd(name)         default:{\
return name::setValue(key,value,size);\
}\
}

#define OPEN_SOURCE(source,ret,fail) if(source != NULL) {\
ret = source->open();\
if(ret != 0)\
goto fail;\
}
#define START_SOURCE(source,ret)      if(source){\
ret = source->start();\
if(ret != 0){\
return ret;\
}\
}
#define STOP_SOURCE(source)          if(source ){\
source->stop();\
}

//template<class T>
//T get_object(long v){
//    return reinterpret_cast<T>(v);
//}
#define START_SOURCE_L(source) pthread_mutex_lock(&mMutex);\
if(source) {\
source->start();\
}\
pthread_mutex_unlock(&mMutex);

#define STOP_SOURCE_L(source) pthread_mutex_lock(&mMutex);\
if(source) {\
source->stop();\
}\
pthread_mutex_unlock(&mMutex);

#define CLOSE_SOURCE(source) if(source){\
if(source->getOwner() == mOwner) {\
source->close();\
}}
#define CLOSE_DELETE_SOURCE(source) if(source != nullptr){\
if(source->getOwner() == mOwner) {\
source->close();\
delete source;\
source = nullptr;\
}}
#define DELETE_BUFFER(buffer) if(buffer != nullptr){\
buffer->giveBack();\
buffer = nullptr;\
}
#define MKPG(a,b,c,d) (a|(b<<8)|(c<<16)|(d<<24))
#define AV_TIMEOUT 1

#define DELETE_STRING(str) if(str != nullptr){delete []str;str = nullptr;}
#define DELETE_OBJECT(object) if(object != nullptr){delete object;object = nullptr;}
#define MEMCPY_STRING(dst,src) if(src != nullptr){\
size_t len = strlen(src);\
if(dst != nullptr){\
delete dst;\
dst = nullptr;}\
if(len > 0){\
dst = new char[len + 1];\
memcpy(dst,src,len);\
dst[len] = 0;\
}}
#define MEMCPY_NAME(name)   if(name != nullptr) {\
                                size_t len =strlen(name);\
                                if(len == 0) {\
                                    LOGW("name len is zore.");\
                                    return;\
                                }\
                                if(len >= MAX_NAME_SIZE) {\
                                    len = MAX_NAME_SIZE-1;\
                                }\
                                memset(mName,0,MAX_NAME_SIZE);\
                                memcpy(mName, name, len);\
                                mName[len] = 0;\
                            }
#define CLEAR_QUEUE(queue)        {AVBuffer* buffer;\
while((buffer = queue.dequeue_l(AVList<AVBuffer*>::TRY)) != nullptr) {\
    buffer->giveBack();\
}}
#define CLOSE_FD(fd)             \
    if (fd > 0) {                \
        LOGK("close fd:%d", fd); \
        ::close(fd);             \
        fd = 0;                  \
    }
#define CLOSE_PIPE(pipe) {\
                            for(int i=0;i<2;i++){\
                                if(pipe[i] > 0){\
                                    ::close(pipe[i]);\
                                    pipe[i] = 0;\
                                }\
                            }\
                        }
#define WRITE_PIPE(pipe,str)    if(pipe[1] > 0) {\
                                    ::write(mPipe[1], str, strlen(str));\
                                }
#define CHECK_STOPED() if(mState == IsStoped) {return;}
#define CHECK_CLOSED() if(mState == IsClosed) {return;}

#ifdef __cplusplus
//NOTE: unknown is defined in windows.h 
NS_BASE_BEGIN

enum AVConversionMatrixType {
    BT601,
    BT709,
};
enum PlayType {
    IsLivePlay  = 0,
    IsVodPlay   = 1,
    IsRtcPlay   = 2,
};
enum PlayerType {
    Is_AVBasePlayer     = 0,
    Is_AVDummyPlayer    = 1,
    Is_AVBytertsPlayer  = 2,
};
enum AVStreamType {
    VideoStream,
    AudioStream,
    SubtStream,
    StreamNB,
};
enum InfoType{
    AV_FATAL_INFO = 0,
    AV_ERROR_INFO= 1,
    AV_STATE_INFO = 2,
};
enum CaptureType{
    CaptureTypeNone = 0,
    CaptureTypePic = 1,
    CaptureTypeMP4 = 2,
    CaptureTypeVideo = 3,
};
enum AVVideoDecoderType {
    IS_SOFTWARE_CODECER,
    IS_HARDWARE_CODECER,
};
enum AVDrmType {
    DrmTypeNone,
    DrmTypeIntertrust,
};
enum VTBOutputType {
    VTBOutputTypeDefault,
    VTBOutputTypeRGB,
};
enum ABRSwitchAction {
    Unknown = 0,
    Downgrade = 1,
    Upgrade = 2,
};

enum TranErrorType {
    ErrOpen = 0,
    ErrRead = 1,
    ErrWrite = 2,
};

enum TTPlayerDebugState {
    TTPlayerStateUnknown = 0,
    TTPlayerDnsParsing,
    TTPlayerTCPConnecting,
    TTPlayerTCPConnected,
    TTPlayerTCPFirstPacket,
    TTPlayerFormatProbing,
    TTPlayerFirstMediaPackage,
        
    TTPlayerDecoderInitialing,
    TTPlayerRenderInitialing,
    TTPlayerFirstFrameDisplayed,    
};

NS_BASE_END

#endif

#define DST_PARAME 1
#define SRC_PARAME 0
#define STREAM(stream,key) (key|(stream<<16))
#define VIDEOS(a) (a|(VideoStream<<16))
#define AUDIOS(a)  (a|(AudioStream<<16))
#define ALLS(a)  (a|(StreamNB<<16))
#define DST_PARAM(a) (a|(DST_PARAME<<16))
#define SRC_PARAM(a) (a|(SRC_PARAME<<16))
#define IS_SRC_PARAM(a) ((a>>16)&1 == SRC_PARAME)
#define IS_DST_PARAM(a) ((a>>16)&1 == DST_PARAME)

#ifndef AV_NOPTS_VALUE
#define AV_NOPTS_VALUE          ((int64_t)UINT64_C(0x8000000000000000))
#endif
#ifndef AV_PKT_FLAG_KEY
#define AV_PKT_FLAG_KEY     0x0001 ///< The packet contains a keyframe
#endif
#ifndef AV_PKT_FLAG_CORRUPT
#define AV_PKT_FLAG_CORRUPT 0x0002 ///< The packet content is corrupted
#endif
#ifndef AV_PKT_FLAG_SWITCH
#define AV_PKT_FLAG_SWITCH 0x0010 ///< The packet is first switch packet
#endif
#ifndef AV_PKT_FLAG_EOF
#define AV_PKT_FLAG_EOF     0x4000 ///< The packet reach stream id eof
#endif
#ifndef AV_PKT_FLAG_FIRST_LIVE
#define AV_PKT_FLAG_FIRST_LIVE 0x5000 ///< The first live packet
#endif
#define MAX_IP_LEN 132
#define VIDEO_FRAME_LINE_SIZE_COUNT 8
#define OPNE_MEDIA_FAIL_TO_TRY 1
#define OPNE_MEDIA_FAIL_NOT_TRY 0
typedef uint64_t aptr_t;
#define MAKE_KS(key,stream_index) (key|(stream_index<<16))
#define GET_STREAM(v) (v>>16)
#define GET_VALUE(v) (v&0xffff)
#define getAPtr(source) ((aptr_t)(source != nullptr ? source->getPtrValue(KeyIsAppWrapperPtr) : 0))
#define INVAL_SERIAL -1
#define DISABLE 0
#define ENABLE  1
#define AV_NOT_DISCARD -100000

#define MAX_AVOUTSYNC_LIST 120

#define AV_FRAME_DROP_0 0
#define AV_FRAME_DROP_1 1
#define AV_FRAME_DROP_2 2
#define AV_FRAME_DROP_3 3

#define AV_SPEED_NO_SET 0.0f
#define AV_SPEED_NORMAL 1.0f

#define AV_ABR_HURRY_THRESHOLD 0.2f
#define AV_ABR_LOW_THRESHOLD   0.4f
#define AV_ABR_HIGH_THRESHOLD  0.75f
#define AV_ABR_REBUFF_PENALTY  8.6f
#define AV_ABR_SAFE_BUFFER  0.75f
#define AV_ABR_TARGET_BUFFER  2.5f
#define AV_ABR_PID_KP  0.5f
#define AV_ABR_PID_KI  0.4f
#define AV_ABR_PID_KD  0.1f
#define AV_ABR_BANDWIDTH_DOWN_PARAMETER 0.75f

#define AV_CV_PIXEL_BUFFER_REF_SIZE  0x1ffffff1
#define AV_FF_YUV_BUFFER_REF_SIZE    0x1ffffff2
#define AV_FF_PCM_BUFFER_REF_SIZE    0x1ffffff3
#define AV_FF_PACKET_BUFFER_REF_SIZE 0x1ffffff4
#define AV_CLEAR_SCREEN_BUFFER_SIZE  0x1ffffff5

#define AVBufQueue  AVQueue<AVBuffer*>
#define AVBufStack  AVStack<AVBuffer*>

#define aint_t int
#define aint_value(a) a
#define IsChangeWindowView 1
#define MAX_NAME_SIZE 16

#define AV_INVALID_DIMENSIONS   0xFFFF
#define CREATE_VIDEO_CROP_AREA_FRAME_PATTERN(x, y, w, h)    ((uint64_t(x) << 48) | (uint64_t(y) << 32) | (uint64_t(w) << 16) | (uint64_t(h) << 0))
#define VIDEO_CROP_AREA_ORIGIN_X(pattern)                   int16_t((pattern >> 48) & 0xFFFF)
#define VIDEO_CROP_AREA_ORIGIN_Y(pattern)                   int16_t((pattern >> 32) & 0xFFFF)
#define VIDEO_CROP_AREA_SIZE_WIDTH(pattern)                 int16_t((pattern >> 16) & 0xFFFF)
#define VIDEO_CROP_AREA_SIZE_HEIGHT(pattern)                int16_t((pattern >>  0) & 0xFFFF)
#define INVALID_VIDEO_CROP_AREA_PATTERN                     CREATE_VIDEO_CROP_AREA_FRAME_PATTERN(AV_INVALID_DIMENSIONS, AV_INVALID_DIMENSIONS, AV_INVALID_DIMENSIONS, AV_INVALID_DIMENSIONS)
#define IS_INVALID_VIDEO_CROP_AREA_PATTERN(pattern)         (pattern == INVALID_VIDEO_CROP_AREA_PATTERN)

#ifndef AV_MIN
#define AV_MIN(x,y) ((x) < (y) ? (x) : (y))
#endif
#ifndef AV_MAX
#define AV_MAX(x,y) ((x) > (y) ? (x) : (y))
#endif

#ifndef AV_ABS
#define AV_ABS(a) ((a) >= 0 ? (a) : (-(a)))
#endif

#ifndef AV_FLOAT_EQUAL
#define AV_FLOAT_EQUAL(x, y, epsilon) (fabs((x) - (y)) <= (epsilon) ? true : false)
#endif
