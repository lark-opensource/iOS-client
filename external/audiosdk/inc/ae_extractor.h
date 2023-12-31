//
// Created by huanghao.blur on 2020/1/10.
//

#pragma once
#ifndef AUDIO_EFFECT_AE_EXTRACTOR_H
#define AUDIO_EFFECT_AE_EXTRACTOR_H

#include <string>
#include <unordered_map>
#include <vector>
#include "ae_bus.h"
#include "ae_extractor_def.h"
#include "ae_parameter.h"

namespace mammon {

    class Extractor {
    public:
        // Interfaces use in common as Effect
        // 和Effect类共用的接口部分
        virtual int process(std::vector<Bus>& bus_array) = 0;

        virtual void reset() = 0;

        /**
         * @brief 获取Extractor的名字
         *
         * @return const char*
         */
        virtual const char* getName() const {
            return "";
        };

        /**
         * @brief Update a value for single parameter
         * 设置单个参数的值
         * @param name 参数名
         * @param value 参数值
         */
        virtual void setParameter(const std::string& name, float value){};

        /**
         * Set parameter using string
         */
        virtual void setParameter(const std::string& name, const std::string& val_str){};

        /**
         * @brief Get the value of a parameter
         * 获取参数值，返回string形式
         * @param name parameter name
         * @return the stringfied value
         */
        virtual std::string getParameter(const std::string& name) const {
            return "";
        }

        /**
         * @brief Get
         * @return all parameters using key-value map
         */
        virtual std::unordered_map<std::string, std::string> getAllParameters() const {
            return {};
        }

        /**
         * @brief Get description of parameters
         * 获取参数描述
         * @return vector of ParameterDescriptor
         */
        virtual std::vector<ParameterDescriptor> getParameterDescriptors() const {
            return {};
        }

        /**
         * @brief Get the required block size for this algorithm
         * 获得这个效果需要的block size
         * 某些效果对block size有要求，不能随系统变化，这个函数获得算法要求的值
         * @return size_t
         */
        virtual size_t getRequiredBlockSize() const {
            return 0;
        }

        /**
         * @brief Set a new sample rate for this extractor
         * 设置新的工作采样率
         * @param sr 新采样率值
         */
        virtual void setSampleRate(size_t sr) {
        }
        /**
         * @brief Get current sample rate
         * 获得当前的采样率
         * @return size_t
         */
        virtual size_t getSampleRate() const {
            return 0;
        }

        /**
         * @brief Get features extracted from current frame
         * 获取当前帧的特征
         */
        virtual FeatureSet getFrameFeatures() = 0;
        /**
         * @brief Get features which need read all data to extract
         * 获取需要全部读取后才能计算的特征
         */
        virtual FeatureSet getOverallFeatures() = 0;
        /**
         * @brief Get descriptions for
         */
        virtual std::vector<FeatureDescriptor> getFeatureDescriptor() = 0;

        virtual ExtractorType getType() const = 0;

        /**
         * @brief returns model version
         *
         * @return the string of model version
         */
        virtual std::string getModelVersion() const {
            return "";
        }

        /**
         * @brief load model and share the same memory of model
         * @param buf the pointer of model memory
         */
        virtual int loadModel(std::shared_ptr<uint8_t>& buf, size_t size) {
            return 0;
        }

        /**
         * @brief load model and make a copy memory of model
         * @param buf the pointer of model memory
         * @param size the size of model memory
         */
        virtual int loadModel(const uint8_t* buf, size_t size) {
            return 0;
        }

        Extractor();

        virtual ~Extractor();

        virtual std::string getModelName() const {
            return "";
        }

        virtual std::string getModelString() const {
            return getModelName() + "_" + getModelVersion() + ".model";
        }
    };

}  // namespace mammon

#endif  // AUDIO_EFFECT_AE_EXTRACTOR_H
