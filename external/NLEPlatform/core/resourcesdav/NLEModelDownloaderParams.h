//
// Created by Bytedance on 2021/7/13.
//

#ifndef SMARTMOVIEDEMO_NLEMODELDOWNLOADERPARAMS_H
#define SMARTMOVIEDEMO_NLEMODELDOWNLOADERPARAMS_H

#include <string>

namespace TemplateConsumer {

    class NLEModelDownloaderParams {

    public:

        explicit NLEModelDownloaderParams(const std::string &appID,
                                 const std::string &appVersion,
                                 const std::string &effectSdkVersion,
                                 const std::string &accessKey,
                                 const std::string &platform,
                                 const std::string &host,
                                 const std::string &effectCacheDir,
                                 const std::string &modelCacheDir,
                                 const std::string &deviceId,
                                 const std::string &deviceType,
                                 const bool &autoUnzip = true);
        
        explicit NLEModelDownloaderParams(const std::string &appID,
                                 const std::string &appVersion,
                                 const std::string &effectSdkVersion,
                                 const std::string &accessKey,
                                 const std::string &platform,
                                 const std::string &deviceId,
                                 const std::string &deviceType,
                                 const std::string &region,
                                 const std::string &appLanguage,
                                 const std::string &effectCacheDir,
                                 const std::string &effectHost,
                                 const std::string &modelCacheDir,
                                 const std::string &artistCacheDir,
                                 const std::string &imuseCacheDir,
                                 const std::string &imuseHost,
                                 const std::string &resolution = "",
                                 const bool &autoUnzip = true);

        std::string getAppID() const;

        std::string getAccessKey() const;

        std::string getPlatform() const;

        std::string getRegion() const;

        std::string getAppLanguage() const;

        std::string getHost() const;

        std::string getDeviceID() const;

        std::string getEffectCacheDir() const;

        std::string getModelCacheDir() const;

        std::string getDeviceType() const;

        std::string getAppVersion() const;

        std::string getEffectSdkVersion() const;
        
        std::string getArtistCacheDir() const;
        
        std::string getIMuseCacheDir() const;
        
        std::string getResolution() const;
        
        bool getAutoUnzip() const;
        
        std::string getIMuseHost() const;

    private:
        const std::string deviceType;
        const std::string appVersion;
        const std::string effectSdkVersion;
        const std::string appID;
        const std::string accessKey;
        const std::string platform;
        const std::string region;
        const std::string appLanguage;
        const std::string host;
        const std::string effectCacheDir;
        const std::string modelCacheDir;
        const std::string deviceId;
        const std::string artistCacheDir;
        const std::string imuseCacheDir;
        const std::string resolution;
        const std::string imuseHost;
        const bool autoUnzip;
    };
}

#endif //SMARTMOVIEDEMO_NLEMODELDOWNLOADERPARAMS_H
