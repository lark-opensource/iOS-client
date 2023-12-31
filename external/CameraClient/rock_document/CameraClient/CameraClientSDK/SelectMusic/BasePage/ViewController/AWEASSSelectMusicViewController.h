//
//  AWEASSSelectMusicViewController.h
//  AWEStudio
//
//  Created by 旭旭 on 2018/8/31.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import "ACCSelectMusicViewControllerProtocol.h"

#import <CameraClient/ACCSelectMusicProtocol.h>
#import <CameraClient/ACCSelectAlbumAssetsProtocol.h>
#import <CameraClient/ACCSelectMusicStudioParamsProtocol.h>


@interface AWEASSSelectMusicViewController : UIViewController <
ACCSelectMusicComponetCommonProtocol,
ACCSelectMusicStudioParamsProtocol,
ACCViewControllerEmptyPageHelperProtocol>

@property (class, nonatomic, assign) BOOL hasInstance;

@property (nonatomic, copy) NSString *createId;
@property (nonatomic, copy) void(^updatePublishModelCategoryIdBlock)(NSString *);

- (UIEdgeInsets)emptyPageEdgeInsets;
- (UIView *)emptyPageBelowView;
- (void)emptyPagePrimaryButtonTapped;
@end
