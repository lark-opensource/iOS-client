//
//  ACCNLEEditService.h
//  CameraClient-Pods-Aweme
//
//  Created by geekxing on 2021/1/19.
//

#import <Foundation/Foundation.h>
#import <CreationKitRTProtocol/ACCEditServiceProtocol.h>
@class ACCEditViewControllerInputData;
@protocol IESContainerProtocol;

NS_ASSUME_NONNULL_BEGIN

@interface ACCNLEEditService : NSObject<ACCEditServiceProtocol>
- (void)configResolver:(id<IESServiceProvider>)resolver;
@end

NS_ASSUME_NONNULL_END
