//
//  ACCServiceBindable.h
//  CreativeKit-Pods-Aweme
//
//  Created by Howie He on 2021/6/16.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol IESServiceProvider;

@protocol ACCServiceBindable <NSObject>

- (void)bindServices:(id<IESServiceProvider>)serviceProvider;

@end

NS_ASSUME_NONNULL_END
