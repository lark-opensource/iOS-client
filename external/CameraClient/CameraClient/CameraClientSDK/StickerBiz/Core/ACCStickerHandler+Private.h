//
//  ACCStickerHandler+Private.h
//  CameraClient
//
//  Created by raomengyun on 2021/1/21.
//

#ifndef ACCStickerHandler_Private_h
#define ACCStickerHandler_Private_h

#import "ACCStickerHandler.h"

@interface ACCStickerHandler()

@property (nonatomic, copy) ACCStickerContainerView *(^stickerContainerLoader)(void);

@property (nonatomic, weak) UIView *uiContainerView;
@property (nonatomic, strong) id<ACCStickerLogger> logger;

@end

#endif /* ACCStickerHandler_Private_h */
