//
//  BDAccountSealEvent.h
//  BDTuring
//
//  Created by bob on 2020/3/4.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class BDTuringConfig;

@interface BDAccountSealEvent : NSObject

@property (atomic, strong) BDTuringConfig *config;

+ (instancetype)sharedInstance;

- (void)collectEvent:(NSString *)event data:(nullable NSDictionary *)params;

@end

NS_ASSUME_NONNULL_END
