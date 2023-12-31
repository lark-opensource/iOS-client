//
//  TSPKReleaseAPIBizInfoSubscriber.h
//  Musically
//
//  Created by bytedance on 2022/6/6.
//

#import <Foundation/Foundation.h>
#import "TSPKSubscriber.h"

@interface TSPKReleaseAPIBizInfoSubscriber : NSObject <TSPKSubscriber>

+ (nonnull instancetype)sharedInstance;

- (nullable NSDictionary *)getTimestampInfoWithDataType:(nonnull NSString *)dataType;

@end
