//
// Created by zhangyeqi on 2019-11-26.
//

#ifndef CUTSAMEAPP_TEMPLATEPLAYER_H
#define CUTSAMEAPP_TEMPLATEPLAYER_H

#include <memory>
#include "cut/ComVEEditor.h"
#include "cut/param/InfoStickerBorderInfo.h"
#include <TemplateConsumer/model.hpp>
#include "ResourceFetcher.h"
#include "DefaultResourceFetcher.h"
#include "ResourceVideoCoder.h"
#include "ResourceEffectCoder.h"
#include "TemplateInfoListener.h"
#include "../resource/TemplateSource.h"
#include "../resource/ProjectEditor.h"
#include "../stream/StreamFunction.h"

using cut::TemplateSource;


namespace cut {

    // 基于 ComVEEditor 的剪同款播放器，这里负责调度整个流程：
    // 1. 接受一个 templateString:JsonString
    // 2. 将 templateString:JsonString 转成 Project 对象
    // 3. 使用 Project 对象操作对应对 ComVEEditor 接口
    // 4. 开始 / 暂停 / 停止
    class TemplatePlayer
            : public TemplateSourceObserver, public std::enable_shared_from_this<TemplatePlayer> {

    public:
        // *******************************************************
        // ********************** 对象基础接口 *********************
        // *******************************************************

        TemplatePlayer(shared_ptr<ComVEEditor> comVEEditor);

        virtual ~TemplatePlayer();

        shared_ptr<ComVEEditor> getComVEEditor() {
            return editor;
        }

//        void setWorkspace(string workspace);

//        void setSurface(void *surfaceHandler, void *extraData);

        // *******************************************************
        // ********************** 播放器接口 ***********************
        // *******************************************************

        /**
         *
         * URL的下载使用默认下载器，业务可以设置Adapter接管下载能力
         *
         * @param type zip/json/http TemplateSource.SOURCE_TYPE
         */
//        void setDataSource(const string &content, const string &type);

        /**
         * 上层已经创建了 TemplateSource, 直接传进来
         * @param source TemplateSource
         * @return 0表示成功，负值表示错误码
         */
        int32_t setDataSource(shared_ptr<TemplateSource> source);
                
        void setProject(shared_ptr<CutSame::TemplateModel> project);
        void synchronizePlayer();

        void setVideoPreviewConfig(CutSame::VideoPreviewConfig &config);

        shared_ptr<CutSame::TemplateModel> getResult();

        ComVEState getState();

        /**
         * 获取prepare错误码
         */
        int getError() const;

        /**
         * 获取prepare错误描述
         */
        const string &getErrorMsg() const;

        int64_t getCurrentPosition();

        int64_t getDuration();

        void setPlayerStatusListener(void *listener);

        /**
         * 耗时阻塞接口
         */
        void prepare();

        void setOnInfoListener(const shared_ptr<TemplateInfoListener> &listener);

        void start();

        void pause();

        void stop();

        void seek(int64_t timeStamp);

        void destroy();

        // ****************************************************
        // ************* "必要资源" 获取的能力接口注入 ************
        // ****************************************************

        /**
         * 设置一个 资源获取器；
         *
         * 可继承 DefaultResourceFetcher, 实现三个接口：
         * onFetchVideo()
         * onFetchEffect()
         * onFetchNormalFile
         */
//        void setResourceFetcher(shared_ptr<ResourceFetcher> fetcher);

        // *****************************************************
        // ******************** 资源读写操作 ********************
        // *****************************************************

        /**
         * 指定 materialId 更新视频资源路径；TODO：调用后 Player 自动从头开始播放？
         * @param materialId 资源id
         * @param path 视频路径
         * @return 错误码 - TemplateError
         */
        int32_t setVideoPath(const string &materialId, const string &path);

        /**
         * 指定 materialId 更新视频时间的裁剪区；TODO：调用后 Player 自动从头开始播放？
         * @param materialId 资源id
         * @param startTime 开始时间
         * @return 错误码 - TemplateError
         */
        int32_t setVideoTimeClip(const string &materialId, int64_t startTime);

        /**
         * 指定 materialId 更新视频空间的裁剪区；TODO：调用后 Player 自动从头开始播放？
         *
         * update Project + applyVideoSpaceClip()
         * @param materialId 资源id
         * @param crop 裁剪信息
         * @return 错误码 - TemplateError
         */
        int32_t setVideoSpaceClip(const string &materialId, CutSame::Crop &crop);

        /**
         * 获取全部 VideoSegment
         */
        std::vector<shared_ptr<CutSame::VideoSegment>> getVideoSegments();

        shared_ptr<CutSame::TailSegment> getTailSegment();

        /**
         * TODO：@柱子：接口注释
         * @return 文字段
         */
        std::vector<CutSame::TextSegment> getTextSegments();

        /**
        * 获取信息化贴纸的边界
        * 返回五个值 中心点x(-1~1) 中心点y(-1~1) 宽度(-1~1) 高度(-1~1) 旋转角度
         * Todo: 以vector的形式返回给业务方用起来有点别扭
        */
        InfoStickerBorderInfo getTextBorder(const string &materialId);

        /**
         * TODO：@柱子：接口注释
         *
         * @param materialId 资源id
         * @param text 文字json
         */
        int32_t changeText(const string &materialId, string text);

        int32_t setSinglePlaySource(const string &materialId, const string &path);

        int32_t compile(const std::string &outFilePath, CutSame::VideoCompileParam &compileParam,
                        void *compileListener);

        void setEpilogueSource(const string &videoPath, const string &textFontPath,
                               const string &textAnimPath);

        void addWatermark(const string &resPath, const float &x, const float &y, const float &scale);

        void removeWatermark();
                
        // void cut::TemplatePlayer::onCreateSuccess(const shared_ptr<Project> &project) {
                void installProject(std::shared_ptr<CutSame::TemplateModel> &project);

    private:

        // ******************** TemplateSource Observer **********************
        void onCreateProgress(int64_t progress) override;

        void onCreateSuccess(const shared_ptr<CutSame::TemplateModel> &project) override;

        void onCreateFailed(int errorCode, int subErrorCode, string errorMsg) override;

        // input member
//        string workspace;
//        shared_ptr<ResourceFetcher> resourceFetcher;
        shared_ptr<TemplateInfoListener> infoListener;

        // inner member
        shared_ptr<TemplateSource> templateSource;
        shared_ptr<CutSame::TemplateModel> project;

        shared_ptr<ComVEEditor> editor;

        // 假如 prepare 未成功，外部调用修改接口，放在这里临时缓存；prepare成功之后，再设置
        map<string, string> setVideoPathCache;
        map<string, int64_t> setVideoTimeClipCache;
        map<string, CutSame::Crop> setVideoSpaceClipCache;

        string singlePlayMaterialId;
        string singlePlayVideoPath;

        int32_t errorCode = 0;
        string errorMsg = "";

        string epilogueVideoPath = ""; //片尾的视频资源路径
        string epilogueFontPath = ""; // 片尾的文字字体路径
        string epilogueTextAnimPath = ""; // 片尾的文字动画路径

        string watermarkId = ""; // 应用了水印则为非空字符串，没有则为空字符串

        /**
         * 还原audio效果
         */
        int32_t initAudioEffect(CutSame::Segment &segment, int64_t index, int type);

        void initAudioFade(CutSame::Segment segment);

        int32_t initAudioAction();

        int32_t initMaskAction();

        int32_t initVideoTrack();

        int32_t initMainVideoTrack();
                
        int32_t initSubVideo();

        int32_t initSticker();

        int32_t initEffect(CutSame::Segment &segment, int index);

        int32_t initVideoEffect();

        int32_t initText();

        int32_t initImage();

        /**
         * 贴纸动画
         * 包括 1.文本贴纸  2.图片贴纸  3.信息化贴纸
         */
        int32_t initStickerAnim(CutSame::Segment &seg);

        /**
         * 全局调节  亮度等
         */
        int32_t initGlobalAdjust();

        /**
         * 全局滤镜
         */
        int32_t initGlobalFilter();

        int32_t initGlobalFilterOrAdjust(CutSame::Segment &filterOrAdjustSeg, std::shared_ptr<CutSame::MaterialEffect> materialmaterial);

        /**
         * 初始化片尾视频
         */
        int32_t initEpilogueVideo(CutSame::Segment &segment, VideoData &videoData);

        /**
         * 初始化片尾文字
         * 这个要在VEEditor.prepare之后调用
         */
        int32_t initEpilogueText();

        /**
         * 更新片尾视频的显示位置
         * @param clipIndex 片尾的clipIndex
         * @param scale 片尾文字&视频的整体缩放比例
         * @param textHeight 需要根据文字高度计算视频的位置
         */
        int32_t initEpilogueVideoTransform(int32_t clipIndex, float scale, float textHeight);

        string getMaterialEffectPath(CutSame::Segment &seg, const string &type);

        /**
         * 获取导出视频的size
         * @param expectWidth 期望宽高 如 1280*720(720p) 1920*1080(1080p)
         * @param expectHeight expectHeight
         * @return size
         */
        std::pair<uint32_t, uint32_t> getCompileVideoSize(uint32_t expectWidth, uint32_t expectHeight);

        void singlePlayPreProcess();

        void initVideoMask(CutSame::Segment &seg, uint32_t clipIndex) const;

        void initVideoCurveSpeed(CutSame::Segment &seg, uint32_t clipIndex) const;
    };

}


#endif //CUTSAMEAPP_TEMPLATEPLAYER_H
