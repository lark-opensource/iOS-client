//
//  ACCNLEPublishEditorBuilder.h
//  CameraClient-Pods-Aweme
//
//  Created by raomengyun on 2021/7/9.
//

#import <Foundation/Foundation.h>
#import <CreationKitRTProtocol/ACCEditSessionBuilderProtocol.h>

NS_ASSUME_NONNULL_BEGIN

@class AWEVideoPublishViewModel;

// 直接进发布或者静默发布的EditorBuilder
// 直接进发布没有编辑页的 serviceContainer，需要自行创建以及持有 service
@interface ACCNLEPublishEditorBuilder : NSObject<ACCEditSessionBuilderProtocol>

- (instancetype)initWithPublishModel:(AWEVideoPublishViewModel *)publishModel;

@end

NS_ASSUME_NONNULL_END
