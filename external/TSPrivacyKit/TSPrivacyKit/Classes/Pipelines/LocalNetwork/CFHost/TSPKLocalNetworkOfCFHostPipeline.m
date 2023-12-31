//
//  TSPKLocalNetworkOfCFHostPipeline.m
//  Baymax_MusicallyTests
//
//  Created by admin on 2022/6/14.
//

#import "TSPKLocalNetworkOfCFHostPipeline.h"
#include <BDFishhook/BDFishhook.h>
#include <arpa/inet.h>
#import "TSPKFishhookUtils.h"

static NSString *const CFHostStartInfoResolutionStr = @"CFHostStartInfoResolution";
#pragma mark - CFHostStartInfoResolution

static Boolean
(*tspk_old_CFHostStartInfoResolution)(CFHostRef theHost, CFHostInfoType info, CFStreamError *__nullable error);

Boolean
tspk_new_CFHostStartInfoResolution(CFHostRef theHost, CFHostInfoType info, CFStreamError *__nullable error)
{
    @autoreleasepool {
        //TODO: not able to fuse
        BOOL success = tspk_old_CFHostStartInfoResolution(theHost, info, error);
        
        NSString *networkAddress;
        
        CFRetain(theHost);
        switch (info) {
            case kCFHostAddresses:
            {
                // from hostName to ip address
    //            NSString *type = @"kCFHostAddresses";
                CFArrayRef hostNames = CFHostGetNames(theHost, NULL);
                NSArray *array = (__bridge NSArray *)hostNames;

                for (NSString *hostName in array) {
                    networkAddress = hostName;
                    break;
                }
            }
            break;
            case kCFHostNames:
            {
                // from IP address to hostName
    //            NSString *type = @"kCFHostNames";
                CFArrayRef addressArray = CFHostGetAddressing(theHost, nil);
                if (addressArray && CFArrayGetCount(addressArray) > 0) {
                    NSArray *sockaddrArray = (__bridge NSArray *)addressArray;
                    for (NSData *sockaddrData in sockaddrArray) {
                        struct sockaddr_in *sa_in = (struct sockaddr_in *)[sockaddrData bytes];
                        if (sa_in != NULL) {
                            const char *ipAddress = inet_ntoa(sa_in->sin_addr);
                            if (ipAddress != NULL) {
                                networkAddress = [NSString stringWithUTF8String:ipAddress];
                                break;
                            }
                        }
                    }
                }
            }
            break;
            case kCFHostReachability:
                break;
            default:
                break;
        }

        CFRelease(theHost);
        
        [TSPKLocalNetworkOfCFHostPipeline handleAPIAccess:CFHostStartInfoResolutionStr networkAddress:networkAddress];

        return success;
    }
}

@implementation TSPKLocalNetworkOfCFHostPipeline

+ (NSString *)pipelineType
{
    return TSPKPipelineLocalNetworkOfCFHost;
}

+ (NSArray<NSString *> * _Nullable)stubbedCAPIs
{
    return @[CFHostStartInfoResolutionStr];
}

+ (NSString *)stubbedClass
{
    return nil;
}

+ (void)preload {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        struct bd_rebinding startInfoResolution;
        startInfoResolution.name = [CFHostStartInfoResolutionStr UTF8String];
        startInfoResolution.replacement = tspk_new_CFHostStartInfoResolution;
        startInfoResolution.replaced = (void *)&tspk_old_CFHostStartInfoResolution;

        struct bd_rebinding rebs[] = {
            startInfoResolution
        };
        __attribute__((unused)) int flag = tspk_rebind_symbols(rebs, 1);
    });
}

@end
