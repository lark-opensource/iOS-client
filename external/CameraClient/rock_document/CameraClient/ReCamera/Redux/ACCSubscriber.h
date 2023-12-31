//
//  ACCSubscriber.h
//  Pods
//
//  Created by leo on 2019/12/12.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ACCSubscriber <NSObject>
- (void)sendNext:(nullable id)value;
@end

@interface ACCSubscriber : NSObject <ACCSubscriber>
+ (instancetype)subscriberWithNext:(void (^)(id current))next;
@end

NS_ASSUME_NONNULL_END
