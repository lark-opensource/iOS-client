//
// Created by wangchengyi.1 on 2021/4/27.
//

#include <string_util.h>
#include <DAVFile.h>
#include "DAVDownloader.h"
#include "DAVHttpClient.h"
#include "file_platform.h"
#include "DavinciLogger.h"
#include "md5.h"
#include "DAVNetworkCreator.h"

davinci::downloader::DAVDownloader::DAVDownloader() = default;

unsigned long long
davinci::downloader::DAVDownloader::DownloadFile(const std::string &url, const std::string &destFilePath,
                                                 const std::string &destFileMd5,
                                                 const bool unZipAfterDownloaded,
                                                 const davinci::downloader::FileDownloadSuccessCallback &successCallback,
                                                 const davinci::downloader::FileDownloadProgressCallback &progressCallback,
                                                 const davinci::downloader::FileDownloadFailCallback &failCallback) {
    if (destFilePath.empty()) {
        failCallback(DownloadErrorCode::PARAM_INVALID, "dest path empty");
        return 0;
    }
    {
        std::unique_lock<std::recursive_mutex> callbackLock(callbackMutex);
        if (successCallback != nullptr) {
            successCallbackMap[destFilePath].emplace_back(successCallback);
        }
        if (progressCallback != nullptr) {
            progressCallbackMap[destFilePath].emplace_back(progressCallback);
        }
        if (failCallback != nullptr) {
            failCallbackMap[destFilePath].emplace_back(failCallback);
        }
    }

    std::unique_lock<std::recursive_mutex> lock(mutex);
    if (std::find(downloadingFiles.begin(), downloadingFiles.end(), destFilePath) != downloadingFiles.end()) {
        LOGGER->i("url %s is already downloading!", url.c_str());
        return 0;
    }
    if (this->netWorkClient == nullptr) {
        this->netWorkClient = davinci::network::DAVNetworkCreator::createDAVHttpClient();
    }
    downloadingFiles.emplace_back(destFilePath);
    auto tempFilePath = destFilePath + "_temp";
    FILE *file = fopen_platform(tempFilePath.c_str(), "wb");
    if (file == NULL) {
        remove(tempFilePath.c_str());
        internalOnFail(destFilePath, DownloadErrorCode::FILE_OPEN_FAILED, "open dest path failed!");
        return 0;
    }
    auto *cxt = (MD5_CTX *) malloc(sizeof(MD5_CTX));
    bool enableMd5Check = false;
    if (!destFileMd5.empty()) {
        md5_init(cxt);
        enableMd5Check = true;
    }
    auto self = this->shared_from_this();
    auto client = this->netWorkClient;
    return this->netWorkClient->RequestGet(url,
                                           [self, client, file, tempFilePath, destFilePath, enableMd5Check, destFileMd5, cxt, unZipAfterDownloaded](
                                                   void *pHttpClient,
                                                   davinci::network::HttpClientCallbackAction actionCode,
                                                   void *wParam,
                                                   int64_t lParam,
                                                   const davinci::network::MsgExtParam &stExtParam) {
                                               fwrite(wParam, lParam, 1, file);
                                               if (enableMd5Check) {
                                                   md5_update(cxt, wParam, (size_t) lParam);
                                               }
                                               auto lengthTotal = client->GetCurContentLength(stExtParam.uiReqId);
                                               if (lengthTotal != 0) {
                                                   float progress = ((float) lParam) / lengthTotal;
                                                   self->internalOnProgress(destFilePath, progress);
                                               }
                                               if (actionCode == davinci::network::HttpClientCallbackAction::SUCCESS) {
                                                   fflush(file);
                                                   fclose(file);
                                                   std::string filePath;
                                                   if (unZipAfterDownloaded) {
                                                       filePath = destFilePath + ".zip";
                                                   } else {
                                                       filePath = destFilePath;
                                                   }
                                                   if (enableMd5Check) {
                                                       unsigned char md5[16];
                                                       md5_final(cxt, md5);
                                                       free(cxt);
                                                       auto md5_string = cbox::to_hex_string(md5, 16);
                                                       if (md5_string == destFileMd5) {
                                                           if (rename(tempFilePath.c_str(), filePath.c_str()) != 0) {
                                                               LOGGER->e("rename failed, path: %s, dest path: %s",
                                                                         tempFilePath.c_str(), filePath.c_str());
                                                               remove(tempFilePath.c_str());
                                                               self->internalOnFail(destFilePath, DownloadErrorCode::RENAME_FILE_ERROR,
                                                                              "rename failed");
                                                               return;
                                                           }
                                                           if (unZipAfterDownloaded) {
                                                               if (davinci::file::DAVFile::unZipSafely(filePath.c_str(), destFilePath.c_str(), true)) {
                                                                   self->internalOnSuccess(destFilePath, destFilePath);
                                                               } else {
                                                                   self->internalOnFail(destFilePath, DownloadErrorCode::RENAME_FILE_ERROR,
                                                                                  "unzip failed");
                                                               }
                                                               return;
                                                           }
                                                           self->internalOnSuccess(destFilePath, destFilePath);
                                                       } else {
                                                           LOGGER->e("md5 not match, expected: %s, actual: %s",
                                                                     destFileMd5.c_str(), md5_string.c_str());
                                                           remove(tempFilePath.c_str());
                                                           self->internalOnFail(destFilePath, DownloadErrorCode::MD5_ERROR,
                                                                          "md5 does not match");
                                                       }
                                                   } else {
                                                       if (rename(tempFilePath.c_str(), filePath.c_str()) != 0) {
                                                           LOGGER->e("rename failed, path: %s, dest path: %s",
                                                                     tempFilePath.c_str(), filePath.c_str());
                                                           remove(tempFilePath.c_str());
                                                           self->internalOnFail(destFilePath, DownloadErrorCode::RENAME_FILE_ERROR,
                                                                          "rename failed");
                                                           return;
                                                       }
                                                       if (unZipAfterDownloaded) {
                                                           if (davinci::file::DAVFile::unZipSafely(filePath.c_str(), destFilePath.c_str(), true)) {
                                                               self->internalOnSuccess(destFilePath, destFilePath);
                                                           } else {
                                                               self->internalOnFail(destFilePath, DownloadErrorCode::RENAME_FILE_ERROR,
                                                                              "unzip failed");
                                                           }
                                                           return;
                                                       }
                                                       self->internalOnSuccess(destFilePath, destFilePath);
                                                   }

                                               } else if (actionCode ==
                                                          davinci::network::HttpClientCallbackAction::FAIL) {
                                                   fclose(file);
                                                   free(cxt);
                                                   remove(tempFilePath.c_str());
                                                   self->internalOnFail(destFilePath, DownloadErrorCode::NETWORK_ERROR,
                                                                  std::to_string(stExtParam.errorCode));
                                               }
                                           });
}

