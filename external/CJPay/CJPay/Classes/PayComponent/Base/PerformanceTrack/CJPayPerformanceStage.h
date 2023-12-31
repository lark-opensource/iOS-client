//
//  CJPayPerformanceStage.h
//  Pods
//
//  Created by 王新华 on 2021/10/15.
//

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, CJPayPerformanceStageType) {
    CJPayPerformanceStageTypeNone = 0,
    CJPayPerformanceStageTypeAPIStart, // API 调用
    CJPayPerformanceStageTypeAPIEnd,   // API 调用结束
    CJPayPerformanceStageTypeRequestStart,  // 请求发起
    CJPayPerformanceStageTypeRequestEnd,    // 请求回调
    CJPayPerformanceStageTypePageInit,      // 页面初始化
    CJPayPerformanceStageTypePageAppear,    // 页面出现
    CJPayPerformanceStageTypePageFinishRender, // 页面渲染完成
    CJPayPerformanceStageTypePageDisappear,   // 页面消失
    CJPayPerformanceStageTypePageDealloc,     // 页面占用内容销毁
    CJPayPerformanceStageTypeActionCell,      // 点击cell
    CJPayPerformanceStageTypeActionBtn,       // 点击button
    CJPayPerformanceStageTypeActionGesture,   // 手势触发
};
 
// 100个Model
@interface CJPayPerformanceStage : NSObject

@property (nonatomic, copy, nonnull) NSString *name;
@property (nonatomic, assign) CJPayPerformanceStageType stageType;
@property (nonatomic, copy, readonly) NSString *stageTypeStr;
@property (nonatomic, assign) CFAbsoluteTime curTime;
@property (nonatomic, copy, nonnull) NSString *sdkProcessID;
@property (nonatomic, copy, nullable) NSString *pageName;
@property (nonatomic, copy) NSDictionary *extra;

- (BOOL)isValid;

@end

NS_ASSUME_NONNULL_END
