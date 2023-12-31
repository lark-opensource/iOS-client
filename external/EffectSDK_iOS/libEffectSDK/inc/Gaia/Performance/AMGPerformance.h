
/**
* @file AMGPerformance.h
* @author liuang (liuang@bytedance.com)
* @brief File
* @version 10.21.0
* @date 2020-7-16
* @copyright Copyright (c) 2020
*/

#ifndef performance_hpp
#define performance_hpp

#include "AMGPerformanceEvaluation.h"

NAMESPACE_AMAZING_ENGINE_BEGIN
class GAIA_LIB_EXPORT PerformanceCap
{
public:
    PerformanceCap();
    ~PerformanceCap() = default;
    PerformanceEvaluate* getEvaluateInstance() const;
    StatisticsFrameCost* getStatisticsFrameCost(PerformanceEvaluateType type);

private:
    std::unique_ptr<PerformanceEvaluate> m_evaluateInstance = nullptr;
    std::vector<std::unique_ptr<StatisticsFrameCost>> m_statisticsFrameCost;
};

NAMESPACE_AMAZING_ENGINE_END
#endif /* performance_hpp */
