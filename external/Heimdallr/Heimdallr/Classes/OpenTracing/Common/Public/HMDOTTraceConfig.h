//
//  HMDOTTraceConfigd.h
//  Pods
//
//  Created by liuhan on 2022/6/7.
//
#import <Foundation/Foundation.h>
#import "HMDOTTraceDefine.h"

extern NSString * _Nonnull const kHMDTraceParentStr;

@interface HMDOTTraceConfig : NSObject

@property (nonatomic, copy, readonly, nullable) NSString *serviceName; /*trace的名字*/

@property (nonatomic, copy, nullable) NSString *customHighOrderTraceID; /*自定义traceID的高64位，同时传递traceParent以traceParent为准*/

@property (nonatomic, copy, nullable) NSString *traceParent; /*traceParent字符串，包含traceID高64位信息，同时传递customHighOrderTraceID以traceParent为准。traceParent标准格式为{Version:2}-{TraceId:32}-{ParentId:16}-{Flags:2}*/

@property (nonatomic, assign) BOOL isForcedUplaod; /*是否强制采样命中，默认为否*/

@property (nonatomic, strong, nullable) NSDate *startDate; /*trace开始时间*/

@property (nonatomic, assign) HMDOTTraceInsertMode insertMode; /*span写入模式，具体可以查看HMDOTTraceInsertMode枚举的定义，默认为HMDOTTraceInsertModeEverySpanStart*/


/*movingline record*/
@property (nonatomic, assign) BOOL isMovingLine; /*default is false*/

/*the type of trace, e.g: app.ui.page*/
@property (nonatomic, copy, nullable) NSString *type;

- (nonnull instancetype)initWithServiceName:(nonnull NSString *)serviceName;

- (nonnull id)init __attribute__((unavailable("initWithServiceName:")));
+ (nonnull instancetype)new __attribute__((unavailable("initWithServiceName:")));

@end


typedef void (^HMDOTTraceMemoryCacheOverCallBack)(void);

@interface HMDOTManagerConfig : NSObject

@property (nonatomic, assign) BOOL enableCacheUnHitLog;  /*是否缓存未命中的动线数据，默认为NO*/

@property (nonatomic, assign) long long maxCacheFileSize; /*缓存文件大小，默认256(KB)*/

@property (nonatomic, assign) int maxMemoryCacheCount; /*内存缓存区缓存最大数量,默认400*/

@property (nonatomic, assign) int memoryCacheOverCallbackInvokeInterval;/*溢出回调调用时间间隔，单位s，默认60(s)*/

@property (nonatomic, strong, nullable) HMDOTTraceMemoryCacheOverCallBack memoryCacheOverCallBack; /*内存缓存区溢出回调，业务需立即finish当前页面trace*/

/**
 单例方法

 @return 返回HMDOTManagerConfig类的单例
 */
+ (instancetype _Nonnull )defaultConfig;

@end
