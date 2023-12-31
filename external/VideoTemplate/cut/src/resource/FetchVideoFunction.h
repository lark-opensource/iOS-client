//
// Created by zhangyeqi on 2019-12-13.
//

#ifndef CUTSAMEAPP_VIDEOCOMPLETEFUNCTION_H
#define CUTSAMEAPP_VIDEOCOMPLETEFUNCTION_H

#include <TemplateConsumer/TemplateModel.h>
#include "../stream/StreamFunction.h"
#include "../player/ResourceFetcher.h"
#include "../player/ResourceVideoCoder.h"

#include <memory>

namespace cut {

    /**
     * 依赖 ResourceFetcher，input 格式："video://$videoSegmentListJsonString"
     */
    class FetchVideoFunction : public asve::StreamFunction<std::shared_ptr<CutSame::TemplateModel>, std::shared_ptr<CutSame::TemplateModel>>,
              public cut::ResourceFetcherCallback,
              public std::enable_shared_from_this<FetchVideoFunction> {
    public:
        FetchVideoFunction(const shared_ptr<ResourceFetcher> &fetcher);

    protected:
        void run(std::shared_ptr<CutSame::TemplateModel>& project) override;


    public:
        void onSuccess(const string &input, const string &output) override;

        void onError(const string &input, const int errorCode, const string &errorMsg) override;

    private:
        shared_ptr<CutSame::TemplateModel> project;
        ResourceVideoCoder coder{};
        const shared_ptr<ResourceFetcher> &fetcher;
    };
}


#endif //CUTSAMEAPP_VIDEOCOMPLETEFUNCTION_H
