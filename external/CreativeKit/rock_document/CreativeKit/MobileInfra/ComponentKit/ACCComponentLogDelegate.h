//
//  ACCComponentLogDelegate.h
//  CreativeKit-Pods-Aweme
//
//  Created by Liu Deping on 2020/11/16.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ACCFeatureComponent;

@protocol ACCComponentLogDelegate <NSObject>

- (void)logComponent:(id<ACCFeatureComponent>)component selector:(SEL)aSelector duration:(NSTimeInterval)duration;

@end

NS_ASSUME_NONNULL_END
