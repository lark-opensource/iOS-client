//
//  AWECustomPhotoStickerEditViewController.h
//  CameraClient
//
//  Created by 卜旭阳 on 2020/6/12.
//

#import <UIKit/UIKit.h>

@class AWECustomPhotoStickerEditConfig;

@interface AWECustomPhotoStickerEditViewController : UIViewController

@property(nonatomic, copy) void(^completionBlock)();

@property(nonatomic, copy) void(^clickOnRemoveBgBlock)();

@property(nonatomic, copy) void(^cancelBlock)();

- (instancetype)initWithConfig:(AWECustomPhotoStickerEditConfig *)config;

- (void)saveImageCompleted;

@end

