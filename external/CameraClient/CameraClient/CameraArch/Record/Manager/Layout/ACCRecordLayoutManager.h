//
//  ACCRecordLayoutManager.h
//  Pods
//
//  Created by Shen Chen on 2020/3/30.
//

#import <Foundation/Foundation.h>
#import "ACCRecordLayoutGuide.h"
#import "AWEStudioVideoProgressView.h"
#import "AWECaptureButtonAnimationView.h"
#import "ACCLayoutContainerProtocolD.h"

NS_ASSUME_NONNULL_BEGIN

@interface ACCRecordLayoutManager : NSObject <ACCLayoutContainerProtocolD>
@property (nonatomic, weak) UIView *interactionView;
@property (nonatomic, weak) UIView *rootView;
@property (nonatomic, weak) UIView *modeSwitchView;
@property (nonatomic, weak) UIView *stickerContainerView; // to be responsible for handling sticker's gestures
@property (nonatomic, weak) UIView *recordButtonSwitchView;

@end

NS_ASSUME_NONNULL_END
