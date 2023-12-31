// NOTE: This file has been copied from mammon_engine as a short term
//       fix for resource io while we wait for the shared fileio library
//       to be developed. PNC 20200520
//
// Created by huanghao.blur on 2020/3/16.
//
#pragma once

#include "me_resource_finder.h"
#include "mammon_path.h"

namespace mammon {
    class ZipReader;

    class FileResourceFinder : public mammon::IResourceFinder {
    public:
        class FileStream;

        FileResourceFinder();

        ~FileResourceFinder() = default;

        void reset();

        void addSearchPath(std::string path) override;

        void addSearchMemory(void* data, uint32_t size) override;

        virtual const std::vector<std::string> &getSearchPathList() const override;

        virtual std::unique_ptr<IResourceStream> open(const std::string & uri) override;

        std::unique_ptr<mammon::FileSource> openAudioStream(const std::string& uri) override;

        std::string find(const std::string& uri) const override;

        bool existInPath(const std::string & uri) const ;

        bool existInMemory(const std::string & uri) const ;

        bool exist(const std::string & uri) const ;

        std::string getLocalPathFromURI(const std::string &uri) const;

        static FileResourceFinder& getInstance();
    private:
        std::vector<std::string> search_paths_;
        std::vector<std::shared_ptr<ZipReader>> zip_readers_;
    };

}  // namespace mammon
