//
// Created by bytedance on 2020/6/7.
//

#ifndef NLEPLATFORM_NLERESTYPE_H
#define NLEPLATFORM_NLERESTYPE_H

#include <memory>
#include <cstdio>
#include <string>
#include "nle_export.h"

namespace cut::model {

    enum NLE_EXPORT_CLASS class NLEResType : int {
        NONE = 0,               ///< 空/无资源/占位节点/无意义
        DRAFT = 1,              ///<草稿文件
        VIDEO = 2,              ///<视频文件
        AUDIO = 3,              ///<音频文件
        IMAGE = 4,              ///<图片文件
        TRANSITION = 5,         ///<转场资源包
        EFFECT = 6,             ///<特效资源包
        FILTER = 7,             ///<滤镜/调节资源包：（仅有一个调节参数）滤镜强度，亮度值，对比度，饱和度，锐化，高光，色温 ...
        STICKER = 8,            ///<贴纸资源包
        FLOWER = 9,             ///<花字资源包
        FONT = 10,              ///<字体资源包
        SRT = 11,               ///<歌词字幕 SRT 文件
        ADJUST = 12,            ///<调节
        ANIMATION_STICKER = 15,   ///<贴纸动画资源包
        ANIMATION_VIDEO = 16,     ///<视频动画资源包
        MASK = 17,                ///<蒙板
        PIN = 18,                 ///<PIN算法文件
        INFO_STICKER = 19,      ///<信息化贴纸资源包
        IMAGE_STICKER = 20,     ///<图片贴纸资源包
        TEXT_STICKER = 21,      ///<文本贴纸资源包
        SUBTITLE_STICKER = 22,  ///<歌词字幕贴纸资源包
        EMOJI_STICKER = 23,     ///<emoji贴纸资源包
        TIME_EFFECT = 24,       ///<内置时间特效
        CHER_EFFECT = 25,       ///<电音
        CHROMA = 26,            ///<色度抠图
        ANIMATION_TEXT = 27,    ///<文字动画资源包
        LYRIC_STICKER = 28,      ///<歌词贴纸
        COMPOSER = 29,           ///<composer
        AUTOSUBTITLE_STICKER = 30, ///<自动字幕
        TEXT_TEMPLATE = 31,         ///<文字模板资源包
        MIX_MODE = 32,          ///<混合模式
        BUBBLE = 33,            ///<气泡
        TEXT_SHAPE = 34,        ///<文字形状
        BEAUTY = 35,            ///<美颜
        SOUND = 36,              ///<音效
        RECORD = 37,              ///<录音
        ALGORITHM_MV_AUDIO = 38,     ///<算法MV模板音频文件
        MUSIC_MV_AUDIO = 39,          ///<音乐MV模板音频文件
        NORMAL_MV_AUDIO = 40,         ///<普通MV模板音频文件
        VOICE_CHANGER_FILTER = 41,  ///<变声
        KARAOKE_USER_AUDIO = 42,  ///<K歌用户唱的声音资源
        ALGORITHM_AUDIO = 43,      ///<算法卡点，需要添加一条音轨，该type标识算法卡点音乐资源。Java/OC VE接口不对外暴露创建音轨的过程，使用VE Public Api时需要手动添加音轨。
        AUDIO_DSP_FILTER = 44,     ///<音频DSP滤镜
        IMAGE_RAW = 45,     ///<RAW数据的图片，不带头信息  暂时仅用于抖音动图功能
    };

    enum class NLEResTag : int {
        NORMAL = 0,       ///<常规资源 抖音资源
        AMAZING = 1,      ///<AMAZING资源 //剪同款资源
    };

