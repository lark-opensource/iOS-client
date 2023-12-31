//
// Created by wangchengyi.1 on 2021/4/27.
//

#include "DAVResourceIdParser.h"
#include "UrlResourceHandler.h"
#include "UrlResourceProtocol.h"
#include "DAVDownloader.h"
#include "DavinciLogger.h"
#include "DAVPublicUtil.h"

using namespace davinci::resource;

UrlResourceHandler::UrlResourceHandler() {
    downloader = std::make_shared<davinci::downloader::DAVDownloader>();
}

davinci::resource::DAVResourceTaskHandle
davinci::resource::UrlResourceHandler::fetchResource(const std::shared_ptr<DAVResource> &davinciResource,
                                                     const std::unordered_map<std::string, std::string> &extraParams,
                                                     const std::shared_ptr<DAVResourceFetchCallback> &callback) {

    auto parser = davinci::resource::DAVResourceIdParser(davinciResource->getResourceId());
    if (parser.queryParams.find(UrlResourceProtocol::KEY_URL()) == parser.queryParams.end()) {
        LOGGER->e("please set http_url!");
        callback->onError(-1);
        return 0;
    }
    if (extraParams.find(UrlResourceProtocol::EXTRA_PARAM_SAVE_PATH()) == extraParams.end()) {
        LOGGER->e("please set save path first!");
        callback->onError(-1);
        return 0;
    }
    auto httpUrl = parser.queryParams[UrlResourceProtocol::KEY_URL()];
    auto decodedHttpUrl = davinci::resource::DAVPublicUtil::urlDecode(httpUrl);

    const auto& destPath = extraParams.at(UrlResourceProtocol::EXTRA_PARAM_SAVE_PATH());
    bool unZipAfterDownloaded = false;
    if (extraParams.find(UrlResourceProtocol::EXTRA_PARAM_AUTO_UNZIP()) != extraParams.end()) {
        unZipAfterDownloaded = extraParams.at(UrlResourceProtocol::EXTRA_PARAM_AUTO_UNZIP()) == "true";
    }
    std::string md5String;
    if (extraParams.find(UrlResourceProtocol::EXTRA_PARAM_MD5()) != extraParams.end()) {
        md5String = extraParams.at(UrlResourceProtocol::EXTRA_PARAM_MD5());
    }
    downloader->DownloadFile(decodedHttpUrl,
                             destPath, md5String, unZipAfterDownloaded,
                             [davinciResource, callback](const std::string &filePath) {
                LOGGER->i("download file: %s success!", filePath.c_str());
                auto successResource = std::make_shared<DAVResource>(davinciResource->getResourceId());
                successResource->setResourceFile(filePath);
                callback->onSuccess(successResource);
            }, [callback](float progress) {
                LOGGER->i("download file progress: %lf ", progress);
                callback->onProgress((long) (progress * 100));
            }, [callback](davinci::downloader::DownloadErrorCode errorCode, const std::string &errorMsg) {
                LOGGER->i("download file failed, errorCode: %d, msg: %s ", errorCode, errorMsg.c_str());
                callback->onError(static_cast<DRResult>(errorCode));
            });
    return 0;
}

std::shared_ptr<davinci::resource::DAVResource>
davinci::resource::UrlResourceHandler::fetchResourceFromCache(const davinci::resource::DavinciResourceId &davinciResourceId,
                                                              const std::unordered_map<std::string, std::string> &extraParams) {
    return std::make_shared<DAVResource>(davinciResourceId);
}

bool davinci::resource::UrlResourceHandler::canHandle(const std::shared_ptr<DAVResource> &davinciResource) {
    return UrlResourceProtocol::isUrlResource(davinciResource->getResourceId());
}

std::shared_ptr<UrlResourceHandler> UrlResourceHandler::create() {
    return std::make_shared<UrlResourceHandler>();
}


