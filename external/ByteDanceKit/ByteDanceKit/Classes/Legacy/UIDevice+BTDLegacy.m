//
//  UIDevice+BTDLegacy.m
//  ByteDanceKit
//
//  Created by bytedance on 2020/7/23.
//

#import "UIDevice+BTDLegacy.h"
#import <AdSupport/AdSupport.h>

static BOOL optimizeIDFXEnabled__ = YES;
static NSString *const kTTIDFAStrKey = @"com.bytedanceKit.kTTIDFAStrKey";
static NSString *const kTTIDFVStrKey = @"com.bytedanceKit.kTTIDFVStrKey";

static dispatch_queue_t get_idfa_queue() {
    static dispatch_queue_t queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = dispatch_queue_create("com.bytedance.idfa", DISPATCH_QUEUE_SERIAL);
    });
    return queue;
}

@interface BTDIDFACache : NSObject

+ (instancetype)sharedInstance;

@property(atomic, copy) NSString *idfaString;
@property(atomic, copy) NSString *idfvString;

@end

@implementation BTDIDFACache

+ (instancetype)sharedInstance {
    static BTDIDFACache *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

@end

@implementation UIDevice (BTDLegacy)

+ (void)btd_optimizeIDFXEnabled:(BOOL)enable {
    optimizeIDFXEnabled__ = enable;
}

+ (NSString*)btd_idfaString {
    if (optimizeIDFXEnabled__) {
        NSString *result = [BTDIDFACache sharedInstance].idfaString;
        if (result.length == 0) {
            result = [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
            dispatch_async(get_idfa_queue(), ^{
                [BTDIDFACache sharedInstance].idfaString = result;
            });
        }
        return result;
    } else {
        return [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
    }
}

+ (NSString *)btd_idfvString {
    if (optimizeIDFXEnabled__) {
        NSString *result = [BTDIDFACache sharedInstance].idfvString;
        if (result.length == 0) {
            result = [[UIDevice currentDevice].identifierForVendor UUIDString];
            dispatch_async(get_idfa_queue(), ^{
                [BTDIDFACache sharedInstance].idfvString = result;
            });
        }
        return result;
    } else {
        return [[UIDevice currentDevice].identifierForVendor UUIDString];
    }
}


@end
