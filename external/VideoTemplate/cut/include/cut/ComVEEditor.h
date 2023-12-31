//
// Created by zhangyeqi on 2019-11-18.
//

#ifndef CUTSAMEAPP_ANDROIDVEEDITOR_H
#define CUTSAMEAPP_ANDROIDVEEDITOR_H

#include <string>
#include "ComObj.h"
#include "VideoData.h"
#include <TemplateConsumer/model.hpp>
#include <TemplateConsumer/Clip.h>
#include <TemplateConsumer/Crop.h>

#define VIDEO_TYPE 0
#define AUDIO_TYPE 1
#define AUDIO_CLIP_INDEX 0

namespace cut {

    enum class ComVEState {
        UNKNOWN = 0, // 未知状态，找不到VEEditor对象，获取状态时出现异常等等
        IDLE = 1,
        ERROR = 2,
        PLAYING = 3,
        PAUSED = 4,
        PREPAREING = 5
    };

    class ComVEEditor {
    public:
        ComVEEditor();

        virtual ~ComVEEditor();

        /**
         * 初始化VE
         * @param surfaceHandler  传入的surface，Android传入SurfaceView、iOS传入UIView
         * @param extraData  额外参数，目前只有Android端需要传入一个Context指针
         *
         * @return 非0表示异常
         */
        // int32_t init(void *surfaceHandler, void *extraData);

        /**
         * 设置VideoData
         * @param data 源VideoData
         *
         * @return 非0表示异常
         */
        virtual int32_t setDataSource(VideoData *data);
        
        virtual int32_t synchronizeProject(std::shared_ptr<CutSame::TemplateModel> project) { return 0; }

        /**
         * 设置视频播放时参数
         * @param config 播放时参数
         * @return 非0表示异常
         */
        virtual int32_t setVideoPreviewConfig(CutSame::VideoPreviewConfig &config) = 0;

        /**
         * 获取状态
         * @return ComVEState
         */
        virtual ComVEState getState() = 0;

        /**
         * 播放
         */
        virtual void play() = 0;

        /**
         * 暂停
         */
        virtual void pause() = 0;

        /**
         * 停止播放
         */
        virtual void stop() = 0;

        /**
         * 视频播放seek
         * @param timestamp 需要seek到的时间，毫秒
         */
        virtual void seek(int64_t timestamp) = 0;

        /**
         * 获取当前播放的时间
         * @return 当前播放到的时间 毫秒
         */
        virtual int64_t getCurPosition() = 0;

        /**
         * 设置播放器状态监听器
         */
        virtual void setPlayerStatusListener(void *listener) = 0;

        /**
         * 获取视频总时长，多段视频获取到的是处理好的总时长
         * @return 视频总时长
         */
        virtual int64_t getDuration() = 0;

        /**
         * 更换视频 路径
         *
         * @param segmentId 代表视频分段/音频分段
         * @param path 更换的视频路径
         *
         * @return 是否更新成功, 0表示成功, 负值表示出错
         *
         * @author zhangyeqi
         */
        virtual int32_t updateVideoPath(const string &segmentId, const string &path) = 0;

        /**
         * 更新视频蒙层
         * @param path           蒙层资源
         * @param paramsJson     蒙层 config json
         * @return 是否更新成功, 0表示成功, 负值表示出错
         */
         // TODO ios对齐
        virtual int32_t updateMask(const string &segmentIdd, const string &path,
                   const string &paramsJson) = 0;

        /**
         * 曲线变速
         * @param params params
         * @param start start
         * @param duration duration
         * @return 是否更新成功, 0表示成功, 负值表示出错
         */
         // TODO ios对齐
        virtual int32_t adjustCurveSpeed(const string &segmentId,
                                 const string &params, const int64_t start,
                                 const int64_t duration, int32_t mode, float speed) = 0;

        /**
         * 计算曲边变速的数据
         * @param params params
         * @return 是否更新成功, 0表示成功, 负值表示出错
         */
         // TODO ios对齐  但这个方法的合理信有待商讨！！！！！建议先空实现
        virtual float calculateAveCurveSpeed(const string &params) = 0;


        /**
         * 更换视频 时间裁剪区域
         *
         * @param sourceStartTime 视频开始时间
         * @param sourceEndTime 视频结束时间
         * @param speed 视频播放速度
         *
         * @return 是否更新成功, 0表示成功, 负值表示出错
         *
         * @author zhangyeqi
         */
        virtual int32_t updateVideoTimeClip(const string &segmentId, const int64_t sourceStartTime,
                                            const int64_t sourceEndTime, const double speed) = 0;

