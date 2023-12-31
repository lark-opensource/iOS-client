//
// Created by zhangyeqi on 2019-12-17.
//

#ifndef CUT_ANDROID_RESOURCEFETCHER_H
#define CUT_ANDROID_RESOURCEFETCHER_H

#include <memory>
#include <string>
#include <string>
#include <map>
#include "TemplateException.h"

namespace cut {
#define SCHEMA_DELIMITER string("://")
#define SCHEMA_VIDEO string("video")
#define SCHEMA_EFFECT string("effect")
#define SCHEMA_NORMAL string("normal")

    class ResourceFetcherCallback {
    public:
        virtual void onSuccess(const string &input, const string &output) = 0;

        virtual void onError(const string &input, const int errorCode, const string &errorMsg) = 0;
    };

    class ResourceFetcher {
    public:
        virtual ~ResourceFetcher() {};
        virtual void fetch(const string &input, const std::shared_ptr<ResourceFetcherCallback> &callback) = 0;
        
        virtual void onCanceled() {};
        
        //TODO：Migration先放这里，后面再整理（lixingpeng）
        virtual std::string upgradeData(const string &input) = 0;
        
        // 若为true，则会在资源下载后拷贝到工作区
        virtual bool shouldCopyToWorkspace() = 0;
    };



    template<typename PACK, typename FRAME>
    class ResourceIOCoder {
    public:
        virtual FRAME decode(const PACK& pack) = 0;

        virtual PACK encode(const FRAME& frame) = 0;
    };
}


#endif //CUT_ANDROID_RESOURCEFETCHER_H
