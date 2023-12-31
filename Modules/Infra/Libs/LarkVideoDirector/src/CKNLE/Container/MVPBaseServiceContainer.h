//
//  MVPBaseServiceContainer.h
//  MVP
//
//  Created by liyingpeng on 2020/12/30.
//

#import <Foundation/Foundation.h>
#import <IESInject/IESInject.h>
#import <CreativeKit/ACCBarItemContainerView.h>
#import "LVDCameraService.h"
NS_ASSUME_NONNULL_BEGIN

@interface MVPBaseServiceContainer : IESStaticContainer<ACCBarItemContainerViewDelegate>

@property (nonatomic, weak) UIViewController* camera;
@property (nonatomic, weak) UIViewController* editing;
@property (nonatomic, assign) LVDCameraType cameraType;
@property (nonatomic, assign) BOOL inCamera;
@property (nonatomic, assign) BOOL isExport; // 标记是否是导出场景，如果是，则不执行 dismiss 回调
@property (nonatomic, weak) id<LVDVideoEditorControllerDelegate> editorDelegate;

+ (instancetype)sharedContainer;

- (void)clickSendBtn:(UIControl *)sender;

@end

NS_ASSUME_NONNULL_END
