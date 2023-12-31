//
//  TSPKMediaNotificationObserver.h
//  Indexer
//
//  Created by bytedance on 2022/2/22.
//

#import <Foundation/Foundation.h>

@interface TSPKMediaNotificationObserver : NSObject

+ (void)setup;

+ (nullable NSDictionary *)getInfoWithDataType:(nonnull NSString *)dataType;

@end
