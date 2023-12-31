//
// Created by zhangyeqi on 2019-11-26.
//

#ifndef CUTSAMEAPP_TEMPLATESOURCE_H
#define CUTSAMEAPP_TEMPLATESOURCE_H

#include <TemplateConsumer/model.hpp>
#include <memory>
#include "../stream/StreamFunction.h"
#include "../executor/Executor.h"
#include "TemplateSourceObserver.h"
#include "../executor/CountDownLatch.h"
#include "../player/DefaultResourceFetcher.h"

using std::weak_ptr;

namespace cut {

struct TemplateSourceConfig {
    bool isNeedDispatchMaterials = false;
    bool isNeedDispatchMediaPath = true;
};
    /**
     * TemplateSource 代表 TemplatePlayer 播放需要的资源, Project对象及其相关的本地文件;
     * TemplateSource 对象接受一个zip文件路径，通过StreamFunction最终生成Project对象及其相关的本地文件;
     * TemplateSource 对象维护着Project对象并提供getResult()接口获取;
     * 针对Project对象的复杂的修改操作，请通过ProjectEditor工具类实现;
     *
     * [zipFilePath] ➡ [TemplateSource] ➡ [StreamFunction] ➡ [Project+files]
     *                                                               ⬆
     *                                                         [ProjectEditor]
     */
    class TemplateSource : public std::enable_shared_from_this<TemplateSource> {
    public:
        friend class TemplatePlayer;

        static const string SOURCE_TYPE_URL;
        static const string SOURCE_TYPE_ZIP;
        static const string SOURCE_TYPE_JSON;
        static const string SOURCE_TYPE_WORKSPACE; // 暂时仅IOS用到，Android未对上暴露
        static const string SOURCE_TYPE_Project; // 新建的时候直接创建了草稿

        /**
         * 参数 zipFile 用于指定剪同款资源包的获取源
         * 1. 可以是本地文件路径：比如 android 的 /data/data/xxx.zip
         * 2. 可以是网络下载地址：比如 https://www.effect.com/xxx.zip -> 请确保设置了 Downloader
         *
         * TemplateSource 针对 http/https 开头的参数，当做网络下载地址处理
         */
        TemplateSource(const string& workspace, const std::pair<string, string>& sourceInfo, TemplateSourceConfig config = TemplateSourceConfig());

        TemplateSource(const string& workspace, std::shared_ptr<CutSame::TemplateModel> project, TemplateSourceConfig config = TemplateSourceConfig());

        virtual ~TemplateSource();

        /**
         * 需要在 prepare 之前设置
         * @param fetcher fetcher
         */
        void setResourceFetcher(shared_ptr<DefaultResourceFetcher> fetcher);

        /**
         * 准备播放所需资源，下载zip包，解压zip包，生成Project对象，下载贴纸等等；
         * 这是一个耗时操作，请不要在主线程调用；
         *
         * prepare()操作结束后，请通过 {@link #getErrorCode()} 判断操作是否成功
         *
         * prepare()阶段依赖业务方提供EffectResourceFetcher,以及Downloader(如果需要的话)
         *
         * TODO: 支持部分 prepare ？仅下载并解压zip包？
         */
        void prepare();

        /**
         * 这是一个调试用的接口，忽略 fetcher 的错误信息，继续 prepare
         */
        void prepareDecodeOnly();
        
        /**
        * 取消当前的任务
        */
        void cancel();

        /**
         * 设置 prepare() 结果监听；
         * 如果设置时prepare()已经执行完毕，则立刻回调结果（可能成功可能失败）;
         *
         * 目前此接口只在 TemplatePlayer 中调用，还未通过 JNI/OC 等等方式暴露给业务方；
         * 未来要暴露的话，需要将接口改成 addObserver 支持多个监听器
         */
        void addObserver(const shared_ptr<TemplateSourceObserver> &observer);

