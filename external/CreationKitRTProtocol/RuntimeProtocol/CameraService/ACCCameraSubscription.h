//
//  ACCCameraSubscription.h
//  Pods
//
//  Created by liyingpeng on 2020/6/1.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ACCCameraSubscription <NSObject>

- (void)addSubscriber:(id)subscriber;

@optional
- (void)removeSubscriber:(id)subscriber;

@end

@interface ACCCameraEventPerformer : NSObject

@property (nonatomic, assign) SEL aSelector;
@property (nonatomic, copy) void(^realPerformer)(id);

+ (instancetype)performerWithSEL:(SEL)selector performer:(void(^)(id))performer;

@end

@interface ACCCameraSubscription : NSObject <ACCCameraSubscription>

- (void)performEventSelector:(SEL)aSelector realPerformer:(void(^)(id))realPerformer;
- (void)make:(ACCCameraEventPerformer *)performer;

@end

NS_ASSUME_NONNULL_END
