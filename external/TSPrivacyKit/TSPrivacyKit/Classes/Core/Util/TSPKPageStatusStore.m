//
//  TSPKPageStatusStore.m
//  Musically
//
//  Created by ByteDance on 2022/8/19.
//

#import "TSPKPageStatusStore.h"
#import <ByteDanceKit/ByteDanceKit.h>
#import "TSPrivacyKitConstants.h"
#import "TSPKLock.h"

@interface TSPKPageStatusStore ()

@property (nonatomic, strong) id<TSPKLock> lock;
@property (nonatomic, strong) NSMutableDictionary <NSString *, NSNumber *> *pageStatusInfo; // value is according to enum TSPKPageStatus
@property (nonatomic, copy) NSArray *caredPages;

@end

@implementation TSPKPageStatusStore

+ (instancetype)shared
{
    static TSPKPageStatusStore *store;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        store = [[TSPKPageStatusStore alloc] init];
    });
    return store;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _lock = [TSPKLockFactory getLock];
        _pageStatusInfo = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)addObserver {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handlePageStatusChangeNotification:) name:TSPKViewWillAppear object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handlePageStatusChangeNotification:) name:TSPKViewWillDisappear object:nil];
}

- (void)handlePageStatusChangeNotification:(NSNotification *)notification
{
    NSString *pageName = [notification.userInfo btd_stringValueForKey:TSPKPageNameKey];
    
    BOOL isCaredPage = [self.caredPages containsObject:pageName];
    
    if (!isCaredPage) {
        return;
    }
    
    NSString *notificationName = notification.name;
    
    // avoid block main thread
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self.lock lock];
        if ([notificationName isEqualToString:TSPKViewWillAppear]) {
            self.pageStatusInfo[pageName] = @(TSPKPageStatusAppear);
        } else if ([notificationName isEqualToString:TSPKViewWillDisappear]) {
            self.pageStatusInfo[pageName] = @(TSPKPageStatusDisappear);
        }
        [self.lock unlock];
    });
}

- (void)setConfigs:(NSArray *__nullable)configs {
    self.caredPages = configs.copy;
}

- (TSPKPageStatus)pageStatus:(NSString *)pageName {
    [self.lock lock];
    TSPKPageStatus status = [self.pageStatusInfo btd_integerValueForKey:pageName default:TSPKPageStatusUnknown];
    [self.lock unlock];

    return status;
}

@end
