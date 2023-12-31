//
//  HMDFileUploader.h
//  Heimdallr
//
//  Created by fengyadong on 2018/10/24.
//

#import "HMDFileUploader.h"
#if RANGERSAPM
#import "HMDFileUploader+RangersAPMURLProvider.h"
#import "RangersAPMUploadHelper.h"
#else
#import "HMDFileUploader+HMDURLProvider.h"
#endif /* RANGERSAPM */
#import "HMDFileUploadRequest+URLPathProvider.h"
// Utility
#import "HMDMacro.h"
#import "NSData+HMDJSON.h"
#import "NSDictionary+HMDHTTPQuery.h"
#import "NSDictionary+HMDSafe.h"
// ALog
#import "HMDALogProtocol.h"
// DeviceInfo
#import "HMDInfo+AppInfo.h"
#import "HMDInjectedInfo.h"
// Network
#import "HMDNetworkManager.h"
#import "HMDNetworkUploadModel.h"
// PrivateServices
#import "HMDURLManager.h"

#define HMD_FILE_BOUNDARY @"AaB03x"
#define HMD_NEW_LINE [[NSString stringWithFormat:@"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]

NSString *const kHMDFileUploadDefaultPath = @"/monitor/collect/c/logcollect";

@implementation HMDFileUploader

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static HMDFileUploader *share = nil;
    dispatch_once(&onceToken, ^{
        share = [[HMDFileUploader alloc] init];
    });
    return share;
}

- (void)uploadFileWithRequest:(nonnull HMDFileUploadRequest *)request {
    if (![HMDInjectedInfo defaultInfo].canUploadFile) {
        if (request.finishBlock) {
            request.finishBlock(NO,nil);
        }
        return;
    }
    
    BOOL isDir = NO;
    if (!request.filePath || ![[NSFileManager defaultManager] fileExistsAtPath:request.filePath isDirectory:&isDir] || isDir) {
        if (request.finishBlock) {
            request.finishBlock(NO,nil);
        }
        return;
    }
    request.logType = request.logType?:@"unknown";
    request.scene = request.scene?:@"unknown";
    request.path = request.path?:kHMDFileUploadDefaultPath;
    request.commonParams = request.commonParams?:@{};
    // test did:48052456271
    NSString *uploadURL = [HMDURLManager URLWithHostProvider:self pathProvider:request forAppID:[HMDInjectedInfo defaultInfo].appID];
    NSAssert(uploadURL, @"Both host and path cannot be nil!");
    if (uploadURL == nil) {
        if (request.finishBlock) {
            request.finishBlock(NO, nil);
        }
        return;
    }
    HMDInjectedInfo *injectedInfo = [HMDInjectedInfo defaultInfo];
    HMDInfo *info = [HMDInfo defaultInfo];
    //combine URLString
    NSMutableDictionary *queryParams = [NSMutableDictionary dictionary];
    [queryParams addEntriesFromDictionary:[HMDInjectedInfo defaultInfo].commonParams];
    [queryParams hmd_setObject:injectedInfo.deviceID forKey:@"device_id"];
    if (injectedInfo.scopedDeviceID) {
        [queryParams hmd_setObject:injectedInfo.scopedDeviceID forKey:@"scoped_device_id"];
    }
    [queryParams hmd_setObject:injectedInfo.appID forKey:@"aid"];
    [queryParams hmd_setObject:info.shortVersion forKey:@"app_version"];
    [queryParams hmd_setObject:info.sdkVersion forKey:@"sdk_version"];
    [queryParams hmd_setObject:info.buildVersion forKey:@"update_version_code"];
    [queryParams hmd_setObject:injectedInfo.channel forKey:@"channel"];
    [queryParams hmd_setObject:@"iOS" forKey:@"os"];
#if RANGERSAPM
    [queryParams hmd_setObject:injectedInfo.userID forKey:@"uid"];
    [queryParams hmd_setObject:injectedInfo.userID forKey:@"user_id"];
#endif

    NSString *queryStr = [queryParams hmd_queryString];
    NSString *uploadURLString = [NSString stringWithFormat:@"%@?%@", uploadURL, queryStr];

    NSURL *url = [NSURL URLWithString:uploadURLString];
    
    //request
    BOOL isAlogUpload = [request.logType isEqualToString:@"alog"];
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url];
    urlRequest.HTTPMethod = @"POST";
    [urlRequest setValue:[NSString stringWithFormat:@"multipart/form-data;boundary=%@",HMD_FILE_BOUNDARY] forHTTPHeaderField:@"Content-Type"];
    if (isAlogUpload) {
        [urlRequest setValue:request.scene forHTTPHeaderField:@"scene"];
    }
    
#if RANGERSAPM
    NSDictionary<NSString *, NSString *> *headerField = [RangersAPMUploadHelper headerFieldsForAppID:injectedInfo.appID];
    [headerField enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
        if (!HMDIsEmptyString(key) && !HMDIsEmptyString(obj)) {
            [urlRequest setValue:obj forHTTPHeaderField:key];
        }
    }];
