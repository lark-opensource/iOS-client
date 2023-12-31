//
//  BDWebImageStartUpTask.m
//  BDWebImage
//
//  Created on 2020/4/10.
//
#import <BDStartUp/BDStartUpGaia.h>
#import <BDStartUp/BDApplicationInfo.h>
#import "BDWebImageStartUpTask.h"
#import "BDStartUpImageURLFilter.h"
#import <BDWebImage/BDWebImage.h>

static const NSUInteger BDStartUpWebImageDiskSizeLimit = 256 * 1024 * 1024;
static const NSUInteger BDStartUpWebImageDiskAgeLimit = 7 * 24 * 60 * 60;
static const NSUInteger BDStartUpWebImageMemorySizeLimit = 256 * 1024 * 1024;
static const NSUInteger BDStartUpWebImageMemoryAgeLimit = 12 * 60 * 60;

BDAppAddStartUpTaskFunction() {
    [[BDWebImageStartUpTask sharedInstance] scheduleTask];
}

@implementation BDWebImageStartUpTask

+ (instancetype)sharedInstance {
    static BDWebImageStartUpTask *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [self new];
    });

    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.priority = BDStartUpTaskPriorityDefault;
        self.urlFilter = [BDStartUpImageURLFilter new];
    }
    
    return self;
}

- (void)startWithApplication:(UIApplication *)application
                    delegate:(id<UIApplicationDelegate>)delegate
                     options:(NSDictionary *)launchOptions {
    [BDWebImageManager sharedManager].urlFilter = self.urlFilter;
}

@end

