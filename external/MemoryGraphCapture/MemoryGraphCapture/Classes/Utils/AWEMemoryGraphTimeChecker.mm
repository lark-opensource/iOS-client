//
//  AWEMemoryGraphTimeChecker.cpp
//  MemoryGraphCapture
//
//  Created by zhouyang11 on 2021/7/12.
//

#include "AWEMemoryGraphTimeChecker.hpp"

static const long edgeCountMask = (1<<17)-1;
static const long vmCountMask = (1<<9)-1;

namespace MemoryGraph {

AWEMemoryGraphTimeChecker &AWEMemoryGraphTimeChecker::GetInstance()
{
    // 局部静态特性的方式实现单实例
    static AWEMemoryGraphTimeChecker signal;
    return signal;
}

AWEMemoryGraphTimeChecker::AWEMemoryGraphTimeChecker()
{
}

AWEMemoryGraphTimeChecker::~AWEMemoryGraphTimeChecker()
{
}

bool AWEMemoryGraphTimeChecker::nodeCheckPoint(const ZONE_STRING &errstr)
{
    edgeCount++;
    if ((edgeCount & edgeCountMask) == 0) {
        return checkPoint(errstr);
    }
    return false;
}

bool AWEMemoryGraphTimeChecker::vmCheckPoint(const ZONE_STRING &errstr) {
    vmCount++;
    if((vmCount & vmCountMask) == 0) {
        return checkPoint(errstr);
    }
    return false;
}

void AWEMemoryGraphTimeChecker::startCheckWithMaxTime(double maxTime)
{
    timeLimit = maxTime;
    lastTime = CACurrentMediaTime();
    totalTime = 0;
    memset(&errstr, 0, sizeof(errstr));
    edgeCount = 0;
    vmCount = 0;
    isTimeOut = false;
}

bool AWEMemoryGraphTimeChecker::checkPoint(const ZONE_STRING &errstr)
{
    double curTime = CACurrentMediaTime();
    double duration = curTime - lastTime;
    totalTime += duration;
    lastTime = curTime;
    if (totalTime > timeLimit) {
        this->errstr = errstr;
        this->isTimeOut = true;
        return true;
    }
    return false;
}

double AWEMemoryGraphTimeChecker::checkTotalTime() {
    return totalTime;
}
}
