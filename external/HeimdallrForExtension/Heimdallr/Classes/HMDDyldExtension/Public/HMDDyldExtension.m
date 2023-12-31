//
//  HMDDyldExtension.m
//  Pods
//
//  Created by APM on 2022/9/1.
//

#import "HMDDyldExtension.h"
#import "dlfcn.h"

static NSString * const kHMDAppDylibPath = @"AppDylibPath";
static long long const kHMDInterval = 30;

@implementation HMDDyldExtension

+ (NSData *)jsonDataForDictionary:(NSDictionary *)dict {
    NSData *jsonData = nil;
    if ([NSJSONSerialization isValidJSONObject:dict]) {
        @try {
            jsonData = [NSJSONSerialization dataWithJSONObject:dict options:0 error:nil];
        } @catch (NSException *exception) {
            
        }
    }
    return jsonData;
}

+(void)preloadDyldWithGroupID:(NSString *)appGroupID finishBlock:(void (^)(HMDDyldPreloadInfo *_Nullable))finishBlock{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError *error = nil;
        NSFileManager *manager = [NSFileManager defaultManager];
        NSURL *groupURL = [manager containerURLForSecurityApplicationGroupIdentifier:appGroupID];
        NSURL *fileURL = [groupURL URLByAppendingPathComponent:kHMDAppDylibPath];
        NSData *data = [NSData dataWithContentsOfURL:fileURL];
        if(data){
            NSDictionary *preload = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
            if([preload isKindOfClass:[NSDictionary class]]){
                id lastTimeObj = [preload objectForKey:@"time"];
                NSTimeInterval lastTime = [lastTimeObj isKindOfClass:[NSNumber class]] ? [lastTimeObj doubleValue] : 0;
                id appImagesObj = [preload objectForKey:@"appImages"];
                NSArray *appImages = [appImagesObj isKindOfClass:[NSArray class]] ? appImagesObj : nil;
                if(![appImages isKindOfClass:[NSArray class]]){
                    error = [NSError errorWithDomain:@"HMDDyldExtensionErrorType" code:HMDDyldExtensionErrorDataTypeError userInfo:@{NSLocalizedFailureReasonErrorKey:@"data type error", NSLocalizedDescriptionKey:@"data type error"}];
                    if(finishBlock){
                        HMDDyldPreloadInfo *info = [[HMDDyldPreloadInfo alloc] initWithError:error];
                        finishBlock(info);
                    }
                    return;
                }
                NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970];
                if(currentTime - lastTime < kHMDInterval){
                    error = [NSError errorWithDomain:@"HMDDyldExtensionErrorType" code:HMDDyldExtensionErrorShortInterval userInfo:@{NSLocalizedFailureReasonErrorKey:@"too short interval", NSLocalizedDescriptionKey:@"too short interval"}];
                    if(finishBlock){
                        HMDDyldPreloadInfo *info = [[HMDDyldPreloadInfo alloc] initWithError:error];
                        finishBlock(info);
                    }
                    return;
                }
                NSString *path = [[NSBundle mainBundle] bundlePath];
                NSRange range = [path rangeOfString:@".app/"];
                if(range.location != NSNotFound){
                    NSString *prefix = [path substringToIndex:range.location+range.length];
                    for(NSString *p in appImages)
                    {
                        if([p isKindOfClass:[NSString class]]){
                            NSString *libPath = [prefix stringByAppendingString:p];
                            if([manager fileExistsAtPath:libPath]){
                                dlopen([libPath UTF8String], RTLD_LAZY);
                            }
                        }
                    }
                    currentTime = [[NSDate date] timeIntervalSince1970];
                    NSMutableDictionary *newPreload = [preload mutableCopy];
                    [newPreload setObject:[NSNumber numberWithDouble:currentTime] forKey:@"time"];
                    NSData *newData = [self jsonDataForDictionary:newPreload];
                    [newData writeToURL:fileURL atomically:YES];
                } else{
                    error = [NSError errorWithDomain:@"HMDDyldExtensionErrorType" code:HMDDyldExtensionErrorPathError userInfo:@{NSLocalizedFailureReasonErrorKey:@"invalid path", NSLocalizedDescriptionKey:@"invalid path"}];
                }
                
            } else{
                error = [NSError errorWithDomain:@"HMDDyldExtensionErrorType" code:HMDDyldExtensionErrorDataTypeError userInfo:@{NSLocalizedFailureReasonErrorKey:@"data type error", NSLocalizedDescriptionKey:@"data type error"}];
            }
        } else{
            error = [NSError errorWithDomain:@"HMDDyldExtensionErrorType" code:HMDDyldExtensionErrorNoData userInfo:@{NSLocalizedFailureReasonErrorKey:@"fail to read valid data", NSLocalizedDescriptionKey:@"fail to read valid data"}];
        }
        if(finishBlock){
            HMDDyldPreloadInfo *info = [[HMDDyldPreloadInfo alloc] initWithError:error];
            finishBlock(info);
        }
    });
}

@end
