//
// Created by zhangyeqi on 2019-12-02.
//

#ifndef CUTSAMEAPP_DECODEFUNCTION_H
#define CUTSAMEAPP_DECODEFUNCTION_H

#include <string>
#include <TemplateConsumer/TemplateModel.h>
#include "../stream/StreamFunction.h"
#include "../player/ResourceFetcher.h"

namespace cut {
    /**
     * 功能：输入Json文件路径，输出Project对象
     */
class DecodeFunction : public asve::StreamFunction<std::pair<string, string>, shared_ptr<CutSame::TemplateModel>> {
    public:
        DecodeFunction(const shared_ptr<ResourceFetcher> &fetcher, bool isNeedDispatchMediaPath)
        :mFetcher(fetcher), isNeedDispatchMediaPath(isNeedDispatchMediaPath) {};
        void run(std::pair<string, string>& sourceInfo) override;
        void adjustMediaPath(std::shared_ptr<CutSame::TemplateModel> &project);
        private:
        shared_ptr<ResourceFetcher> mFetcher;

    bool isNeedDispatchMediaPath = true;
};
}


#endif //CUTSAMEAPP_DECODEFUNCTION_H
