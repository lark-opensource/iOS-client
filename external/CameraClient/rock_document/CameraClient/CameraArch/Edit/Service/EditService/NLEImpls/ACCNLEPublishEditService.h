//
//  ACCNLEPublishEditService.h
//  CameraClient-Pods-Aweme
//
//  Created by raomengyun on 2021/7/9.
//

#import <Foundation/Foundation.h>
#import <CreationKitRTProtocol/ACCEditServiceProtocol.h>

NS_ASSUME_NONNULL_BEGIN

@class AWEVideoPublishViewModel;

// 直接进发布或者静默发布的EditorBuilder
// 直接进发布没有编辑页的 serviceContainer，需要自行创建以及持有 service
@interface ACCNLEPublishEditService : NSObject<ACCEditServiceProtocol>

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithPublishModel:(AWEVideoPublishViewModel *)publishModel;

@end

NS_ASSUME_NONNULL_END
