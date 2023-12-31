
#pragma once
#ifndef AUDIO_EFFECT_AE_NO_EFFECT_H
#define AUDIO_EFFECT_AE_NO_EFFECT_H

#include <stdexcept>
#include "ae_bus.h"
#include "ae_defs.h"
#include "ae_parameter.h"

namespace mammon {

    /**
     * @brief No Effect class for processors
     */
    class MAMMON_EXPORT NoEffect {
    public:
        virtual ~NoEffect() = default;

        /**
         * @brief Get the name of current effect
         *
         * @return const char*
         */
        virtual const char* getName() const = 0;

        /**
         * @brief Actually process input data
         * @param bus_array Input data blocks
         * @return int If success returns 0 otherwise non zero values
         */
        virtual int process(std::vector<Bus>& input_bus, std::vector<Bus>& output_bus) = 0;

        /**
         * @brief Reset processing state to the initial state
         */
        virtual void reset() = 0;

        /**
         * @brief Update a value for single parameter
         * @param name Parameter name
         * @param value Parameter value
         */
        virtual void setParameter(const std::string& name, float value) {
        };

        /**
         * Set parameter using string
         */
        virtual void setParameter(const std::string& name, const std::string& val_str) {
        };

        /**
         * @brief Get all Parameter object of this effect
         * @return const std::vector<Parameter*>&
         */
        virtual std::vector<Parameter*> getParametersSet() const {
            return {};
        };

        /**
         * @brief 获取单个参数的值
         * 获取不存在的值返回{name: "", value: 0.0f}
         * @param name 参数名称
         * @return const Parameter&
         */
        virtual const Parameter& getParameter(const std::string& name) const = 0;

        /**
         * @brief Get description of parameters
         * 获取参数描述
         * @return vector of ParameterDescriptor
         */
        virtual std::vector<ParameterDescriptor> getParameterDescriptors() const {
            return {};
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
         * @brief load model and share the same memory of model
         * @param buf the pointer of model memory
         */
        virtual int loadModel(std::shared_ptr<acore::byte>& buf, size_t size) {
            return 0;
        }

        /**
         * @brief load model and make a copy memory of model
         * @param buf the pointer of model memory
         * @param size the size of model memory
         */
        virtual int loadModel(const acore::byte* buf, size_t size) {
            return 0;
        }

        /**
         * @brief 设置效果器的内部状态
         * 这个函数仅在需要恢复目前的工作状态的时候使用
         * 这个函数不负责恢复参数
         * @param bytes 内部状态将采用该序列化二进制数据重置
         * @return bool
         */
        virtual bool setState(std::vector<acore::byte>& bytes) {
            return true;
        }
        /**
         * @brief 获取效果器的内部状态
         * 这个函数仅在需要恢复目前的工作状态的时候使用
         * 这个函数不负责恢复参数
         * @param bytes 内部状态的序列化二进制数据将保存到这里输出
         * @return bool
         */
        virtual std::vector<acore::byte> getState() {
            return {};
        }

        /**
         * @brief 获取效果器的延迟值
         * 获取效果器算法造成的延迟
         * @return size_t
         */
        virtual size_t getLatency() const {
            return 0;
        }

        /**
         * @brief 获取效果要求的输入Bus数量
         *
         * @return int
         */
        virtual int getInputBusesCount() const {
            return 1;
        }

        /**
         * @brief 获取效果将会提供的输出Bus的数量
         *
         * @return int
         */
        virtual int getOutputBusesCount() const {
            return 1;
        }
    };

}  // namespace mammon

#endif  // AUDIO_EFFECT_AE_NO_EFFECT_H