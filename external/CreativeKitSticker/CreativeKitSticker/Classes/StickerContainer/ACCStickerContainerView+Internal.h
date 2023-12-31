//
//  ACCStickerContainerView+Internal.h
//  CameraClient
//
//  Created by liuqing on 2020/6/15.
//

#import "ACCStickerContainerView.h"
#import "ACCStickerContainerConfigProtocol.h"
#import "ACCStickerHierarchyManager.h"
#import "ACCStickerGroupManager.h"

@interface ACCStickerContainerView ()

@property (nonatomic, strong) NSObject<ACCStickerContainerConfigProtocol> *config;
@property (nonatomic, strong) ACCStickerHierarchyManager *stickerManager;
@property (nonatomic, strong) ACCStickerGroupManager *stickerGroupManager;

@end