        /**
         * 更换视频 空间裁剪区域
         *
         * @param crop 裁剪区域
         *
         * @return 是否更新成功, 0表示成功, 负值表示出错
         *
         * @author zhangyeqi
         */
        virtual int32_t updateVideoCrop(const string &segmentId, CutSame::Crop &crop) = 0;

        /**
         * 更换视频 位置
         *
         * @return 是否更新成功, 0表示成功, 负值表示出错
         *
         * @author zhangyeqi
         */
        virtual int32_t
        updateVideoTransform(const string &segmentId, float scale, CutSame::Clip &clip) = 0;

        /**
         * 添加视频副轨
         * @param path 副轨视频路径
         * @param blendPath 混合效果文件path
         * @param trimIn 视频开始时间
         * @param trimOut 视频结束时间
         * @param sequenceIn 视频入点
         * @param sequenceOut 视频出点
         * @param layer 视频层级
         * @param alpha 视频透明度
         * @param degree 视频旋转角度
         * @param scaleFactor 视频scale比例
         * @param transX 视频x方向位移
         * @param transY 视频y方向位移
         * @param mirror 视频镜像方式, 为0代表不镜像，为1代表镜像x方向，为2代表镜像y方向
         * @return 返回0表示正常, 返回负值表示出错
         */
        virtual int32_t
        addSubVideo(const string &segmentId, const string &path, const string &blendPath,
                    int64_t trimIn, int64_t trimOut, int64_t sequenceIn, int64_t sequenceOut,
                    int32_t layer, float alpha, int32_t degree, float scaleFactor, float transX,
                    float transY, uint32_t mirror) = 0;

        /**
         * 添加一段背景音乐
         * @param audioFilePath 音乐文件路径
         * @param audioInTimeInMillis 音乐选取的开始时间
         * @param beginTimeInMillis 音乐在整段视频播放时开始播放的时间
         * @param duration 此段音乐播放的时长
         * @param speed 此段音乐播放的速度
         * @param reverse 是否需要倒放
         * @return 返回0表示正常, 返回负值表示出错
         */
        virtual int32_t addAudioTrack(const string &segmentId, const std::string &audioFilePath,
                                      int64_t audioInTimeInMillis,
                                      int64_t beginTimeInMillis, int64_t duration,
                                      float speed, bool reverse) = 0;

        /**
         * 添加特效
         * @param effectPath 特效本地文件绝对路径
         * @param startTime 特效开始时间
         * @param endTime 特效结束时间
         * @return 返回0表示正常, 返回负值表示出错
         */
        virtual int32_t
        addInfoEffect(const string &segmentId, const string &effectPath, int64_t startTime,
                      int64_t endTime, int64_t timeOffset) = 0;

        /**
         * 添加文字贴纸
         * @param text 需要添加的文字，包括配置信息
         * @param effectPath 文字特效/花字
         * @param bubblePath 文字框效果/气泡
         * @param layerWeight 文字层级深度
         * @param startTime 文字开始时间
         * @param endTime 文字结束时间
         * @param x 文字x坐标
         * @param y 文字y坐标
         * @param flipX x轴是否翻转
         * @param flipY y轴是否翻转
         * @param scale 文字scale
         * @param rotate 文字旋转
         * @return 返回0表示正常, 返回负值表示出错
         */
        virtual int32_t
        addTextSticker(const string &segmentId, CutSame::MaterialText &text, const string &effectPath,
                       const string &bubblePath, int64_t layerWeight, int64_t startTime,
                       int64_t endTime, float x, float y, bool flipX, bool flipY, float scale,
                       float rotate, int64_t timeOffset) = 0;


        /**
         * 设置转场
         * @param path 转场效果文件绝对路径
         * @param segmentId 视频segmentId
         * @param duration 转场持续时间
         * @param isOverlap 转场是否交叠前后视频轨
         * @return 返回0表示正常, 返回负值表示出错
         */
        virtual int32_t
        setTransition(const string &path, const string &segmentId, int64_t duration,
                      bool isOverlap) = 0;
        

        /**
         * 设置视频动画
         * @param path 视频动画文件绝对路径
         * @param segmentId segmentId
         * @param startTime 开始时间，毫秒
         * @param duration 持续时间，毫秒
         * @return 是否更新成功, 0表示成功, 负值表示出错
         */
        virtual int32_t
        setVideoAnim(const string &path, const string &segmentId, int64_t startTime,
                     int64_t duration) = 0;

        /**
         * 设置滤镜
         * @param path 滤镜文件路径
         * @param segmentId 视频的segmentId
         * @param intensity 程度 0.0-1.0f
         * @return 是否更新成功, 0表示成功, 负值表示出错
         */
        virtual int32_t
        setVideoFilter(const std::string &path, const string &segmentId, float intensity) = 0;

