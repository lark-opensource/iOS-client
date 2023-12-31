//
//  BDPPerformanceMonitor.h
//  Timor
//
//  Created by muhuai on 2018/3/11.
//

#import <Foundation/Foundation.h>

@protocol BDPTiming <NSObject>
- (void)timing:(NSString *)name;                                            // 记录当前时间点
- (void)timing:(NSString *)name value:(NSTimeInterval)time;                 // 记录指定时间点
- (NSDictionary *)timingData;                                               // 返回所有timing数据
@end

@protocol BDPAppTiming <BDPTiming>
@optional
- (void)timing_appStart:(NSTimeInterval)time;
@end

@protocol TMAPageTiming <BDPTiming>
@optional
- (void)timing_pageStart;
- (void)timing_pageWebViewLoad;
- (void)timing_pageFrameLoad;
- (void)timing_pageNavigationComplete;
@end

@protocol BDPWebViewTiming <BDPTiming>
@optional
- (void)timing_pageInitReady;
- (void)timing_pageWebViewDocumentReady;
@end

@protocol BDPJSContextTiming <BDPTiming>
@optional
- (void)timing_setDataReceive:(NSTimeInterval)time;
- (void)timing_setDataSendJS;
- (void)timing_appJSCoreStart;
- (void)timing_appJSCoreAppJSLoad;
- (void)timing_appJSCoreDocumentReady;
@end

@interface BDPPerformanceMonitor : NSObject <BDPTiming>

- (void)setPerformance:(NSString *)name value:(NSObject *)value;

- (NSDictionary *)performanceData;

@end
