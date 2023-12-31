#ifdef __cplusplus
#ifndef _BACH_RESOURCE_FINDER_H_
#define _BACH_RESOURCE_FINDER_H_

#include <stdlib.h>
#include <string>
#include <memory>
#include <functional>
#include "Bach/Base/BachAlgorithmConstant.h"

NAMESPACE_BACH_BEGIN

struct BACH_EXPORT BachAlgorithmModel
{
    std::string name;
    int64_t modelType = 0;
    int64_t config = 0;          // High 32-bit reserved for mapping flag: Do not assign negative value or values that greater than 2^32
    const char* pData = nullptr; // 输出数据的指针，使用方会负责释放
    int64_t length = 0;          // 输出数据的大小
    std::string path;
    void* modelParams = nullptr;
    bool absolutePath = false;
    int32_t isPacked = true;
};

struct BACH_EXPORT BachAlgorithmModelEvent
{
    BachAlgorithmModel modelInfo;
    AlgorithmType algType;
    size_t algID = 0;
    int errorCode = 0;
    double timeCost = 0;
};

class BACH_EXPORT BachResourceFinder
{
public:
    virtual ~BachResourceFinder() {}

    /**
     * find model resource by name
     */
    virtual bool findResource(BachAlgorithmModel& model) = 0;

    /**
     * release model data
     * @param model
     * @return
     */
    virtual bool releaseResource(BachAlgorithmModel& model)
    {
        delete[] model.pData;
        model.pData = nullptr;
        model.length = 0;
        return true;
    }

    /**
     * useful for some algorithms support ocl/coreml model, optional
     * @return a path that can write by bach
     */
    virtual std::string getCacheDir() const
    {
        return "";
    }

    /**
     * report model load event, optional
     */
    virtual bool reportEvent(const BachAlgorithmModelEvent& event)
    {
        return false;
    }
};

enum class BachDownloadStatus
{
    DOWNLOAD_SUCCESS = 0,
    DOWNLOAD_FAILED = 1
};
typedef std::function<void(BachDownloadStatus, int32_t, void*)> bach_download_cb;

class BACH_EXPORT BachDownloadableResourceFinder : public BachResourceFinder
{
public:
    /**
         * config to initialize BachDownloadableResourceFinder
         * @param modelCacheDir cache folder to storage algorithm model
         * @param builtInModelDir builtIn models folder
         * @param region it can set to 'US-e' or not to set, optional
         * @param appID which app use this BachDownloadableResourceFinder, optional
         * @param appVersion app version, optional
         * @param useOnlineEnv test: "0";default:online: "1", optional
         * @param modelTag model tag  of test env(yong dao), optional
         */
    struct Config
    {
        std::string modelCacheDir = "";
        std::string builtInModelDir = "";
        std::string region;
        std::string appID = "";
        std::string appVersion = "";
        std::string busId = "100";
        std::string useOnlineEnv = "1";
        std::string modelTag = "";
        bool sync = false;
        void* assetMgr = nullptr; // android platform asset manager handle, optional
    };

    /**
     * download algorithm models from online
     * @param modelNames algorithm models to download
     */
    virtual void downloadModels(const std::vector<std::string>& modelNames, bach_download_cb cb = nullptr, int32_t length = 0, void* params = nullptr) = 0;
    virtual std::vector<std::string> getFindModels() = 0;
    virtual void clearHistory() = 0;
};

// same definition with bef_resource_finder in EffectSDK bef_framework_public_base_define.h
typedef void* bach_handle;
typedef char* (*bach_resource_finder)(bach_handle, const char*, const char*);
class BACH_EXPORT BachResourceFinderFactory
{
public:
    /**
     * create a local file resource finder can find algorithm models in modelDir folder
     * @param modelDir the folder that store algorithm models
     * @return a local resource finder instance
     */
    static BachResourceFinder* CreateFileResourceFinder(const std::string& modelDir);

    /**
     * create a resource finder with function pointer such as EP handle
     * @param handle a user handle that will callback to bach_resource_finder
     * @param resource_finder C function impl to find resource path
     * @param cacheDir a writeable folder to store ocl/coreml model, optional for some algorithms
     * @param assetMgr reserved only useful for android platform access model in app assets
     * @return a resource finder that use EP function to find algorithm models
     */
    static BachResourceFinder* CreateResourceFinder(bach_handle* handle, bach_resource_finder resource_finder, const std::string& cacheDir = "", void* assetMgr = nullptr);

    /**
     * create a resource finder that support download models from online
     * @param config resource finder init config
     * @return  a resource finder that support auto download missing models
     */
    static BachDownloadableResourceFinder* CreateDownloadableResourceFinder(const BachDownloadableResourceFinder::Config& config);

    /**
     * release resource finder instance
     * @param finder resource finder instance
     */
    static void DestroyResourceFinder(BachResourceFinder* finder);
};

NAMESPACE_BACH_END
#endif

#endif