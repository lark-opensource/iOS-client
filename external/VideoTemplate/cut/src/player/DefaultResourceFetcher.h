//
// Created by zhangyeqi on 2019-12-19.
//

#ifndef CUT_ANDROID_DEFAULTRESOURCEFETCHER_H
#define CUT_ANDROID_DEFAULTRESOURCEFETCHER_H

#include <TemplateConsumer/model.hpp>
#include "ResourceFetcher.h"
#include "ResourceVideoCoder.h"
#include <string>
#include <memory>
#include "cdom/ModelType.h"

namespace cut {
class FetchCallback {
public:
    FetchCallback(const string& input,
                  std::shared_ptr<ResourceFetcherCallback> realCallback);

    virtual void onError(const int errorCode, const string &errorMsg);

protected:
    const string input;
    std::shared_ptr<ResourceFetcherCallback> realCallback;
};

class FetchVideoCallback : public FetchCallback {
public:
    FetchVideoCallback(const string &input,
                       const std::shared_ptr<ResourceFetcherCallback> realCallback);

    void onSuccess(const std::vector<std::shared_ptr<CutSame::VideoSegment>> &segments);
};

class FetchNormalCallback : public FetchCallback {
public:
    FetchNormalCallback(const string &input,
                        std::shared_ptr<ResourceFetcherCallback> realCallback);

    void onSuccess(const string &filePath);
};

struct FetchError {
    FetchError(const int errorCode, const std::string& errorMsg):mErrorCode(errorCode),mErrorMsg(errorMsg) {}
    const int mErrorCode;
    const std::string mErrorMsg;
};

class FetchEffectRequest {
typedef std::function<void(const std::string &filepath, const std::shared_ptr<FetchError> &error)> Callback;
public:
    FetchEffectRequest(const std::string &resourceId, const std::string &resourceType, const cdom::EffectSourcePlatformType effectSourcePlatformType, cdom::MaterialType materialType):
        mResourceId(resourceId),
        mResourceType(resourceType),
        mEffectSourcePlatformType(effectSourcePlatformType),
        mMaterialType(materialType) {}
    
    FetchEffectRequest(const std::string &resourceId, const std::string &resourceType, cdom::MaterialType materialType):
        mResourceId(resourceId),
        mResourceType(resourceType),
        mEffectSourcePlatformType(cdom::EffectSourcePlatformTypeLoki),
        mMaterialType(materialType) {}
    
    friend class ResourceEffectCoder;
    
    void addRspCallback(Callback func) {
        mCallbacks.push_back(func);
    }
    
    void response(std::shared_ptr<FetchError>& error) {
        for (auto& f : mCallbacks) {
            f("", error);
        }
    }
    
    void response(const std::string &filepath) {
        for (auto& f : mCallbacks) {
            f(filepath, nullptr);
        }
    }
    
    const std::string& getResourceId() const {
        return mResourceId;
    }
    
    const std::string& getResourceType() const {
        return mResourceType;
    }
    
    const cdom::EffectSourcePlatformType& getEffectSourcePlatformType() const {
        return mEffectSourcePlatformType;
    }
    
    const cdom::MaterialType getMaterialType() const {
        return mMaterialType;
    }
    
private:
    const std::string mResourceId;
    const std::string mResourceType;
    const cdom::EffectSourcePlatformType mEffectSourcePlatformType;
    const cdom::MaterialType mMaterialType;
    std::vector<Callback> mCallbacks;//一个请求可能对应多个回调（重复资源）
};

class FetchEffectCallback {
public:
    virtual ~FetchEffectCallback() = default;

    virtual void onError(FetchEffectRequest *req, const FetchError &error) = 0;
    
    virtual void onSucces(const std::vector<std::shared_ptr<FetchEffectRequest>> &reqs) = 0;
};

class DefaultResourceFetcher : public ResourceFetcher {

public:
    void
    fetch(const string &input, const std::shared_ptr<ResourceFetcherCallback> &callback) override;
    virtual void fetchEffect(const std::vector<std::shared_ptr<FetchEffectRequest>> &reqs, std::shared_ptr<FetchEffectCallback> callback) = 0;
    
    virtual bool shouldCopyToWorkspace() override { return false; }; //默认不拷贝

protected:
    virtual ~DefaultResourceFetcher() {}
    virtual void onFetchVideo(const std::vector<std::shared_ptr<CutSame::VideoSegment>> &segments, std::shared_ptr<FetchVideoCallback> callback) {};

    virtual void onFetchNormalFile(const string &url, std::shared_ptr<FetchNormalCallback> callback) = 0;
};
}

#endif //CUT_ANDROID_DEFAULTRESOURCEFETCHER_H
