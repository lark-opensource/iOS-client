//
// Created by zhangyeqi on 2019-12-02.
//

#ifndef CUTSAMEAPP_DOWNLOADFUNCTION_H
#define CUTSAMEAPP_DOWNLOADFUNCTION_H

#include "../stream/StreamFunction.h"
#include "TemplateSource.h"
#include <string>
#include <memory>

namespace cut {

    /**
     * 依赖 ResourceFetcher，input 格式："normal://$url"
     */
    class DownloadFunction
            : public asve::StreamFunction<std::pair<string, string>, std::pair<string, string>>,
              public cut::ResourceFetcherCallback,
              public std::enable_shared_from_this<DownloadFunction> {
    public:
        DownloadFunction(const shared_ptr<DefaultResourceFetcher> &fetcher);

        void onSuccess(const string &input, const string &output) override;

        void onError(const string &input, const int errorCode, const string &errorMsg) override;

    protected:
        virtual void run(std::pair<string, string>& sourceInfo) override;

    private:
        const shared_ptr<DefaultResourceFetcher> &fetcher;
    };
}


#endif //CUTSAMEAPP_DOWNLOADFUNCTION_H
