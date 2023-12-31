//
//  ACCRecorderAudioModeViewController.h
//  CameraClient-Pods-AwemeCore
//
//  Created by liujinze on 2021/10/15.
//

#import <UIKit/UIKit.h>
#import "ACCRecordLayoutGuide.h"
#import "ACCLightningRecordAnimationView.h"
#import <CreationKitArch/ACCRecordMode.h>
#import "ACCRecorderBackgroundManagerProtocol.h"

@protocol ACCAudioModeRecordFlowDelegate <NSObject>

- (BOOL)audioButtonAnimationShouldBegin:(id<ACCCaptureButtonAnimationProtocol>)animationView;
- (void)audioButtonAnimationDidBegin:(id<ACCCaptureButtonAnimationProtocol>)animationView;
- (void)audioButtonAnimationDidEnd:(id<ACCCaptureButtonAnimationProtocol>)animationView;
- (void)audioButtonAnimationDidMoved:(CGPoint)touchPoint;

@end

@interface ACCRecorderAudioModeViewController : UIViewController

@property (nonatomic, strong, nullable) ACCRecordMode *recordMode;
@property (nonatomic, copy, nullable) void (^goNext)(void);
@property (nonatomic, copy, nullable) void (^close)(void);
@property (nonatomic, copy, nullable) void (^changeColor)(void);
@property (nonatomic, copy, nullable) void (^audioViewDidApear)(void);
@property (nonatomic, copy, nullable) void (^showGuide)(UIView *backgroundView);
@property (nonatomic, copy, nullable) void (^removeGuideBubble)(void);
@property (nonatomic, strong) ACCRecordLayoutGuide * _Nullable layoutGuide;
@property (nonatomic, strong, readonly) ACCLightningRecordAnimationView * _Nullable recordAnimationView;
@property (nonatomic, weak, nullable) id<ACCAudioModeRecordFlowDelegate> delegate;

- (instancetype)initWithBackgroundManager:(NSObject<ACCRecorderBackgroundSwitcherProtocol> *  _Nonnull )backgroundManager;

- (void)getTemplateBackgroundImagePath:(NSString *)path completion:(void(^)(NSString * _Nullable, BOOL))completion;

- (void)getTemplateuserAvatarImagePath:(NSString *)path completion:(void(^)(NSString * _Nullable, BOOL))completion;

- (void)becomeRecordingState;

- (void)becomeNormalState;//目前没有分段录制

- (void)updateUserAvatar:(UIImage * _Nullable)image;

@end
