#ifdef __cplusplus
#ifndef _BACH_ALGORITHM_SYSTEM_H_
#define _BACH_ALGORITHM_SYSTEM_H_

#include <unordered_map>

#include "Bach/Base/BachResourceFinder.h"
#include "Bach/Base/BachAlgorithmBuffer.h"
#include "BachAlgorithmInput.h"

NAMESPACE_BACH_BEGIN

class BACH_EXPORT BachInitConfig
{
public:
    BachResourceFinder* finder = nullptr; // 算法模型查找，继承实现
    std::string applicationName;          //业务场景值, 请和对接RD沟通确认，必须设置
    std::string deviceName;               //设备名称, 可以不设定,(slam算法需要)
};

class BACH_EXPORT BachAlgorithmConfigWithNodeName
{
public:
    std::unordered_map<std::string, int64_t> intParam;
    std::unordered_map<std::string, float> floatParam;
    std::unordered_map<std::string, std::string> stringParam;
};

class BACH_EXPORT BachAlgorithmSystem
{
public:
    virtual ~BachAlgorithmSystem() {}
    /**
     * 初始化配置
     * @param config 配置信息
     */
    virtual BachErrorCode init(const BachInitConfig& config) = 0;
    /**
     * 添加Graph配置信息，只支持添加一张graph配置
     *
     * @param config 图的配置json字符串，业务读取文件传入
     */
    virtual BachErrorCode initGraph(const std::string& config) = 0;

    /**
     * 移除指定的Graph，移除之后可以重新添加新的graph
     *
     */
    virtual BachErrorCode removeGraph() = 0;

    /**
     * 根据输入信息，执行算法
     *
     * @param in 输入数据
     */
    virtual BachErrorCode execute(const BachAlgorithmInput& in) = 0;

    /**
     * 算法执行结束, 获取指定算法类型的结果，业务static_cast成具体的子类
     * @param type 算法类型
     * @return  算法结果BachBuffer
     */
    virtual BachBuffer* getResult(const AlgorithmType& type) = 0;

    /**
     * 开启/关闭指定算法节点
     *
     * @param type 算法类型
     * @param enable 开启/关闭
     */
    virtual BachErrorCode enable(const AlgorithmType& type, bool enable) = 0;

    /**
     * 开启/关闭某个算法节点
     *
     * @param nodeName  节点的名称
     * @param enable  开启/关闭
     */
    virtual BachErrorCode enable(const std::string& nodeName, bool enable) = 0;

    /**
     * 给指定算法类型的节点更新int类型参数
     *
     * @param type  算法类型
     * @param params  int参数集合
     */
    virtual BachErrorCode setParams(const AlgorithmType& type, const std::unordered_map<std::string, int64_t>& params) = 0;

    /**
     * 给指定算法类型的节点更新float类型参数
     *
     * @param type   算法类型
     * @param params float参数集合
     */
    virtual BachErrorCode setParams(const AlgorithmType& type, const std::unordered_map<std::string, float>& params) = 0;

    /**
     * 给指定算法类型的节点更新string类型参数
     *
     * @param type
     * @param params string参数集合
     */
    virtual BachErrorCode setParams(const AlgorithmType& type, const std::unordered_map<std::string, std::string>& params) = 0;

    /**
     * 给算法节点设置int类型参数
     *
     * @param nodeName  节点的名称
     * @param params    int参数集合
     */
    virtual BachErrorCode setParams(const std::string& nodeName, const std::unordered_map<std::string, int64_t>& params) = 0;

    /**
     * 给算法节点设置float类型参数
     *
     * @param nodeName  节点的名称
     * @param params    float参数集合
     */
    virtual BachErrorCode setParams(const std::string& nodeName, const std::unordered_map<std::string, float>& params) = 0;

    /**
     * 给算法节点设置string类型参数
     *
     * @param nodeName   节点的名称
     * @param params     string参数集合
     */
    virtual BachErrorCode setParams(const std::string& nodeName, const std::unordered_map<std::string, std::string>& params) = 0;

    /**
     * 算法执行结束，获取算法节点的结果，业务static_cast成具体的子类
     *
     * @param nodeName   节点的名称
     * @return  算法结果BachBuffer
     */
    virtual BachBuffer* getResult(const std::string& nodeName, uint32_t outputIndex = 0) = 0;

