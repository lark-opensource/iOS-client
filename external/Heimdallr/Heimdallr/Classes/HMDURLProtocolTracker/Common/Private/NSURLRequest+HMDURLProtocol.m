//
//  NSURLRequest+HMDURLProtocol.m
//  Heimdallr
//
//  Created by fengyadong on 2018/3/8.
//
#import "Heimdallr+Private.h"
#import "HMDHTTPRequestTracker.h"
#import "HMDHTTPTrackerConfig.h"
#import "HeimdallrUtilities.h"
#import "HMDFileTool.h"
#import <objc/runtime.h>
#import "NSURLRequest+HMDURLProtocol.h"
// PrivateServices
#import "HMDMonitorService.h"

@implementation NSURLRequest (hmdNSURLProtocolExtension)

//- (NSMutableURLRequest *)hmd_getPostRequestIncludeBody {
//    NSMutableURLRequest * req = [self mutableCopy];
//    if ([self.HTTPMethod isEqualToString:@"POST"]) {
//        if (!self.HTTPBody) {
//            NSInteger maxLength = 1024;
//            uint8_t d[maxLength];
//            NSInputStream *stream = self.HTTPBodyStream;
//            NSMutableData *data = [[NSMutableData alloc] init];
//            [stream open];
//            BOOL endOfStreamReached = NO;
//            //不能用 [stream hasBytesAvailable]) 判断，处理图片文件的时候这里的[stream hasBytesAvailable]会始终返回YES，导致在while里面死循环。
//            while (!endOfStreamReached) {
//                NSInteger bytesRead = [stream read:d maxLength:maxLength];
//                if (bytesRead == 0) { //文件读取到最后
//                    endOfStreamReached = YES;
//                } else if (bytesRead == -1) { //文件读取错误
//                    endOfStreamReached = YES;
//                } else if (stream.streamError == nil) {
//                    [data appendBytes:(void *)d length:bytesRead];
//                }
//            }
//            req.HTTPBody = [data copy];
//            [stream close];
//        }
//
//    }
//    return req;
//}

