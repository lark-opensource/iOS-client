//
//  OPContextLogger.m
//  Timor
//
//  Created by yinyuan on 2020/9/7.
//

#import "OPContextLogger.h"

@interface OPContextLogger ()

/// 扩展日志信息
@property (nonatomic, strong) NSMutableString *exLogInfo;

/// 文件名
@property (nonatomic, copy) NSString *fileName;

/// 方法名
@property (nonatomic, copy) NSString *funcName;

/// 代码行
@property (nonatomic, assign) NSInteger line;

@end

@implementation OPContextLogger

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.exLogInfo = NSMutableString.string;
    }
    return self;
}

- (OPContextLogger * _Nonnull (^ _Nonnull)(NSString * _Nullable name, id _Nullable value))addLogValue {
    __weak typeof(self) weakSelf = self;
    return ^OPContextLogger *(NSString * _Nullable name, id _Nullable value) {
        typeof(weakSelf) self = weakSelf;
        if (!self) {
            return nil;
        }
        if (name) {
            self.addLogMessage(@"%@:%@", name, value);
        }
        return self;
    };
}

- (OPContextLogger * _Nonnull (^ _Nonnull)(NSString * _Nullable message, ...))addLogMessage {
    __weak typeof(self) weakSelf = self;
    return ^OPContextLogger *(NSString * _Nullable message, ...) {
        typeof(weakSelf) self = weakSelf;
        if (!self) {
            return nil;
        }
        return [self __addLogMessage:message];
    };
}

- (OPContextLogger *)__addLogMessage:(NSString * _Nullable)message {
    if (message && [message isKindOfClass:NSString.class] && message.length > 0) {
        @synchronized (self) {
            if (self.exLogInfo.length > 0) {
                // 后面新增的日志信息，前面加一个 逗号+空格
                [self.exLogInfo appendString:@", "];
            }
            [self.exLogInfo appendString:message];
        }
    }
    return self;
}

- (OPContextLogger * _Nonnull (^ _Nonnull)(OPLogLevel level, const char* _Nullable fileName, const char* _Nullable funcName, NSInteger line, NSString * _Nullable message))__logWithContextInfo {
    __weak typeof(self) weakSelf = self;
    return ^OPContextLogger *(OPLogLevel level, const char* _Nullable fileName, const char* _Nullable funcName, NSInteger line, NSString * _Nullable message) {
        typeof(weakSelf) self = weakSelf;
        if (!self) {
            return nil;
        }
        @synchronized (self) {
            [self logLevel:level fileName:fileName funcName:funcName line:line message:message];
        }
        return self;
    };
}

- (void)logLevel:(OPLogLevel)level
        fileName:(const char* _Nullable)fileName
        funcName:(const char* _Nullable)funcName
            line:(int)line
         message:(NSString *)message {
    NSString *logContent = [NSString stringWithFormat:@"%@. %@", message ?: @"", self.exLogInfo];
    _OPLog(level, self.tag, (fileName ?: self.fileName.UTF8String), funcName ?: self.funcName.UTF8String, (line ?: self.line), logContent);
}

@end
