//
//  ACCStickerGestureComponentProtocol.h
//  Pods
//
//  Created by chengfei xiao on 2019/10/21.
//

#import <Foundation/Foundation.h>

#import "AWEEditorStickerGestureViewController.h"

NS_ASSUME_NONNULL_BEGIN

@protocol ACCStickerGestureComponentMessageProtocol <NSObject>

@end

@protocol ACCStickerGestureComponentProtocol <NSObject>

@property (nonatomic, strong) AWEEditorStickerGestureViewController *stickerGestureController;

//pan手势
- (void)startPanOperation;
- (void)finishPanOperation;
- (void)startNewStickerPanOperation;
- (void)finishNewStickerPanOperation;

@end

NS_ASSUME_NONNULL_END
