
/**
* @file AMGPerformanceEvaluation.h
* @author liuang (liuang@bytedance.com)
* @brief File
* @version 10.21.0
* @date 2020-7-16
* @copyright Copyright (c) 2020
*/

#ifndef performanceEvaluation_hpp
#define performanceEvaluation_hpp

#include "Gaia/AMGPrerequisites.h"
#include <unordered_map>
#include <map>
#include <string>
#include <atomic>

NAMESPACE_AMAZING_ENGINE_BEGIN
/*
 *@breid module swtich,use for function or performance debug
 */
enum PerformanceEvaluateSwitchMode
{
    PESM_SWITCH_NONE,
    PESM_SWITCH_RENDER,
    PESM_SWITCH_TERMINAL_DRAW,
    PESM_SWITCH_FEATURE,
    PESM_SWITCH_ALGORITHM,
    PESM_SWITCH_ALGIRITHM_HARDWARE,
    PESM_SWITCH_COUNT
};

class GAIA_LIB_EXPORT PerformanceEvaluate
{
public:
    PerformanceEvaluate();
    ~PerformanceEvaluate() = default;
    PerformanceEvaluate(const PerformanceEvaluate&) = delete;
    PerformanceEvaluate(const PerformanceEvaluate&&) = delete;
    PerformanceEvaluate& operator=(const PerformanceEvaluate&) = delete;
    void setSwitchStatus(PerformanceEvaluateSwitchMode swtich, bool status);
    bool getSwitchStatus(PerformanceEvaluateSwitchMode swtich) const;

private:
    std::unordered_map<PerformanceEvaluateSwitchMode, bool> m_switchStatus;
};

enum PerformanceEvaluateType
{
    PET_THREAD_RENDER = 0,
    PET_THREAD_ALGORITHM = 1,
    PET_FIRST_FRAME,
    PET_EFFECT_SWITCH,
    PET_COUNT
};

class GAIA_LIB_EXPORT StatisticsFrameCost
{
public:
    StatisticsFrameCost() = delete;
    StatisticsFrameCost(const StatisticsFrameCost&) = delete;
    StatisticsFrameCost(const StatisticsFrameCost&&) = delete;
    StatisticsFrameCost(PerformanceEvaluateType type);
    ~StatisticsFrameCost() = default;
    StatisticsFrameCost& operator=(const StatisticsFrameCost&) = delete;
    void beginRecord();
    void beginRecord(const std::string& tag);
    void setDirtyFalse(bool flag);
    void setTiggersDirtyTagFalse(const std::string& tag);
    void endRecord();
    void endRecord(const std::string& tag);
    bool trigStatisticsPoint(const std::string& tag);
    void printLog();
    void reset();
    void resetTriggers();
    int getFrameCount() const { return m_frameCount; }
    void addFrameCount() { m_frameCount++; }
    void setEnable(bool enable) { m_enable = enable; }
    double getTimeCost();
    double getTimeCost(const std::string& tag);

private:
    long long m_frameBeginTime = 0;
    unsigned int m_frameCount = 0;
    unsigned int m_trigIndex = 0;
    std::atomic<bool> m_dirty;
    bool m_enable = false;
    std::atomic<double> m_timeCost;
    std::map<unsigned int, std::string> m_triggers;
    std::vector<double> m_triggersCost;
    PerformanceEvaluateType m_type;
    std::string m_tag = "";
    bool m_recording = false;
    std::unordered_map<std::string, bool> m_tiggersDirty;
    // <tracePointTag, traceBeginTimePoint>
    std::unordered_map<std::string, long long int> m_beginTriggersTime;
    // <tracePointTag, <traceNum, totalCostTime>>
    std::unordered_map<std::string, std::pair<unsigned int, long long int>> m_triggersTimeCost;
};
NAMESPACE_AMAZING_ENGINE_END
#endif /* performanceEvaluation_hpp */
