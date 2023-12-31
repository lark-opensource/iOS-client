// NOTE: This file has been copied from mammon_engine as a short term
//       fix for resource io while we wait for the shared fileio library
//       to be developed. PNC 20200520
//
// Created by huanghao.blur on 2020/3/16.
//

#pragma once

#include <vector>
#include <string>
#include <memory>
#include "me_file_source.h"

/*
 * 统一使用URI做资源编码：
 * [system]://path
 * 目前Effect那边有file://和asset://
 * 模型加载是没有前缀的，使用不同的系统进行读取，我们约定用model:// 外面做适配
 */

// URI PREFIX:
#define MAMMON_RESOURCE_FILE_URI_PREFIX "file://"
#define MAMMON_RESOURCE_ASSET_URI_PREFIX "asset://"
#define MAMMON_RESOURCE_MODEL_URI_PREFIX "model://"


namespace mammon {

    class IResourceFinder {
    public:
        /**
         * Add a search path for this finder
         * 添加搜索路径
         * @param searchPath Candidate searching path for finder
         */
        virtual void addSearchPath(std::string searchPath) = 0;

        /**
         * Add a search memory for this finder
         * 添加搜索路径
         * @param searchPath Candidate searching path for finder
         */
        virtual void addSearchMemory(void *addr, uint32_t size) = 0;

        /**
         * Get the list of searching paths of this finder
         * @return List of candidate searching path
         */
        virtual const std::vector<std::string> &getSearchPathList() const = 0;

        /**
         * Open data stream for given uri
         * The URI encoding is referenced on the beginning of this file
         * 从URI打开资源，URI编码参考文件开始的注释
         * @param uri The URI of resource
         * @return nullptr will be returned when URI cannot be open or found
         * 找不到uri或者打不开资源的时候返回nullptr
         */
        virtual std::unique_ptr<IResourceStream> open(const std::string &uri) = 0;

        /**
         * @brief Open an audio stream
         * Will get a interleaved PCM stream
         * 打开音频流，拿到交错的采样
         * @param std::string Audio file URI
         * @return std::unique_ptr<FileSource>
         */
        virtual std::unique_ptr<mammon::FileSource> openAudioStream(const std::string &uri) = 0;


        /**
         * @brief Find the uri and return full path
         *
         * @param uri
         * @return std::string
         */
        virtual std::string find(const std::string &uri) const = 0;

        virtual ~IResourceFinder() = default;
    };

}  // namespace mammon