- (NSString *)hmdTempDataFilePath {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setHmdTempDataFilePath:(NSString *)hmdTempDataFilePath {
    objc_setAssociatedObject(self, @selector(hmdTempDataFilePath), hmdTempDataFilePath, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSInteger)hmdHTTPBodyStreamLength {
    return [objc_getAssociatedObject(self, _cmd) integerValue];
}

- (void)setHmdHTTPBodyStreamLength:(NSInteger)hmdBodyLength {
    objc_setAssociatedObject(self, @selector(hmdHTTPBodyStreamLength), @(hmdBodyLength), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

@implementation NSMutableURLRequest (hmdNSURLProtocolExtension)

- (void)hmd_handlePostRequestBody {
    if ([self.HTTPMethod isEqualToString:@"POST"]) {
        if (!self.HTTPBody) {
            NSInteger maxLength = 1024;
            uint8_t d[maxLength];
            NSInputStream *stream = self.HTTPBodyStream;
            
            NSMutableData *data = [[NSMutableData alloc] init];
            @try {
                [data increaseLengthBy:maxLength];
            } @catch (NSException *exception) {
                //打个点，内存不足
                return;
            }
            BOOL tempDataExist = YES;
            NSInteger tempDataLength = 1024;
            NSInteger tempDataLoc = 0;
            
            NSInteger totalLength = 0;
            [stream open];
            BOOL endOfStreamReached = NO;
            //不能用 [stream hasBytesAvailable]) 判断，处理图片文件的时候这里的[stream hasBytesAvailable]会始终返回YES，导致在while里面死循环。
            NSString *fileURLString = nil;
            NSFileHandle *fileHandle = nil;
            while (!endOfStreamReached) {
                NSInteger bytesRead = [stream read:d maxLength:maxLength];
                if (bytesRead == 0) { //文件读取到最后
                    endOfStreamReached = YES;
                } else if (bytesRead == -1) { //文件读取错误
                    endOfStreamReached = YES;
                } else if (stream.streamError == nil) {
                    totalLength += bytesRead;
                    if (!tempDataExist && totalLength > 5 * 1024 * 1024) {
                        if (!fileURLString) {
                            fileURLString = [self hmd_dataTempFileURLString];
                            fileHandle = [NSFileHandle fileHandleForUpdatingAtPath:fileURLString];
                        }
                        [fileHandle seekToEndOfFile];
                        [fileHandle writeData:data];
                        [data resetBytesInRange:NSMakeRange(0, data.length)];
                        tempDataLoc = 0;
                        tempDataLength = data.length;
                        tempDataExist = tempDataLength > 0;
                    }
                    if (tempDataExist) {
                        //由于每次都是读1024字节，只有最后一次会出现不足1024字节，所以tempDataLength一定是1024字节的整数倍，所以在此分支，不存在tempDataLength < bytesRead的情况
                        if (bytesRead >= 1024) {
                            [data replaceBytesInRange:NSMakeRange(tempDataLoc, 1024) withBytes:d];
                            tempDataLoc += 1024;
                        } else {
                            [data replaceBytesInRange:NSMakeRange(tempDataLoc, bytesRead) withBytes:d];
                            tempDataLoc += bytesRead;
                        }
                        tempDataLength -= bytesRead;
                        tempDataExist = tempDataLength > 0;
                    } else {
                        [data appendBytes:(void *)d length:bytesRead];
                    }
                }
            }
            if (tempDataExist) {
                [data replaceBytesInRange:NSMakeRange(tempDataLoc, tempDataLength) withBytes:NULL length:0];
            }
            if (fileURLString) {
                [fileHandle seekToEndOfFile];
                [fileHandle writeData:data];
                [fileHandle closeFile];
                self.HTTPBodyStream = [NSInputStream inputStreamWithFileAtPath:fileURLString];
                self.hmdTempDataFilePath = fileURLString;
                [HMDMonitorService trackService:@"slardar_urlprotocol_huge_httpbody" metrics:@{@"bodyLength":@(totalLength)} dimension:nil extra:@{@"url":(self.URL.absoluteString ?: @"nil")} syncWrite:NO];
            } else {
                self.HTTPBody = data;
            }
            self.hmdHTTPBodyStreamLength = totalLength;
            [stream close];
        }
        
    }
}

+ (void)hmd_setupDataTempFolderPath {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [[NSFileManager defaultManager] removeItemAtPath:[self hmd_dataTempFolderURLString] error:nil];
        hmdCheckAndCreateDirectory([self hmd_dataTempFolderURLString]);
    });
}

+ (NSString *)hmd_dataTempFolderURLString {
    return [[HeimdallrUtilities heimdallrRootPath] stringByAppendingPathComponent:@"URLProtocol"];
}

- (NSString *)hmd_dataTempFileURLString {
    NSString *fileURLString = [[[self class] hmd_dataTempFolderURLString] stringByAppendingPathComponent:[NSUUID UUID].UUIDString];
    [[NSFileManager defaultManager] createFileAtPath:fileURLString contents:nil attributes:nil];
    return fileURLString;
}

- (void)hmd_handleRequestHeaderFromTraceLogSample {
    HMDHTTPTrackerConfig *netMonitor = (HMDHTTPTrackerConfig *)[HMDHTTPRequestTracker sharedTracker].config;
    BOOL enableBaseApiAll = netMonitor.baseApiAll.floatValue > 0;
    BOOL enableApiAll = netMonitor.enableAPIAllUpload;
    BOOL enableTraceLog = netMonitor.enableTTNetCDNSample;

    if (enableTraceLog && enableBaseApiAll) {
        [self setValue:@"01" forHTTPHeaderField:@"x-tt-trace-log"];
    } else if (enableTraceLog && enableApiAll) {
        [self setValue:@"02" forHTTPHeaderField:@"x-tt-trace-log"];
    }
}

@end
