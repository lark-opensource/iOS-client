//
//  ACCEditServiceUtils.h
//  CameraClient-Pods-Aweme
//
//  Created by Fengfanhua.byte on 2021/1/28.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class AWEVideoPublishViewModel;
@protocol ACCEditServiceProtocol;

@interface ACCEditServiceUtils : NSObject

/// 静默发布或者直接进入发布的 EditService，后期可以与编辑页合并
+ (id<ACCEditServiceProtocol>)editServiceOnlyForPublishWithPublishModel:(AWEVideoPublishViewModel *)publishModel
                                                                   isMV:(BOOL)isMV;

/// publishTask 专用 EditService，后期可以与编辑页合并
+ (id<ACCEditServiceProtocol>)editServiceForPublishTaskWithPublishModel:(AWEVideoPublishViewModel *)publishModel;

+ (void)dismissPreviewEdge:(id<ACCEditServiceProtocol>)editService
              publishModel:(AWEVideoPublishViewModel *)publishModel;

@end

NS_ASSUME_NONNULL_END
