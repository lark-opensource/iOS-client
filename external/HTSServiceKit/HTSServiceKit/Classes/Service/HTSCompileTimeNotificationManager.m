//  HTSCompileTimeNotificationManager.m
//  HTSCompileTimeNotificationManager
//
//  Created by Huangwenchen on 2020/03/31.
//  Copyright © 2020 bytedance. All rights reserved.
//

#import "HTSCompileTimeNotificationManager.h"
#import "HTSMacro.h"
#import <mach-o/dyld.h>
#import <mach-o/getsect.h>
#import "HTSMessageCenter.h"
#import "HTSServiceCenter.h"

#ifndef __LP64__
typedef struct mach_header HTSMachHeader;
#else
typedef struct mach_header_64 HTSMachHeader;
#endif

typedef NSMutableArray<NSValue *> HTSMutablePointerArray;

@interface HTSCompileTimeNotificationManager: NSObject

@property (strong, nonatomic) NSMutableDictionary<NSString *, HTSMutablePointerArray *> * subscribers;

@end

@implementation HTSCompileTimeNotificationManager

+ (instancetype)sharedManager{
    static HTSCompileTimeNotificationManager * _instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[HTSCompileTimeNotificationManager alloc] init];
    });
    return _instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _subscribers = [[NSMutableDictionary alloc] init];
    }
    return self;
}

static NSMutableDictionary * internal_loadCompileNotifications(id observer) __attribute__((no_sanitize("address"))) {
    NSMutableDictionary * subscribers = [[NSMutableDictionary alloc] init];
    NSInteger imageCount = _dyld_image_count();
    for (uint32_t idx = 0; idx < imageCount; idx++) {
        HTSMachHeader * mh = (HTSMachHeader *)_dyld_get_image_header(idx);
        unsigned long size = 0;
        _hts_notification_pair * data = (_hts_notification_pair *)getsectiondata(mh,_HTS_SEGMENT, _HTS_NOTI_SECTION, &size);
        if (size == 0)  continue;
        uint32_t count = size / sizeof(_hts_notification_pair);
        if (count == 0) continue;
        for (NSInteger idy = 0; idy < count; idy++) {
            _hts_notification_pair pair = data[idy];
#if __has_feature(address_sanitizer)
            if(pair.name_provider == 0 || pair.logic_provider == 0) {
                continue;
            }
#endif
            _hts_notification_name_provider namePointer = (_hts_notification_name_provider)pair.name_provider;
            NSString * notificationName = namePointer();
            if (![notificationName isKindOfClass:[NSString class]]) {
                NSLog(@"Notification name must be NSString: %@",notificationName);
                assert(0);
                continue;
            }
            HTSMutablePointerArray * pointers = [subscribers objectForKey:notificationName];
            if (!pointers) {
                pointers = [[HTSMutablePointerArray alloc] init];
                [subscribers setObject:pointers forKey:notificationName];
                [[NSNotificationCenter defaultCenter] addObserver:observer selector:@selector(handleNotification:) name:notificationName object:nil];
            }
            [pointers addObject:[NSValue valueWithPointer:pair.logic_provider]];
        }
    }
    return subscribers;
}

- (void)loadCompileNotifications {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        self.subscribers = internal_loadCompileNotifications(self);
    });
}

- (void)handleNotification:(NSNotification *)notification{
    NSString * name = [notification name];
    if (!name)  return;
    HTSMutablePointerArray * pointers = [self.subscribers objectForKey:name];
    for (NSValue * value in pointers) {
        _hts_notification_logic_provider pointer = (_hts_notification_logic_provider)value.pointerValue;
        pointer(notification);
    }
}

@end

__used FOUNDATION_EXPORT void HTSLoadCompileTimeNotificationData(void){
    [[HTSCompileTimeNotificationManager sharedManager] loadCompileNotifications];
}