#endif
    NSMutableData *data = [[NSMutableData alloc] init];
    
    NSMutableDictionary *mParams = [NSMutableDictionary dictionary];
    NSAssert([[HMDInjectedInfo defaultInfo] appID], @"appID cannot be nil!");
    [mParams setValue:[[HMDInjectedInfo defaultInfo] appID] forKey:@"aid"];
    [mParams setValue:[HMDInjectedInfo defaultInfo].deviceID forKey:@"device_id"];
    if ([HMDInjectedInfo defaultInfo].scopedDeviceID) {
        [mParams setValue:[HMDInjectedInfo defaultInfo].scopedDeviceID forKey:@"scoped_device_id"];
    }
    [mParams setValue:@"iOS" forKey:@"os"];
#if RANGERSAPM
    [mParams setValue:[HMDInjectedInfo defaultInfo].userID forKey:@"uid"];
    [mParams setValue:[HMDInjectedInfo defaultInfo].userID forKey:@"user_id"];
#endif
    
    NSDictionary *params = [mParams copy];
    
    for (NSString *key in params) {
        NSString *value = [params valueForKey:key];
        [data appendData:[[NSString stringWithFormat:@"--%@",HMD_FILE_BOUNDARY] dataUsingEncoding:NSUTF8StringEncoding]];
        [data appendData:HMD_NEW_LINE];
        [data appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=%@", key] dataUsingEncoding:NSUTF8StringEncoding]];
        [data appendData:HMD_NEW_LINE];
        [data appendData:HMD_NEW_LINE];
        [data appendData:[[NSString stringWithFormat:@"%@", value] dataUsingEncoding:NSUTF8StringEncoding]];
        [data appendData:HMD_NEW_LINE];
    }
    [data appendData:[[NSString stringWithFormat:@"--%@", HMD_FILE_BOUNDARY] dataUsingEncoding:NSUTF8StringEncoding]];
    [data appendData:HMD_NEW_LINE];
    
    NSArray *arr = [request.filePath componentsSeparatedByString:@"/"];
    NSString *fileName = request.filePath;
    if (arr.count > 0) {
        fileName = arr[arr.count - 1];
    }
    
    NSString *param;
	NSString *alogTimeInfo=@"";
    NSString *crashUUID = @"";
#if !RANGERSAPM
	//Add extra start/end time info of alog content Only in crash/exception case
	if([request.logType isEqualToString:@"alog"] && [request.scene isEqualToString:@"crash"] && [fileName containsString:@".alog"]) {
		NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:request.filePath error:nil];
		if (fileAttributes != nil) {
			//Extract start_time from alog filename whose format is 'prefix_yyyyMMdd_HHmmss.alog'
			NSUInteger timeLoc = [fileName rangeOfString:@".alog" options:NSBackwardsSearch].location - 15;
            // double insurance
            if (timeLoc > 0 && timeLoc < [fileName length]) {
                NSString *timeInfo= [fileName substringWithRange:NSMakeRange(timeLoc, 15)];
                NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                [dateFormatter setDateFormat:@"yyyyMMdd_HHmmss"];
                NSTimeInterval createTime = [[dateFormatter dateFromString:timeInfo] timeIntervalSince1970];
                //Extract last modified time of file as end_time
                NSTimeInterval lastModified = [[fileAttributes objectForKey:NSFileModificationDate] timeIntervalSince1970];
                //timestamp unit is ms
                NSString *startTime = [NSString stringWithFormat:@"%qu", (long long)(createTime * 1000.0)];
                NSString *endTime = [NSString stringWithFormat:@"%qu", (long long)(lastModified * 1000.0)];
                alogTimeInfo = [NSString stringWithFormat:@" ; start_time=\"%@\"; end_time=\"%@\"", startTime, endTime];
            }
		}
	}
#else
    if ([request.scene isEqualToString:@"crash"] && [request.logType isEqualToString:@"coredump"]) {
        if ([fileName hasPrefix:@"cd-"] && [fileName hasSuffix:@".zip"]) {
            NSString *uuid = [[fileName stringByReplacingOccurrencesOfString:@"cd-" withString:@""] stringByReplacingOccurrencesOfString:@".zip" withString:@""];
            crashUUID = [NSString stringWithFormat:@" ; uuid=\"%@\"", uuid];
        }
    }
