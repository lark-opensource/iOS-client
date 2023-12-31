//
//  OPError.m
//  LarkOPInterface
//
//  Created by yinyuan on 2020/7/9.
//

#import "OPError.h"
#import "NSError+OP.h"
#import <ECOProbe/OPMonitorCode.h>
#import <ECOProbe/OPMonitor.h>
#import <ECOProbe/ECOProbe-Swift.h>


@interface OPError()

/// 对应的 OPMonitorCode 对象
@property (nonatomic, strong, readwrite, nonnull) OPMonitorCode *monitorCode;

/// 对应的 userInfo
@property (nonatomic, copy, readwrite, nonnull) NSDictionary<NSString *,id> *userInfo;

@property (nonatomic, strong, readwrite, nullable) NSError *originError;

@property (nonatomic, copy, readwrite) NSString *fileName;
@property (nonatomic, copy, readwrite) NSString *funcName;
@property (nonatomic, assign, readwrite) NSInteger line;

/// 是否开启自动上报
@property (nonatomic, assign) BOOL autoReportEnabled;
/// 是否已经有过上报
@property (nonatomic, assign) BOOL reported;

@end

@implementation OPError

/// 私有的初始化方法
/// @param monitorCode OPMonitorCode
/// @param error NSError
/// @param dict userInfo 自定义信息
/// @param fileName 文件名（一般自动填写）
/// @param funcName 方法名（一般自动填写）
/// @param line 行号（一般自动填写）
- (instancetype _Nonnull)initWithMonitorCode:(OPMonitorCode * _Nonnull)monitorCode
                                       error:(NSError * _Nullable)error
                                    userInfo:(NSDictionary<NSString *,id> * _Nullable)dict
                                    fileName:(const char * _Nullable)fileName
                                    funcName:(const char * _Nullable)funcName
                                        line:(NSInteger)line {
    NSAssert(monitorCode, @"OPError.init: monitorCode should not be nil!");
    NSAssert(fileName && funcName && line, @"OPError.init: fileName, funcName and line should not be nil or 0!");
    
    if (!monitorCode) {
        // 没填 monitorCode 的情况，依然要确保 OPMonitorCode 不为空，因为 monitorCode nonnull，这里填入一个 error_with_empty_monitor_code 的 code
        monitorCode = [[OPMonitorCode alloc] initWithDomain:@"client.error" code:0 level:OPMonitorLevelError message:@"error_with_empty_monitor_code"];
    }
    
    NSMutableDictionary *userInfo = dict.mutableCopy ?: NSMutableDictionary.dictionary;
    
    userInfo[OPMonitorEventKey.monitor_id] = monitorCode.ID;
    userInfo[OPMonitorEventKey.monitor_message] = monitorCode.message;
    
    if (fileName && fileName && line) {
        // 三者要么一起设置，要么都不设置
        userInfo[OPMonitorEventKey.monitor_file] = [NSString stringWithUTF8String:fileName];
        userInfo[OPMonitorEventKey.monitor_function] = [NSString stringWithUTF8String:funcName];
        userInfo[OPMonitorEventKey.monitor_line] = @(line);
    }
    
    if (error) {
        // 设置 Error 信息
        userInfo[OPMonitorEventKey.error_code] = @(error.code);
        userInfo[OPMonitorEventKey.error_domain] = error.domain;
        if (error.userInfo) {
            // 递归地设置 userInfo，如果重复包装 OPError(OPError(OPError(NSError).nsError).nsError), 将会形成一个链式结构完整记录错误链路
            userInfo[OPMonitorEventKey.error_user_info] = error.userInfo.copy;
        }
    }
    
    self = [super initWithDomain:monitorCode.domain code:monitorCode.code userInfo:userInfo];
    if (self) {
        self.monitorCode = monitorCode;
        self.originError = error;
        
        self.fileName = fileName ? [NSString stringWithUTF8String:fileName] : nil;
        self.funcName = funcName ? [NSString stringWithUTF8String:funcName] : nil;
        self.line = line;
        
        self.autoReportEnabled = YES;   // 默认开启异常自动上报
        
        // 先输出一份日志
        OPLogError(@"OPError:%@", self.description);
    }
    return self;
}

- (void)dealloc {
    if (self.autoReportEnabled) {
        // 如果开启了自动上报，会尝试上报
        [self reportError];
    }
}

- (void)reportError {
    if (self.reported) {
        return;
    }
    self.reported = YES;
    
    // 注意这里不能直接传入 setError（因为这里会在delloc中调用），否则会出现crash
    [[OPMonitorEvent alloc] initWithService:nil name:nil monitorCode:self.monitorCode]
    .setErrorMessage(self.description)
    .__flushWithContextInfo(self.fileName.UTF8String, self.funcName.UTF8String, self.line);
}

- (OPError *)disableAutoReport {
    self.autoReportEnabled = NO;
    return self;
}

- (OPError *)reportRightNow {
    [self reportError];
    return self;
}

@end

// 为什要用 C 函数来作为 OPError 的初始化方法？
// 主要是因为避免将 fileName、funcName、line 的传入直接暴露给使用者，这三个参数需要通过宏来传入。
// 另外，OC不暴露init方法，因而在 swift 中支持者三个参数新增一个初始化方法不会与OC的初始化方法冲突。
// 虽然比较琐碎，但为了能够较好的同时支持 OC 和 Swift，经过多番比较之后选择的平衡的方案。后续如果弃用 OC，可全部转为 Swift，则不存在此问题。
OPError * _Nonnull __OPErrorNew(OPMonitorCode * _Nonnull monitorCode,
                                NSError * _Nullable error,
                                NSDictionary<NSString *,id> * _Nullable userInfo,
                                const char * _Nullable fileName,
                                const char * _Nullable funcName,
                                NSInteger line) {
    return [[OPError alloc] initWithMonitorCode:monitorCode error:error userInfo:userInfo fileName:fileName funcName:funcName line:line];
}
