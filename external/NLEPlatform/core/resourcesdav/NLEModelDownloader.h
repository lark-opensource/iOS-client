//
// Created by panruijie on 2021/5/30.
//

#ifndef CUT_ANDROID_NLEMODELDOWNLOADER_H
#define CUT_ANDROID_NLEMODELDOWNLOADER_H

#include "NLEResourceDownloadCallback.h"
#include "NLESingleResourceDownloadCallback.h"
#include "NLEModelDownloaderParams.h"
#include "NLEResourceListDownloadCallback.h"

namespace davinci {
    namespace resource {
        class DAVResourceManager;
    }
    namespace executor {
        class DefaultExecutor;
        class Executor;
    }
}

namespace TemplateConsumer {

    class NLEModelDownloader {

    public:

        NLEModelDownloader(shared_ptr<TemplateConsumer::NLEModelDownloaderParams> params);

        virtual ~NLEModelDownloader() = default;

        std::vector<std::shared_ptr<cut::model::NLEResourceNode>> fetchSync(const std::vector<std::shared_ptr<cut::model::NLEResourceNode>> &resourceNodes);
        /**
         * 下载nlemodel中的资源
         * @param nModel
         * @param callback
         * @return taskId
         */
        std::string fetch(const std::shared_ptr<cut::model::NLEModel> nModel,
                          const int32_t fetchThreadCount,
                          const shared_ptr<TemplateConsumer::NLEResourceDownloadCallback> callback);

        /**
         * 传入effect id list
         * @param effectList, 例如 {"30377", "50501"}
         * @param fetchThreadCount 并发下载线程数
         * @param callback
         * @return taskId
         */
        std::string fetchEffectList(const vector<std::string> effectList,
                   const int32_t fetchThreadCount,
                   const shared_ptr<TemplateConsumer::NLEResourceListDownloadCallback> callback);

        /**
         * 根据达芬奇资源id，下载单个资源
         * @param davinciResourceId
         * @param callback
         */
        void fetch(const std::string &davinciResourceId,
                   const shared_ptr<TemplateConsumer::NLESingleResourceDownloadCallback> callback);

        /**
         * 根据taskid取消下载任务
         * 因为达芬奇下载器不支持取消已经在执行中的任务，对于已经开始执行的，需要等待执行结束；未开始执行的，会跳过对应任务(不执行)
         * @param taskId
         * @return
         */
        bool cancelFetch(const std::string &taskId);

        /**
         * 判断当前effectid是否已缓存
         * @param effectId
         * @return
         */
        bool hasCache(const std::string &effectId);

    private:
        std::shared_ptr<TemplateConsumer::NLEModelDownloaderParams> params;
        std::shared_ptr<davinci::resource::DAVResourceManager> davResourceManager = nullptr;
        std::shared_ptr<std::map<std::string, bool>> fetchTaskMap = nullptr;
        std::shared_ptr<std::vector<std::string>> notSupportEffects = nullptr;

        /**
         * 单个下载任务，下载达芬奇资源 （支持loki, url, 算法模型）
         * @param davinciResourceIds
         * @param fetchThreadCount
         * @param callback
         * @return taskId
         */
        std::string fetch(const vector<std::string> davinciResourceIds,
                          const int32_t fetchThreadCount,
                          const shared_ptr<TemplateConsumer::NLEResourceListDownloadCallback> callback);

        /**
         * 该资源是否需要下载(已经缓存或者下载失败的则不需要下载)
         * @param effectId
         * @return
         */
        bool isNeedFetch(const std::string &effectId);

        #ifdef __ANDROID__
            std::shared_ptr<davinci::executor::DefaultExecutor> executor;
        #else
            std::shared_ptr<davinci::executor::Executor> executor;
        #endif
    };

}

#endif //CUT_ANDROID_NLEMODELDOWNLOADER_H
