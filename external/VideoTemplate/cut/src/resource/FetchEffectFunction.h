//
// Created by zhangyeqi on 2019-12-02.
//

#ifndef CUTSAMEAPP_FETCHEFFECTFUNCTION_H
#define CUTSAMEAPP_FETCHEFFECTFUNCTION_H

#include <TemplateConsumer/TemplateModel.h>
#include "cdom/ModelType.h"
#include "../stream/StreamFunction.h"
#include "../player/ResourceEffectCoder.h"

namespace cut {
    /**
     * 依赖 ResourceFetcher，input 格式："effect://$resourceId/$resourceType"
     */
    class FetchEffectFunction
            : public asve::StreamFunction<shared_ptr<CutSame::TemplateModel>, shared_ptr<CutSame::TemplateModel>>,
              public cut::FetchEffectCallback,
              public std::enable_shared_from_this<FetchEffectFunction> {

    public:
        FetchEffectFunction(const shared_ptr<DefaultResourceFetcher> &fetcher):
                  mfetcher(fetcher) {};

        virtual ~FetchEffectFunction();
                  
        static std::vector<std::string> getAllEffectIds(const shared_ptr<CutSame::TemplateModel> &templateModel);
                  
        static std::vector<shared_ptr<FetchEffectRequest>> getAllEffectIdRequest(const shared_ptr<CutSame::TemplateModel> &project);

        void run(shared_ptr<CutSame::TemplateModel>& in) override;

        void onError(FetchEffectRequest *req, const FetchError &error) override;
        
        void onSucces(const std::vector<std::shared_ptr<FetchEffectRequest>> &reqs) override;
        
        void onCanceled() override;

    private:
        clock_t startRunTime = 0;
        shared_ptr<CutSame::TemplateModel> project;
        shared_ptr<DefaultResourceFetcher> mfetcher;
        ResourceEffectCoder coder{};

        map<std::string, shared_ptr<FetchEffectRequest>> requestCache;
        int fetchRequestCount = 0; // 发起多少次request，这个值可能比requestCache.size()要大
        std::atomic<int> fetchResponseCount = {0};
        void addRequest(const string &resourceId, const string &resourceType, const cdom::MaterialType type, std::string *path);
        void addRequest(const string &resourceId, const string &resourceType, const cdom::MaterialType type, const cdom::EffectSourcePlatformType effectSourcePlatformType , std::string *path);
        void onRespone(const cdom::MaterialType type, const string &filepath, string* path);
        void increaseAndCheckNotify();
        void addCoverRequest();
    };
}


#endif //CUTSAMEAPP_FETCHEFFECTFUNCTION_H
