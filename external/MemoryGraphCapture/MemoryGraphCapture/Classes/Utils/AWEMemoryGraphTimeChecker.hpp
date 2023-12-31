//
//  AWEMemoryGraphTimeChecker.hpp
//  MemoryGraphCapture
//
//  Created by zhouyang11 on 2021/7/12.
//

#ifndef AWEMemoryGraphTimeChecker_hpp
#define AWEMemoryGraphTimeChecker_hpp

#include "AWEMemoryAllocator.hpp"
#include <string>

#define MemoryGraphTimeChecker AWEMemoryGraphTimeChecker::GetInstance()

namespace MemoryGraph {
/// MemoryGraph防止超时机制
class AWEMemoryGraphTimeChecker
{
    
public:
    /// 单例
    static AWEMemoryGraphTimeChecker &GetInstance();
    /// start
    void startCheckWithMaxTime(double maxTime);
    /// check point with error desc, true->timeout
    bool checkPoint(const ZONE_STRING &errstr);
    /// 超时描述
    ZONE_STRING errstr;
    /// 是否超时标识
    bool isTimeOut;
    /// 有效边检查点
    bool nodeCheckPoint(const ZONE_STRING &errstr);
    
    double checkTotalTime();
    
    bool vmCheckPoint(const ZONE_STRING &errstr);
private:
    // 采集的最长时间，超时会执行异常逻辑
    double timeLimit;
    // 上一次计时时间
    double lastTime;
    // 采集总时长
    double totalTime;
    // 分析有效边的总个数
    unsigned long edgeCount;
    // 分析vm的个数
    unsigned long vmCount;
    // 禁止外部构造
    AWEMemoryGraphTimeChecker();
    // 禁止外部析构
    ~AWEMemoryGraphTimeChecker();
    // 禁止外部复制构造
    AWEMemoryGraphTimeChecker(const AWEMemoryGraphTimeChecker &signal);
    // 禁止外部赋值操作
    const AWEMemoryGraphTimeChecker &operator=(const AWEMemoryGraphTimeChecker &signal);
};

}

#endif /* AWEMemoryGraphTimeChecker_hpp */
