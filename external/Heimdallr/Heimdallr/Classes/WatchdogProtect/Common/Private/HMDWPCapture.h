//
//  HMDWPCapture.h
//
//  Created by 白昆仑 on 2020/4/9.
//

#import <Foundation/Foundation.h>
#import "HMDThreadBacktrace.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, HMDWPCaptureExceptionType) {
    HMDWPCaptureExceptionTypeWarning = 0,  // 调用耗时但未卡死
    HMDWPCaptureExceptionTypeError, // 调用卡死（超过10s等待阈值）
};

@interface HMDWPCapture : NSObject

+ (HMDWPCapture *)captureCurrentBacktraceWithSkippedDepth:(NSUInteger)depth;

@property(nonatomic, assign)HMDWPCaptureExceptionType type;
@property(nonatomic, strong)NSString *protectType;
@property(nonatomic, strong)NSString *protectSelector;
@property(nonatomic, strong)NSArray <HMDThreadBacktrace*>* _Nullable backtraces;
@property(nonatomic, strong)NSString *log;
@property(nonatomic, assign)NSTimeInterval timeoutInterval;
@property(nonatomic, assign)NSTimeInterval blockTimeInterval;
@property(nonatomic, assign, readonly)NSTimeInterval timestamp;
@property(nonatomic, assign, readonly)NSTimeInterval inAppTime;
@property(nonatomic, assign, getter=isMainThread) BOOL mainThread;

@end

NS_ASSUME_NONNULL_END