        /**
         * 设置美颜
         * @param path 美颜滤镜路径
         * @param strength 美颜强度
         * @return 是否更新成功, 0表示成功, 负值表示出错
         */
        virtual int32_t setBeauty(const string &path, const string &segmentId, float strength) = 0;

        /**
         * 形变 瘦脸 大眼等
         * @return 是否更新成功, 0表示成功, 负值表示出错
         */
        virtual int32_t setReshape(const string &path, const string &segmentId, float eyeStrength,
                                   float cheekStrength) = 0;


        /**
         * 画面效果调节 亮度、对比度等
         * @return 是否更新成功, 0表示成功, 负值表示出错
         */
        virtual int32_t
        setPictureAdjust(const string &segmentId, vector<string> &types, vector<float> &strengths,
                         vector<string> &paths) = 0;

        /**
         * 添加信息化贴纸
         * @param infoStickerPath 贴纸绝对路径
         * @param unicode emoji文字unicode码。当 infoStickerPath为空时，则为添加emoji文字贴纸。
         * @param scale 缩放比例
         * @param rotate 旋转角度
         * @param startTime 贴纸开始时间
         * @param endTime 贴纸结束时间
         * @param x x坐标
         * @param y y坐标
         * @param flipX x轴翻转
         * @param flipY y轴翻转
         * @param layerWeight 层级
         * @return 0表示成功, 负值表示出错
         */
        virtual int32_t addInfoSticker(const string &segmentId, const string &infoStickerPath,
                                       const string &unicode, float scale, float rotate,
                                       int64_t startTime, int64_t endTime, float x, float y,
                                       bool flipX, bool flipY, int32_t layerWeight,
                                       int64_t timeOffset) = 0;

        virtual int32_t deleteInfoSticker(const string &segmentId) = 0;

        /**
         * 设置贴纸动画
         * @param inPath 入场动画
         * @param outPath 出场动画
         * @param loop 是否循环
         * @param inDuration 入场持续时间
         * @param outDuration 出场持续时间
         * @return 是否更新成功, 0表示成功, 负值表示出错
         */
        virtual int32_t setStickerAnimation(const string &segmentId, const std::string &inPath,
                                            const std::string &outPath, bool loop,
                                            int64_t inDuration, int64_t outDuration) = 0;

        /**
         * 添加 亮度/褪色/滤镜等调节
         * @param param 滤镜参数，为json字符串
         * @return 是否更新成功, 0表示成功, 负值表示出错
         */
        virtual int32_t
        addAmazingFilter(const string &segmentId, const string &type, const string &path, int order,
                         int64_t seqIn, int64_t seqOut, const string &param,
                         const string &filterSegId) = 0;

        /**
         * 改变音频声音（男声、女声等)
         * @return 是否更新成功, 0表示成功, 负值表示出错
         */
        virtual int32_t changeVoice(const string &segmentId, int type, std::string &voiceName) = 0;

        /**
         * 调整音量
         * @return 是否更新成功, 0表示成功, 负值表示出错
         */
        virtual int32_t adjustVolume(const string &segmentId, int type, float volume) = 0;

        /**
         * 添加音频淡入淡出效果
         * @param segmentId 视频segmentId
         * @param fadeInDuration 淡入时间
         * @param fadeOutDuration 淡出时间
         * @return 是否更新成功, 0表示成功, 负值表示出错
         */
        virtual int32_t
        addAudioFade(const string &segmentId, int64_t fadeInDuration, int64_t fadeOutDuration) = 0;

        /**
         * 获取文本等信息化贴纸的宽高
         * TODO 按-1~1的坐标系，这里应该返回0~2
         */
        virtual vector<float> getInfoStickerSize(const string &segmentId) = 0;

        /**
         * @return 是否更新成功, 0表示成功, 负值表示出错
         */
        virtual int32_t updateTextSticker(const string &segmentId, CutSame::MaterialText &material,
                                          const string &effectPath, const string &bubblePath) = 0;

        /**
         * 变速变调
         * @param reverse 是否保持原调
         */
        virtual int32_t
        setClipReservePitch(int32_t type, const string &segmentId, bool reverse) = 0;

        /**
         * 导出视频文件
         * @param outFilePath 导出视频文件path
         * @param compileParam 导出参数
         * @param compileListener 进度监听
         * @return 是否导出成功, 0表示成功, 负值表示出错
         */
        virtual int32_t
        compile(const std::string &outFilePath, CutSame::VideoCompileParam &compileParam,
                void *compileListener) = 0;

        /**
         * 释放VEEdtor
         */
        virtual void destroy() = 0;

        virtual int32_t dp2px(float dp) = 0;
    };
}


#endif //CUTSAMEAPP_ANDROIDVEEDITOR_H
