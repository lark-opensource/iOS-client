//
//  TSPKAPICostTimeManager.h
//  TT2
//
//  Created by bytedance on 2022/4/20.
//

#import <Foundation/Foundation.h>
#import "TSPKSubscriber.h"

@interface TSPKAPICostTimeManager : NSObject <TSPKSubscriber>

+ (nonnull instancetype)sharedInstance;

@end
