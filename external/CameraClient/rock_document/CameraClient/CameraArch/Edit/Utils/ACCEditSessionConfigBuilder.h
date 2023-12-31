//
//  ACCEditSessionConfigBuilder.h
//  CameraClient-Pods-Aweme
//
//  Created by geekxing on 2021/2/24.
//

#import <Foundation/Foundation.h>
@class VEEditorSessionConfig;
@class AWEVideoPublishViewModel;

NS_ASSUME_NONNULL_BEGIN

@interface ACCEditSessionConfigBuilder : NSObject

// 编辑页场景
+ (VEEditorSessionConfig *)editorSessionConfigWithPublishModel:(AWEVideoPublishViewModel *)publishModel;

// 部分场景会用到这个 config，历史原因
+ (VEEditorSessionConfig *)mvEditorSessionConfigWithPublishModel:(AWEVideoPublishViewModel *)publishModel;

// 直接进发布页的配置，历史原因
+ (VEEditorSessionConfig *)publishEditorSessionConfigWithPublishModel:(AWEVideoPublishViewModel *)publishModel;


@end

NS_ASSUME_NONNULL_END