    constexpr const char *NLEResTypeToString(const NLEResType &type) {
        switch (type) {
            default:
            case NLEResType::NONE:
                return "NONE";
            case NLEResType::DRAFT:
                return "DRAFT";
            case NLEResType::VIDEO:
                return "VIDEO";
            case NLEResType::AUDIO:
                return "AUDIO";
            case NLEResType::IMAGE:
                return "IMAGE";
            case NLEResType::TRANSITION:
                return "TRANSITION";
            case NLEResType::EFFECT:
                return "EFFECT";
            case NLEResType::FILTER:
                return "FILTER";
            case NLEResType::STICKER:
            case NLEResType::INFO_STICKER:
            case NLEResType::IMAGE_STICKER:
            case NLEResType::TEXT_STICKER:
            case NLEResType::SUBTITLE_STICKER:
            case NLEResType::EMOJI_STICKER:
                return "STICKER";
            case NLEResType::FLOWER:
                return "FLOWER";
            case NLEResType::SRT:
                return "SRT";
            case NLEResType::ANIMATION_STICKER:
                return "ANIMATION_STICKER";
            case NLEResType::FONT:
                return "FONT";
            case NLEResType::ANIMATION_VIDEO:
                return "ANIMATION_VIDEO";
            case NLEResType::ANIMATION_TEXT:
                return "ANIMATION_TEXT";
            case NLEResType::MASK:
                return "MASK";
            case NLEResType::PIN:
                return "PIN";
            case NLEResType::MUSIC_MV_AUDIO:
                return "MUSIC_MV_AUDIO";
            case NLEResType::ALGORITHM_MV_AUDIO:
                return "ALGORITHM_MV_AUDIO";
            case NLEResType::NORMAL_MV_AUDIO:
                return "NORMAL_MV_AUDIO";
        }
    }

    enum class NLECanvasType : int {
        COLOR = 0,          ///<画布类型为纯色
        IMAGE = 1,          ///<画布类型为图片
        VIDEO_FRAME = 2,    ///<画布类型为视频帧
        GRADIENT_COLOR = 3, ///<画布类型为渐变
    };

    enum class NLEClassType : int {
        NONE = 0,               ///<异常
        VIDEO = 2,              ///<视频文件
        AUDIO = 3,              ///<音频文件
        IMAGE = 4,              ///<图片文件
        TRANSITION = 5,         ///<转场
        EFFECT = 6,             ///<特效
        FILTER = 7,             ///<滤镜
        INFO_STICKER = 8,       ///<信息化贴纸
        IMAGE_STICKER = 9,      ///<图片贴纸
        TEXT_STICKER = 10,      ///<文本贴纸
        SUBTITLE_STICKER = 11,  ///<歌词字幕贴纸
        EMOJI_STICKER = 12,     ///<emoji贴纸
        TIME_EFFECT = 13,       ///<内置时间特效
        TEXT_TEMPLATE = 14,     ///<文字模板
        VIDEO_ANIMATION = 15,
        MASK = 16,
        CHROMA = 17,
        MV = 18,                ///<mv类型
    };

    enum class NLEAudioChanger : int {
        NONE = 0,
        BOY = 1,
        GIRL = 2,
        LOLI = 3,
        UNCLE = 4,
        MONSTER = 5
    };

    class NLE_EXPORT_CLASS NLEFilterName {
    public:
        static const std::string COMMON; ///<通用
        static const std::string BRIGHTNESS; ///<亮度
        static const std::string CONTRACT; ///<对比度
        static const std::string SATURATION; ///<饱和度
        static const std::string SHARPEN; ///<锐化
        static const std::string HIGHLIGHT; ///<高光
        static const std::string SHADOW; ///<阴影
        static const std::string TEMPERATURE; ///<色温
        static const std::string TONE; ///<色调
        static const std::string FADE; ///<褪色
        static const std::string LIGHT_SENSATION; ///<光感
        static const std::string VIGNETTING; ///<暗角
        static const std::string PARTICLE; ///<颗粒
        static const std::string HDR; ///<HDR 效果（抖音画质增量）
        static const std::string LENS_HDR; ///<LENS_HDR 效果
        static const std::string BEAUTY; ///<美颜
        static const std::string RESHAPE; ///<瘦脸
        static const std::string AUDIO_COMMON_FILTER; ///<音频滤镜/变声
        static const std::string VIDEO_EFFECT; ///<瘦脸
        static const std::string VIDEO_LENS_HDR; ///<VIDEO_LENS_HDR 效果
        static const std::string AUDIO_LOUDNESS_BALANCE_FILTER; ///<音频滤镜/LOUDNESS_BALANCE
        static const std::string AUDIO_DSP_FILTER; ///<音频滤镜/DSP
        static const std::string AUDIO_VOLUME_FILTER; ///<声音音量滤镜
        static const std::string AI_MATTING; ///<智能抠图
    };
}
#endif //NLEPLATFORM_NLERESTYPE_H