#endif
    // 请求上报时间，服务端在解析文件时，暂时无法获取到请求时间。因此，这里增加了event_time来描述当前请求的时间。
    int64_t currentTimeIntervalInMS = (int64_t)([[NSDate date] timeIntervalSince1970] * 1000);
    if(request.commonParams.count > 0) {
        param = [NSString stringWithFormat:@"Content-Disposition: form-data; event_time=\"%lld\"; name=\"file\"; filename=\"%@\"; logtype=\"%@\"; scene=\"%@\"; env=\"params.txt\"%@%@", currentTimeIntervalInMS, fileName, request.logType, request.scene?:@"unknown", alogTimeInfo, crashUUID];
    } else {
        param = [NSString stringWithFormat:@"Content-Disposition: form-data; event_time=\"%lld\"; name=\"file\"; filename=\"%@\"; logtype=\"%@\"; scene=\"%@\"%@%@", currentTimeIntervalInMS, fileName, request.logType, request.scene?:@"unknown", alogTimeInfo, crashUUID];
    }
    [data appendData:[param dataUsingEncoding:NSUTF8StringEncoding]];
    [data appendData:HMD_NEW_LINE];
    [data appendData:HMD_NEW_LINE];
    [data appendData:[NSData dataWithContentsOfFile:request.filePath]];
    [data appendData:HMD_NEW_LINE];
    
    //env params
    if (request.commonParams.count > 0) {
        [data appendData:[[NSString stringWithFormat:@"--%@", HMD_FILE_BOUNDARY] dataUsingEncoding:NSUTF8StringEncoding]];
        [data appendData:HMD_NEW_LINE];
        [data appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"; logtype=\"env\";", @"params.txt", @"params.txt"] dataUsingEncoding:NSUTF8StringEncoding]];
        [data appendData:HMD_NEW_LINE];
        [data appendData:HMD_NEW_LINE];
        [data appendData:[NSJSONSerialization dataWithJSONObject:request.commonParams options:0 error:nil]];
        [data appendData:HMD_NEW_LINE];
    }
    [data appendData:[[NSString stringWithFormat:@"--%@--",HMD_FILE_BOUNDARY] dataUsingEncoding:NSUTF8StringEncoding]];
    
    HMDNetworkUploadModel *uploadModel = [HMDNetworkUploadModel new];
    uploadModel.uploadURL = uploadURLString;
    uploadModel.data = data;
    uploadModel.headerField = urlRequest.allHTTPHeaderFields;
    uploadModel.isManualTriggered = request.byUser;
    
    [self realUploadFileWithRequest:request model:uploadModel needResponse:isAlogUpload];
}

- (void)realUploadFileWithRequest:(nonnull HMDFileUploadRequest *)request model:(nonnull HMDNetworkUploadModel *)model needResponse:(BOOL)needResponse {
    if (needResponse) {
        [[HMDNetworkManager sharedInstance] uploadWithModel:model callBackWithResponse:^(NSError *error, id data, NSURLResponse *response) {
            
            NSMutableDictionary *responseDict = [NSMutableDictionary dictionary];
            if ([response isKindOfClass:NSHTTPURLResponse.class]) {
                NSDictionary *header = [(NSHTTPURLResponse *)response allHeaderFields];
                NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
                [responseDict setValue:@(statusCode) forKey:@"status_code"];
                
                if ([request.logType isEqualToString:@"alog"] && header && [header hmd_hasKey:@"X-Tt-Logid"]) {
                    [responseDict setObject:[header hmd_stringForKey:@"X-Tt-Logid"] forKey:@"X-Tt-Logid"];
                }
            } else if (response && hmd_log_enable()) {
                HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"%@", @"Heimdallr HTTP response is not NSHTTPURLResponse");
            }
            
            BOOL isSuccess = !error;
            if (isSuccess) {
                @try {
                    NSDictionary * jsonObj = nil;
                    if ([data isKindOfClass:[NSData class]]) {
                        jsonObj = [(NSData *)data hmd_jsonObject:&error];
                    }
                    [responseDict setValue:jsonObj forKey:@"result"];
                    if (response) {
                        [responseDict setValue:@YES forKey:@"has_response"];
                    }
                } @catch (NSException *exception) {
                } @finally {
                }
                
#if RANGERSAPM
                NSString *message = [[responseDict hmd_dictForKey:@"result"] hmd_stringForKey:@"message"];
#else
                NSString *message = nil;
#endif
                NSString *errMessage = [[responseDict hmd_dictForKey:@"result"] hmd_stringForKey:@"errmsg"];
                if (![message isEqualToString:@"success"] && ![errMessage isEqualToString:@"success"]) {
                    isSuccess = NO;
                }
            }
            if (request.finishBlock) request.finishBlock(isSuccess, [responseDict copy]);
            
        }];
    } else {
        [[HMDNetworkManager sharedInstance] uploadWithModel:model callback:^(NSError *error, id jsonObj) {
            BOOL isSuccess = !error;
            if (isSuccess) {
                if ([jsonObj isKindOfClass:[NSDictionary class]]) {
                    NSString * message = [[(NSDictionary *)jsonObj hmd_dictForKey:@"result"] hmd_stringForKey:@"errmsg"];
                    if (![message isEqualToString:@"success"]) {
                        isSuccess = NO;
                    }
                }
            }
            if (request.finishBlock) request.finishBlock(isSuccess, jsonObj);
        }];
    }
}

@end
