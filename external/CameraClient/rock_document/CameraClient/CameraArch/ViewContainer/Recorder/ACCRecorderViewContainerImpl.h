//
//  ACCRecorderViewContainerImpl.h
//  CameraClient
//
//  Created by Liu Deping on 2020/2/25.
//

#import <Foundation/Foundation.h>
#import <CreativeKit/ACCRecorderViewContainer.h>
#import <CreationKitInfra/ACCRACWrapper.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCRecorderViewContainerImpl : NSObject <ACCRecorderViewContainer>

- (instancetype)initWithRootView:(UIView *)rootView;

@end

NS_ASSUME_NONNULL_END
