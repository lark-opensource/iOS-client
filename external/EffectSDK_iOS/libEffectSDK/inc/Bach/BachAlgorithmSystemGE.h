#ifdef __cplusplus
#ifndef _BACH_ALGORITHM_SYSTEM_GE_H_
#define _BACH_ALGORITHM_SYSTEM_GE_H_

#include <unordered_map>

#include "Bach/BachAlgorithmSystem.h"

NAMESPACE_BACH_BEGIN

class BACH_EXPORT BachAlgorithmSystemGE : public BachAlgorithmSystem
{
public:
    class BACH_EXPORT GEInputInfo
    {
    public:
        std::string name;
        BachInputType inputType = BachInputType::IMAGE_BUFFER;
        std::string dataSrc;
    };

    class BACH_EXPORT GEOutputInfo
    {
    public:
        std::string name;
        AlgorithmType algorithmType = AlgorithmType::INVALID;
        std::string usage;
        uint32_t outputIndex = 0;
    };

    /**
     * 添加Graph配置信息，只支持添加一张graph配置
     *
     * @param path 图的配置json路径，支持全路径or目录(自动解析目录下/algorithmConfig.json)
     */
    virtual BachErrorCode initGraphWithPath(const std::string& path) = 0;

    /**
     * 获取算法需要的输入宽高
     *
     * @param view_width 画面宽
     * @param view_height 画面高
     * @param width 输出需要的宽
     * @param height 输出需要的高
     */
    virtual BachErrorCode getInputSize(int view_width, int view_height, int& width, int& height) = 0;

    /**
     * JSON 格式设置参数
     * @param config JSON字符串
     * @return 如果成功，返回 NO_ERROR
     */
    virtual BachErrorCode setParamsFromJSON(const std::string& config) = 0;

    /**
     * 算法初始化Graph结束, 获取算法输入信息
     * @return  算法输入信息
     */
    virtual std::unordered_map<std::string, GEInputInfo>& getInputInfos() = 0;

    /**
     * 算法初始化Graph结束, 获取算法输出信息
     * @return  算法输出信息
     */
    virtual std::unordered_map<std::string, GEOutputInfo>& getOutputInfos() = 0;
};

NAMESPACE_BACH_END

#endif

#endif