//
//  ACCDeallocHelper.h
//  CameraClient-Pods-Aweme
//
//  Created by Pinka on 2020/3/23.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^ACCDeallocHelperBlock)(void);

/**
 It's a helper for observing object dealloc
 */
@interface ACCDeallocHelper : NSObject

/**
 Observing the object when it will dealloc

 @param object the observed object
 @param key unique id
 @param aThis the block will be excuted after the object dealloc
 */
+ (void)attachToObject:(nonnull id)object key:(const void*)key whenDeallocDoThis:(ACCDeallocHelperBlock)aThis;

/**
 Stop observing the object

 @param object the observed object
 @param key unique id
 */
+ (void)dettachObject:(nonnull id)object key:(const void*)key;

@end

NS_ASSUME_NONNULL_END