        void removeObserver(const shared_ptr<TemplateSourceObserver> &observer);

        /**
         * 获取 zip 包解压后的json文件路径
         */
        string getProjectJsonFilePath();

        /**
         * 获取结果，可能为空，通过 setObserver 接口可以监听结果回调;
         * 外部可以通过 getResult() 拿到 Project 对象，然后通过 ProjectEditor 工具类进行修改
         */
        shared_ptr<CutSame::TemplateModel> getResult() const;
//
//        /**
//         * 获取prepare错误码
//         */
//        int getError() const;
//
//        /**
//         * 获取prepare错误描述
//         */
//        string getErrorMsg() const;

        /**
         * 获取 选择Video的约束描述（包含模板zip包中不可更改的视频信息）
         * @see ProjectEditor::getVideoSegments
         */
        std::vector<shared_ptr<CutSame::VideoSegment>> getVideoSegments();

        void setVideoSegments(std::vector<shared_ptr<CutSame::VideoSegment>> &segments);

        /**
         *
         * @param videoSegments videoSegments
         * @return 0表示成功，負值表示出錯
         */
        int32_t setVideoSegments(const std::vector<shared_ptr<CutSame::VideoSegment>> &videoSegments, bool copyToWorkspace);

    protected:
        std::vector<std::shared_ptr<TemplateSourceObserver>> observers;

        string workspaceFolderPath;                 // 输入 - 剪同款本地工作目录

        const std::pair<string, string> sourceInfo;      // 输入 - 资源描述

        volatile bool resultSuccess = false;

        // 创建成功的Project对象，对应TemplateSourceObserver回调中的值
        shared_ptr<CutSame::TemplateModel> result = nullptr;       // 输出 - 成功
        int errorCode = 0;                          // 输出 - 出错信息
        int subErrorCode = 0;
        string errorMsg;                            // 输出 - 出错信息

    private:

        // 理论上，调用方需要 getVideoSegments（此处已经有 result），然后才会调用 setVideoSegments
        // 但是，剪映上层做了优化，videoSegments 可能从外部方式获取，不通过 我们的 getVideoSegments 接口
        // 所以这里对 setVideoSegments 的参数提供缓存，支持在 prepare() 之前调用
        std::vector<shared_ptr<CutSame::VideoSegment>> videoSegments;
        bool copyToWorkspace;

        shared_ptr<DefaultResourceFetcher> resourceFetcher;

        shared_ptr<StreamContext> streamContext;
        shared_ptr<asve::StreamFunction<std::pair<string, string>, shared_ptr<CutSame::TemplateModel>>> stream;

        asve::CountDownLatch prepareLatch{1};

        // 设置 TemplateSource 写操作是否允许
        bool writeAccessible = true;

        /**
         * 设置是否锁住 写操作
         * @param accessible accessible
         */
        void setWriteAccessible(bool accessible);

        static void onFunctionPreSuccess(const weak_ptr<TemplateSource>& weakRef, shared_ptr<CutSame::TemplateModel> project);

        static void onFunctionSuccess(const weak_ptr<TemplateSource>& weakRef, shared_ptr<CutSame::TemplateModel> project);

        static void onFunctionError(const weak_ptr<TemplateSource>& weakRef, int errorCode, int subErrorCode, const string &errorMsg);

        void onFunctionCancel();

        static void onFunctionProgress(const weak_ptr<TemplateSource>& weakRef, int64_t progress);

        /**
         * 外部设置 VideoSegment 时，可能仅仅修改视频路径；未对Crop信息进行修改；
         * 我们需要在这里做一点处理，确保视频的裁剪效果与模板的效果一致；
         * @param videoSegment videoSegment
         */
        void checkVideoSegmentCrop(const shared_ptr<CutSame::VideoSegment>& videoSegment);

        TemplateSourceConfig config;
    };
}

#endif //CUTSAMEAPP_TEMPLATESOURCE_H
