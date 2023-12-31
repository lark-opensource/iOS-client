#pragma once

#include <map>
#include <vector>
#include "ae_bus.h"
#include "ae_defs.h"
#include "ae_loadmodel.h"
#include "ae_parameter.h"

namespace mammon {
    class IResourceFinder;

    enum AudioEffectType { kBasicEffect = 0, kCascadeEffect, kParallelEffect };

    /**
     * @brief 所有音频效果的抽象基类
     *
     */
    class MAMMON_EXPORT Effect {
    public:
        Effect();
        virtual ~Effect() = default;
        /**
         * @brief 获取效果器的名字
         *
         * @return const char*
         */
        virtual const char* getName() const = 0;

        /**
         * @brief 获取这个效果器所有的参数列表
         *
         * @return const std::vector<Parameter*>&
         */
        const std::vector<Parameter*>& getParametersSet() const {
            return parameters_;
        };

        /**
         * @brief 获取单个参数的值
         * 获取不存在的值要抛异常
         * @param name 参数名称
         * @return const Parameter&
         */
        const Parameter& getParameter(const std::string& name) const;
        /**
         * @brief 设置单个参数的值
         *
         * @param name 参数名
         * @param value 参数值
         */
        virtual void setParameter(const std::string& name, float value);
        /**
         * @brief 设置一组参数值
         *
         * @param parameters 参数组
         */
        virtual void setParameters(const std::map<std::string, float>& parameters);

        /**
         * @brief 设置效果器的内部状态
         * 这个函数仅在需要恢复目前的工作状态的时候使用
         * 这个函数不负责恢复参数
         * @param bytes 内部状态将采用该序列化二进制数据重置
         * @return bool
         */
        virtual bool setState(std::vector<uint8_t>& bytes) {
            return true;
        }
        /**
         * @brief 获取效果器的内部状态
         * 这个函数仅在需要恢复目前的工作状态的时候使用
         * 这个函数不负责恢复参数
         * @param bytes 内部状态的序列化二进制数据将保存到这里输出
         * @return bool
         */
        virtual bool getState(std::vector<uint8_t>& bytes) {
            return true;
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
         * @brief 获得这个效果需要的block size
         * 某些效果对block size有要求，不能随系统变化，这个函数获得算法要求的值
         * @return size_t
         */
        virtual size_t getRequiredBlockSize() const {
            return 0;
        }

        /**
         * @brief 重置效果器状态
         * 一般需要重新播放时调用这个函数清除一下历史状态
         */
        virtual void reset() = 0;

        /**
         * @brief 处理数据
         * 效果器处理数据的入口，目前的状态是in-place的，会在原来的bus里写入结果
         * @param bus_array 输入数据
         * @return int 正常返回值是0，出错时返回值小于0，具体含义参考那个效果器的定义
         */
        virtual int process(std::vector<Bus>& bus_array) = 0;

        /**
         * @brief 是否需要先整体处理一次数据
         * 这个值表示是否某些效果需要未来的数据从头到尾先处理一次
         * 这表示这个算法不能做到硬实时处理
         * @return true
         * @return false
         */
        virtual bool needsPreprocess() {
            return false;
        }

        /**
         * @brief Set the Preprocessing object
         *
         */
        virtual void setPreprocessing(bool b) {
        }

        /**
         * @brief Set the ResRoot object
         *
         */
        virtual void setResRoot(std::string path) {
            resRoot_ = path;
        }
        /**
         * @brief Get the ResRoot object
         *
         */
        virtual const std::string getResRoot() const {
            return resRoot_;
        };

        /**
         * @brief Set seek position
         *
         */
        virtual bool seek(double newPosInSec, int mode = SEEK_SET) {
            return false;
        };
        virtual bool seek(int64_t newPosInSamples, int mode = SEEK_SET) {
            return false;
        };
        virtual void seekDefinitely(int64_t newPosInSamples){};

        /* @brief 获取输入Bus的名字
         *
         * @param index Bus的索引
         * @return const char*
         */
        virtual const char* getInputBusName(size_t index) const;

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

        virtual void setSampleRate(size_t) {
        }

        virtual size_t getSampleRate() const {
            return 1;
        }

        /**
         * @brief 获取算法需要的模型版本，无模型不用overide
         *
         * @return const std::string
         */
        virtual std::string getModelVersion() const {
            return "";
        }

        /**
         * @brief 加载模型，直接使用外部的存储空间
         */
        virtual void loadModel(std::shared_ptr<uint8_t>& buf, size_t) {
        }

        /**
         * @brief 加载模型，需要copy操作，内部管理存储空间
         */
        virtual void loadModel(const uint8_t* buf, size_t size) {
        }

        virtual void setResourceFinder(std::shared_ptr<IResourceFinder> finder);

        virtual std::shared_ptr<IResourceFinder> getResourceFinder();

    protected:
        bool need_preprocessing_;  // 暂时留着防止ABI变化
        std::vector<Parameter*> parameters_;
        std::string resRoot_;
        class Impl;
        std::shared_ptr<Impl> pimpl;
        Parameter parameter_{"invalid_parameter", 0.0f, 0.0f, 0.0f};
    };

}  // namespace mammon

#include "cae_effect.h"

struct CAEEffectImpl {
    std::shared_ptr<mammon::Effect> instance;
};
