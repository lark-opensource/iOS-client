//
//  ACCTextReaderSoundEffectsSelectionView.m
//  CameraClient-Pods-Aweme
//
//  This is a transparent view, which is used to prevent superview's gestures from being called.
//
//  Created by Daniel on 2021/2/8.
//

#import "ACCTextReaderSoundEffectsSelectionView.h"

#import <CreativeKit/ACCMacros.h>

#import "ACCTextReaderSoundEffectsSelectionBottomView.h"

@interface ACCTextReaderSoundEffectsSelectionView () <UIGestureRecognizerDelegate>

@property (nonatomic, strong) ACCTextReaderSoundEffectsSelectionBottomView *bottomView;
@property (nonatomic, strong) UITapGestureRecognizer *tapGesture;

@end

@implementation ACCTextReaderSoundEffectsSelectionView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self p_setup];
    }
    return self;
}

- (void)dealloc
{
    [self p_removeObservers];
}

#pragma mark - Private Methods

- (void)p_setup
{
    [self p_addObservers];
    self.tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(p_handleTapGesture:)];
    self.tapGesture.delegate = self;
    [self addGestureRecognizer:self.tapGesture];
}

- (void)p_addObservers
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(p_handleKeyboardWillHideNotification:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

- (void)p_removeObservers
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)p_handleKeyboardWillHideNotification:(NSNotification *)notification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    CGFloat frameHeight = kACCTextReaderSoundEffectsSelectionBottomViewHeight + ACC_IPHONE_X_BOTTOM_OFFSET;
    CGRect frame = CGRectMake(0,
                              self.frame.size.height,
                              ACC_SCREEN_WIDTH,
                              frameHeight);
    self.bottomView = [[ACCTextReaderSoundEffectsSelectionBottomView alloc] initWithFrame:frame
                                                                                     type:ACCTextReaderSoundEffectsSelectionBottomViewTypeNormal
                                                                    isUsingOwnAudioPlayer:YES];
    @weakify(self);
    self.bottomView.getTextReaderModelBlock = ^AWETextStickerReadModel * _Nonnull {
        @strongify(self);
        return ACCBLOCK_INVOKE(self.getTextReaderModelBlock);
    };
    self.bottomView.didTapFinishCallback = ^(NSString * _Nonnull audioFilePath, NSString * _Nonnull speakerID, NSString * _Nonnull speakerName) {
        @strongify(self);
        [UIView animateWithDuration:0.1
                         animations:^{
            CGRect newFrame = self.bottomView.frame;
            newFrame.origin.y = self.frame.size.height;
            self.bottomView.frame = newFrame;
            self.bottomView.alpha = 0.0f;
        } completion:^(BOOL finished) {
            ACCBLOCK_INVOKE(self.didTapFinishCallback, audioFilePath, speakerID, speakerName);
        }];
    };
    self.bottomView.didSelectSoundEffectCallback = ^(NSString * _Nullable audioFilePath, NSString * _Nullable audioSpeakerID) {
        @strongify(self);
        ACCBLOCK_INVOKE(self.didSelectSoundEffectCallback, audioFilePath, audioSpeakerID);
    };
    [self.bottomView setupUI];
    
    [self addSubview:self.bottomView];
//    [self layoutIfNeeded];
    [UIView animateWithDuration:0.35
                     animations:^{
        CGRect newFrame = CGRectMake(0,
                                     self.frame.size.height - frameHeight,
                                     self.frame.size.width,
                                     self.bottomView.frame.size.height);
        self.bottomView.frame = newFrame;
//        [self layoutIfNeeded];
    }];
}

- (void)p_handleTapGesture:(UITapGestureRecognizer *)gesture
{
    [self.bottomView didTapFinishButton:nil];
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    CGPoint touchPoint = [touch locationInView:self];
    return !CGRectContainsPoint(self.bottomView.frame, touchPoint);
}

@end
