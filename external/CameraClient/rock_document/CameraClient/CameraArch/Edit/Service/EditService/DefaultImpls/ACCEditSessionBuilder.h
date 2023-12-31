//
//  ACCEditSessionBuilder.h
//  CameraClient
//
//  Created by haoyipeng on 2020/8/17.
//

#import <Foundation/Foundation.h>
#import <CreationKitRTProtocol/ACCEditSessionBuilderProtocol.h>

NS_ASSUME_NONNULL_BEGIN

@class ACCEditViewControllerInputData;

@interface ACCEditSessionBuilder : NSObject <ACCEditSessionBuilderProtocol>

- (instancetype)initWithPublishModel:(AWEVideoPublishViewModel *)publishModel;

@end

NS_ASSUME_NONNULL_END
