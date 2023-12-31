//
//  FlameGraphTools.m
//  EEAtomic
//  插桩pass中的函数，已集成到toolchain里，需要实现此方法，否则编译报错
//  Created by CL7R on 2020/8/26.
//
#import <Foundation/Foundation.h>
#import <FlameGraphTools/FlameGraphTools-Swift.h>

double es_func_begin(const char *f) {
    return CFAbsoluteTimeGetCurrent();
}

void es_func_end(const char *f, double startTime) {
    double endTime = CFAbsoluteTimeGetCurrent();
    double costTime = (endTime - startTime) * 1000;
    //耗时超过x ms的方法才记录
    if (costTime > MethodTraceLoggerBridge.funcCost) {
        [MethodTraceLoggerBridge logWithName:(const int8_t *)f start:startTime end:endTime];
    }
}
