//
// Created by wangchengyi.1 on 2021/4/27.
//

#ifndef DAVINCIRESOURCEDEMO_DAVDOWNLOADER_H
#define DAVINCIRESOURCEDEMO_DAVDOWNLOADER_H

#include <string>
#include <memory>
#include <functional>
#include <map>
#include <mutex>
#include <vector>

namespace davinci {
    namespace network {
        class DAVHttpClient;
    }
}

namespace davinci {
    namespace downloader {

        enum class DownloadErrorCode : int32_t {
            PARAM_INVALID = -1,
            FILE_OPEN_FAILED = -2,
            NETWORK_ERROR = -3,
            MD5_ERROR = -4,
            RENAME_FILE_ERROR = -5
        };

        using FileDownloadSuccessCallback = std::function<void(const std::string &filePath)>;
        using FileDownloadProgressCallback = std::function<void(float progress)>;
        using FileDownloadFailCallback = std::function<void(DownloadErrorCode errorCode, const std::string &errorMsg)>;

        class DAVDownloader : public std::enable_shared_from_this<DAVDownloader> {

        public:
            DAVDownloader();

            unsigned long long DownloadFile(const std::string &url, const std::string &destFilePath,
                                            const std::string &destFileMd5 = "",
                                            const bool unZipAfterDownloaded = false,
                                            const FileDownloadSuccessCallback &successCallback = nullptr,
                                            const FileDownloadProgressCallback &progressCallback = nullptr,
                                            const FileDownloadFailCallback &failCallback = nullptr);

        private:
            std::recursive_mutex mutex;
            std::recursive_mutex callbackMutex;
            std::shared_ptr<davinci::network::DAVHttpClient> netWorkClient;
            std::vector<std::string> downloadingFiles;
            std::map<std::string, std::vector<FileDownloadSuccessCallback>> successCallbackMap;
            std::map<std::string, std::vector<FileDownloadProgressCallback>> progressCallbackMap;
            std::map<std::string, std::vector<FileDownloadFailCallback>> failCallbackMap;

            void internalOnFail(const std::string &destFilePath, DownloadErrorCode errorCode, const std::string &errorMsg);

            void internalOnSuccess(const std::string &destFilePath, const std::string &filePath);

            void internalOnProgress(const std::string &destFilePath, float progress);

            void internalFinish(const std::string &destFilePath);
        };
    }
}


#endif //DAVINCIRESOURCEDEMO_DAVDOWNLOADER_H