void davinci::downloader::DAVDownloader::internalOnFail(const std::string &destFilePath,
                                                        davinci::downloader::DownloadErrorCode errorCode,
                                                        const std::string &errorMsg) {
    std::vector<FileDownloadFailCallback> failCallBacks;
    {
        std::unique_lock<std::recursive_mutex> lock(callbackMutex);
        if (failCallbackMap.find(destFilePath) != failCallbackMap.end()) {
            failCallBacks = failCallbackMap.at(destFilePath);
        }
        internalFinish(destFilePath);
    }
    for (const auto &callback: failCallBacks) {
        callback(errorCode, errorMsg);
    }
}

void davinci::downloader::DAVDownloader::internalOnSuccess(const std::string &destFilePath, const std::string &filePath) {
    std::vector<FileDownloadSuccessCallback> successCallBacks;
    {
        std::unique_lock<std::recursive_mutex> lock(callbackMutex);
        if (successCallbackMap.find(destFilePath) != successCallbackMap.end()) {
            successCallBacks = successCallbackMap.at(destFilePath);
        }
        internalFinish(destFilePath);
    }
    for (const auto &callback: successCallBacks) {
        callback(filePath);
    }
}

void davinci::downloader::DAVDownloader::internalOnProgress(const std::string &destFilePath, float progress) {
    std::vector<FileDownloadProgressCallback> progressCallBacks;
    {
        std::unique_lock<std::recursive_mutex> lock(callbackMutex);
        if (progressCallbackMap.find(destFilePath) != progressCallbackMap.end()) {
            progressCallBacks = progressCallbackMap.at(destFilePath);
        }
    }
    for (const auto &callback: progressCallBacks) {
        callback(progress);
    }
}

void davinci::downloader::DAVDownloader::internalFinish(const std::string &destFilePath) {
    {
        std::unique_lock<std::recursive_mutex> lock(callbackMutex);
        auto foundFailCallback = failCallbackMap.find(destFilePath);
        if (foundFailCallback != failCallbackMap.end()) {
            failCallbackMap.erase(foundFailCallback);
        }
        auto foundSucessCallback = successCallbackMap.find(destFilePath);
        if (foundSucessCallback != successCallbackMap.end()) {
            successCallbackMap.erase(foundSucessCallback);
        }
        auto foundProgressCallback = progressCallbackMap.find(destFilePath);
        if (foundProgressCallback != progressCallbackMap.end()) {
            progressCallbackMap.erase(foundProgressCallback);
        }
    }
    std::unique_lock<std::recursive_mutex> dataLock(mutex);
    auto found = std::find(downloadingFiles.begin(), downloadingFiles.end(), destFilePath);
    if (found != downloadingFiles.end()) {
        downloadingFiles.erase(found);
    }
}
