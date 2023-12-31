//
//  BDAccountSealEvent.m
//  BDTuring
//
//  Created by bob on 2020/3/4.
//

#import "BDAccountSealEvent.h"
#import "BDTuringConfig+Parameters.h"
#import "BDTuringMacro.h"
#import "BDAccountSealConstant.h"
#import "BDTuringUtility.h"
#import "BDTuringCoreConstant.h"
#import "NSObject+BDTuring.h"
#import <BDTrackerProtocol/BDTrackerProtocol.h>

@interface BDAccountSealEvent ()

@property (nonatomic, strong) dispatch_queue_t serialQueue;

@end

@implementation BDAccountSealEvent


+ (instancetype)sharedInstance {
    static BDAccountSealEvent *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [self new];
    });

    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.serialQueue = dispatch_queue_create("com.BDSeal.Event", DISPATCH_QUEUE_SERIAL);
        NSString *path = turing_sealDatabaseFile();
        if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
            [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
        }
    }
    
    return self;
}

- (void)collectEvent:(NSString *)event data:(NSDictionary *)params {
    if (![event isKindOfClass:[NSString class]] || event.length < 1) {
        return;
    }
    
    NSMutableDictionary *data = [self.config eventParameters] ?: [NSMutableDictionary new];
    [data setValue:@(turing_currentIntervalMS()) forKey:kBDTuringTime];
    [data setValue:event forKey:kBDTuringEvent];
    [data setValue:BDAccountSealEventKeyWord forKey:kBDTuringEventKeyWord];
    NSCAssert([event hasPrefix:BDAccountSealEventPrefix], @"must has prefix");
    if ([params isKindOfClass:[NSDictionary class]]) {
        [data addEntriesFromDictionary:params];
    }
    
    if (![event hasPrefix:BDAccountSealEventPrefix]) {
        event = [NSString stringWithFormat:@"%@%@",BDAccountSealEventPrefix,event];
    }
    
    dispatch_async(self.serialQueue, ^{
        [BDTrackerProtocol eventV3:event params:data];
    });
}

@end