    /**
     * 给算法执行context设置common int类型参数
     *
     * @param params    int参数集合
     */
    virtual BachErrorCode setParams(const std::unordered_map<std::string, int64_t>& params) = 0;

    /**
     * 给算法执行context设置common float类型参数
     *
     * @param params    float参数集合
     */
    virtual BachErrorCode setParams(const std::unordered_map<std::string, float>& params) = 0;

    /**
     * 给算法执行context设置common string类型参数
     *
     * @param params     string参数集合
     */
    virtual BachErrorCode setParams(const std::unordered_map<std::string, std::string>& params) = 0;

    /**
     * 清理当前帧算法结果
     *
     * @return BachErrorCode
     */
    virtual BachErrorCode clearResults() = 0;

    /**
     * 获取算法图中的整数配置参数
     *
     * @param nodeName    节点名
     * @param intParam_   保存配置参数的整型哈希表
     */
    virtual BachErrorCode getParam(const std::string& nodeName,
                                   std::unordered_map<std::string, int64_t>&) = 0;

    /**
     * 获取算法图中的浮点型配置参数
     *
     * @param nodeName      节点名
     * @param floatParam_   保存配置参数的浮点型哈希表
     */
    virtual BachErrorCode getParam(const std::string& nodeName,
                                   std::unordered_map<std::string, float>&) = 0;

    /**
     * 获取算法图中的字符串配置参数
     *
     * @param nodeName       节点名
     * @param stringParam_   保存配置参数的字符串哈希表
     */
    virtual BachErrorCode getParam(const std::string& nodeName,
                                   std::unordered_map<std::string, std::string>&) = 0;

    /**
     * 同时获取算法图中的整数型、浮点型、字符串型配置参数
     *
     * @param algConfig       保存所有配置参数的哈希表
     */
    virtual BachErrorCode getAlgorithmConfigName(std::unordered_map<std::string, BachAlgorithmConfigWithNodeName>& algConfig) = 0;

    /**
     * 返回当前算法图所需要下载的模型名列表
     * @return  模型列表
     */
    virtual std::vector<std::string> getModelNames() = 0;

    /**
     * 添加Graph配置信息，只支持添加一张graph配置
     *
     * @param config 图的配置json字符串，业务读取文件传入
     * @param 根目录
     */
    virtual BachErrorCode initGraphWithRootPath(const std::string& config, const std::string& rootPath) = 0;

    /**
     * 设置cache路径
     *
     * @param cacheFolder 路径
     */
    virtual void setCacheFolder(const std::string& cacheFolder) = 0;
};

class BACH_EXPORT BachAlgorithmSystemWithDevice : public BachAlgorithmSystem
{
public:
    /**
     * 初始化算法需要的设备信息，需要在算法执行前设置，运行时不变
     * @param config 设备配置信息
     * @return 如果成功，返回 NO_ERROR
     */
    virtual BachErrorCode initDevice(const BachDeviceConfig& config) = 0;

    /**
     * 设置运行时需要设备数据信息，可以在其他线程设置，比如传感器回调函数中
     * @param dataType 设备数据类型
     * @param data      数据指针
     * @param dataLen   数据长度
     * @param timestamp 时间戳，时间单位秒
     * @return 如果数据格式正确，返回NO_ERROR
     */
    virtual BachErrorCode setDeviceData(DeviceDataType dataType, double* data, int dataLen, double timestamp) = 0;
};

class BachAlgorithmSystemGE;
class BACH_EXPORT BachAlgorithmFactory
{
public:
    /**
     * 创建默认的算法系统实例
     * @return 算法系统实例
     */
    static BachAlgorithmSystem* CreateAlgorithmSystem();

    /**
     * 创建支持Slam算法的系统实例
     * @return 算法系统实例
     */
    static BachAlgorithmSystemWithDevice* CreateAlgorithmSystemWithDevice();

    /**
     * 创建支持VE通用接口的算法系统实例
     * @return 算法系统实例
     */
    static BachAlgorithmSystemGE* CreateAlgorithmSystemGE();

    /**
     * 销毁算法系统实例
     * @param system 系统实例
     */
    static void DestroyAlgorithmSystem(BachAlgorithmSystem* system);

    /**
     * 获取Bach-SDK对应的版本号
     * @return sdk版本号
     */
    static std::string GetVersion();

    /**
     * 获取Bach-SDK的最新提交commit
     * @return sdk commit号
     */
    static std::string GetCommit();
};

NAMESPACE_BACH_END

#endif

#endif