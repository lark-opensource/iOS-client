//
//  AWEVideoRangeSlider.m
//
// This code is distributed under the terms and conditions of the MIT license.
//
// Copyright (c) 2013 Andrei Solovjev - http://solovjev.com/
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "AWEVideoRangeSlider.h"
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/NSTimer+ACCAdditions.h>
#import "ACCTextReaderToastView.h"
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import "ACCConfigKeyDefines.h"

static inline CGSize screenSize()
{
    static CGSize s_screenSize;
    if(CGSizeEqualToSize(s_screenSize, CGSizeZero))
    {
        s_screenSize = [[UIScreen mainScreen] bounds].size;
    }
    
    return s_screenSize;
}

static const NSInteger DraggingBubleTextWidth = 80.0;
static const NSInteger DraggingBubleTextHeight = 23.0;

@interface AWEVideoRangeSlider() <UIGestureRecognizerDelegate>

@property (nonatomic, strong) UIView *topBorder;
@property (nonatomic, strong) UIView *bottomBorder;
@property (nonatomic, strong) UIImageView *cursor;
@property (nonatomic, strong) UIView *bgView;
@property (nonatomic, strong) ACCTextReaderToastView *textReaderHintView;
@property (nonatomic, assign) BOOL hasFeedback;
@property (nonatomic, assign) BOOL hasSelectMask;
@property (nonatomic, strong) UILabel *leftHandlerBottomLabel;
@property (nonatomic, strong) UILabel *rightHandlerBottomLabel;
@property (nonatomic, assign) CGFloat lockWidth;
@property (nonatomic, assign) BOOL thumbHandlerMoveTogetherWithGesture;
@property (nonatomic, strong) UIImpactFeedbackGenerator *feedBackGenertor NS_AVAILABLE_IOS(10_0);

@property (nonatomic, assign) BOOL holdLeftToDragOn;

@property (nonatomic, assign) BOOL holdRightToDragOn;
@property (nonatomic, assign) BOOL dragRightControlInsideRange;

@property (nonatomic, assign) BOOL rightThumbFlyToRight;
@property (nonatomic, assign) BOOL leftThumbFlyToLeft;
@property (nonatomic, assign) BOOL animationInFlight;

@property (nonatomic, assign) BOOL rightHandleInPan; // 对于fixmode模式，暂时禁掉双手同时操作
@property (nonatomic, assign) BOOL leftHandleInPan; // 对于fixmode模式，暂时禁掉双手同时操作

@property (nonatomic, strong) CAShapeLayer *cursorLayer;

@property (nonatomic, strong) NSTimer *holdDragOnSliderTimer;

@property (nonatomic, assign) CGFloat rightPositionDuringGestureChanging; // indicate the right position while a pan gesture is changing
@property (nonatomic, assign) BOOL isInSnappingRange;

@end

@implementation AWEVideoRangeSlider

#define SLIDER_BORDERS_SIZE 2.f
#define BG_VIEW_BORDERS_SIZE 3.0f


- (instancetype)initWithFrame:(CGRect)frame slideWidth:(CGFloat)slideWidth cursorWidth:(CGFloat)cursorWidth height:(CGFloat)cursorHeight hasSelectMask:(BOOL)hasSelectMask
{
    self = [super initWithFrame:frame];
    if (self) {
        _enterFromType = AWEEnterFromTypeUpload;
        _cursorCanOverrunMaxGap = NO;
        _hasSelectMask = hasSelectMask;
        
        self.topBorder = [[UIView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, SLIDER_BORDERS_SIZE)];
        self.topBorder.backgroundColor = [UIColor whiteColor];
        [self addSubview:self.topBorder];
        
        self.bottomBorder = [[UIView alloc] initWithFrame:CGRectMake(0, frame.size.height-SLIDER_BORDERS_SIZE, frame.size.width, SLIDER_BORDERS_SIZE)];
        self.bottomBorder.backgroundColor = [UIColor whiteColor];
        [self addSubview:self.bottomBorder];
        
        if (hasSelectMask) {
            _bgView = [[UIView alloc] initWithFrame:CGRectMake(slideWidth, SLIDER_BORDERS_SIZE, frame.size.width, frame.size.height - 2 * SLIDER_BORDERS_SIZE)];
            _bgView.backgroundColor = ACCResourceColor(ACCColorPrimary);
            _bgView.alpha = 0.5;
            [self addSubview:_bgView];
        }
        
        self.leftThumb = [[AWESliderLeft alloc] initWithFrame:CGRectMake(0, 0, slideWidth, frame.size.height)];
        
        self.leftThumb.useEnhancedStyle = YES;
        self.leftThumb.contentMode = UIViewContentModeLeft;
        self.leftThumb.userInteractionEnabled = YES;
        self.leftThumb.clipsToBounds = YES;
        self.leftThumb.backgroundColor = [UIColor clearColor];
        [self addSubview:self.leftThumb];
        
        
        UIPanGestureRecognizer *leftPan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleLeftPan:)];
        leftPan.delegate = self;
        [self.leftThumb addGestureRecognizer:leftPan];
        
        _leftHandlerBottomLabel = [[UILabel alloc] init];
        _leftHandlerBottomLabel.hidden = YES;
        _leftHandlerBottomLabel.textColor = ACCResourceColor(ACCUIColorConstTextInverse4);
        _leftHandlerBottomLabel.font = [ACCFont() systemFontOfSize:11 weight:ACCFontWeightMedium];
        [self addSubview:_leftHandlerBottomLabel];
        
        
        self.rightThumb = [[AWESliderRight alloc] initWithFrame:CGRectMake(0, 0, slideWidth, frame.size.height)];
        self.rightThumb.useEnhancedStyle = YES;
        self.rightThumb.contentMode = UIViewContentModeRight;
        self.rightThumb.userInteractionEnabled = YES;
        self.rightThumb.clipsToBounds = YES;
        self.rightThumb.backgroundColor = [UIColor clearColor];
        [self addSubview:self.rightThumb];
        
        _rightHandlerBottomLabel = [[UILabel alloc] init];
        _rightHandlerBottomLabel.hidden = YES;
        _rightHandlerBottomLabel.textColor = ACCResourceColor(ACCUIColorConstTextInverse4);
        _rightHandlerBottomLabel.font = [ACCFont() systemFontOfSize:11 weight:ACCFontWeightMedium];
        [self addSubview:_rightHandlerBottomLabel];
        
        self.textReaderHintView.hidden = YES;
        [self addSubview:self.textReaderHintView];
        ACCMasMaker(self.textReaderHintView, {
            make.centerX.equalTo(self.rightHandlerBottomLabel);
            make.bottom.equalTo(self.rightThumb.mas_top).offset(-5.f);
        });
        
        UIPanGestureRecognizer *rightPan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleRightPan:)];
        rightPan.delegate = self;
        [self.rightThumb addGestureRecognizer:rightPan];
        
        
        _cursor = [[UIImageView alloc] init];
        _cursor.hidden = YES;
        
        _cursorLayer = [CAShapeLayer layer];
        _cursorLayer.fillColor = ACCResourceColor(ACCUIColorConstTextInverse).CGColor;
        [_cursor.layer addSublayer:_cursorLayer];
        
        [self setCursorWidth:cursorWidth height:cursorHeight];
        [self addSubview:_cursor];
        
        UIPanGestureRecognizer *cursorPan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleCursorPan:)];
        [_cursor addGestureRecognizer:cursorPan];
        
        
        _rightPosition = self.bodyWidth;
        _leftPosition = 0;
        _cursorPosition = 0;
        
        
        _bubleText = [[UILabel alloc] init];
        _bubleText.font = [ACCFont() systemFontOfSize:13 weight:ACCFontWeightMedium];
        _bubleText.backgroundColor = [UIColor clearColor];
        _bubleText.textColor = ACCResourceColor(ACCUIColorConstTextInverse2);
        _bubleText.layer.shadowColor = ACCResourceColor(ACCUIColorConstSDInverse).CGColor;
        _bubleText.layer.shadowOffset = CGSizeMake(0, 0.5f);
        _bubleText.layer.shadowRadius = 2.0;
        
        CGFloat width = screenSize().width - 15 - 48;
        CGFloat height = 20;
        _bubleText.frame = CGRectMake(16, -29.5 - 7.5 - height / 2, width, height);
        
        [self addSubview:_bubleText];
    }
    
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame slideWidth:(CGFloat)slideWidth
{
    return [self initWithFrame:frame slideWidth:slideWidth cursorWidth:6 height:frame.size.height + 8.f hasSelectMask:NO];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    if (self.animationInFlight) {
        return;
    }
    
    CGRect frame = self.frame;
    
    if (_hasSelectMask) {
        CGRect _bgViewFrame = CGRectMake(self.leftThumb.acc_width, SLIDER_BORDERS_SIZE, frame.size.width, frame.size.height - 2 * SLIDER_BORDERS_SIZE);
        _bgView.frame = _bgViewFrame;
    }
    
    CGFloat leftX = (screenSize().width - self.bodyWidth) / 2.0 + CGRectGetWidth(self.rightThumb.bounds);
    CGFloat visualLeftPosition = self.fixedBodyWidthMode && self.holdLeftToDragOn ? 0 : _leftPosition;
    visualLeftPosition = self.leftThumbFlyToLeft ? -leftX : visualLeftPosition;
    
    self.leftThumb.center = CGPointMake(visualLeftPosition + CGRectGetMidX(self.leftThumb.bounds), CGRectGetMidY(self.bounds));
    CGFloat leftDiff = (self.leftThumb.bounds.size.width - self.leftThumb.visibleWidth) / 2.0;
    _leftHandlerBottomLabel.center = CGPointMake(self.leftThumb.center.x + leftDiff, self.leftThumb.center.y + 30);
    
    CGFloat visualRightPosition = self.fixedBodyWidthMode && self.holdRightToDragOn ? self.bodyWidth : _rightPosition;
    visualRightPosition = self.rightThumbFlyToRight ? (screenSize().width + CGRectGetMidX(self.rightThumb.bounds)) : visualRightPosition;
    self.rightThumb.center = CGPointMake(visualRightPosition + CGRectGetMaxX(self.leftThumb.bounds) + CGRectGetMidX(self.rightThumb.bounds), self.leftThumb.center.y);
    CGFloat rightDiff = (self.rightThumb.bounds.size.width - self.rightThumb.visibleWidth) / 2.0;
    _rightHandlerBottomLabel.center = CGPointMake(self.rightThumb.center.x - rightDiff, self.rightThumb.center.y + 30);
    _cursor.center = CGPointMake(_cursorPosition + CGRectGetMaxX(self.leftThumb.bounds), CGRectGetMidY(self.bounds));
    
    CGFloat leftInset = self.leftThumb.lockThumb ? 1.f : 5.f;
    self.topBorder.frame = CGRectMake(CGRectGetMaxX(self.leftThumb.frame) - leftInset, 0, CGRectGetMinX(self.rightThumb.frame) - CGRectGetMaxX(self.leftThumb.frame) + 2 * leftInset, SLIDER_BORDERS_SIZE);
    
    self.bottomBorder.frame = CGRectMake(CGRectGetMinX(self.topBorder.frame), CGRectGetMaxY(self.leftThumb.frame) - SLIDER_BORDERS_SIZE, CGRectGetWidth(self.topBorder.frame), SLIDER_BORDERS_SIZE);
    
    if (_hasSelectMask) {
        _bgView.frame = CGRectMake(CGRectGetMaxX(self.leftThumb.frame) - 5, SLIDER_BORDERS_SIZE, CGRectGetMinX(self.rightThumb.frame) - CGRectGetMaxX(self.leftThumb.frame) + 10, frame.size.height - 2 * SLIDER_BORDERS_SIZE);
    }
    
    [self bringSubviewToFront:self.cursor];
}

#pragma mark - Gestures

- (void)handleLeftPan:(UIPanGestureRecognizer *)gesture
{
    if (self.holdDragOnSliderTimer) {
        //滑动滑杆时取消持续拖动定时器, cancel the continuous drag timer when sliding the slider
        [self p_invalidSliderTimer];
    }
    
    if (self.thumbHandlerMoveTogetherWithGesture) {
        [self handleSlidePan:gesture forThumbType:AWEThumbTypeLeft];
        return;
    }
    if (self.fixedBodyWidthMode && self.rightHandleInPan) {
        return;
    }
    self.leftHandleInPan = YES;
    if (gesture.state == UIGestureRecognizerStateBegan) {
        [self gestureDidBeginByType:AWEThumbTypeLeft];
    } else if (gesture.state == UIGestureRecognizerStateChanged) {
        CGPoint translation = [gesture translationInView:self];
        _leftPosition += translation.x;

        if (self.fixedBodyWidthMode) {
            if (_leftPosition < 0) {
                if (!self.holdLeftToDragOn) {
                    self.holdLeftToDragOn = YES;
                    // 开始Hold来向左滑
                    if ([self.delegate respondsToSelector:@selector(videoRangeDidBeginHoldToChangeByType:offset:)]) {
                        [self.delegate videoRangeDidBeginHoldToChangeByType:AWEThumbTypeLeft offset:fabs(_leftPosition)];
                    }
                    _cursorPosition = 0;
                    [gesture setTranslation:CGPointZero inView:self];
                    
                    // 刚开始左控件向左滑，需要制造一个右控件向右的animation
                    if ([self.delegate respondsToSelector:@selector(videoRangeSliderShouldShowExpandAnimationByType:)] &&
                        [self.delegate videoRangeSliderShouldShowExpandAnimationByType:AWEThumbTypeLeft]) {
                        [self expandRightThumbToRight];
                    }
                    
                    return;
                }
                _cursorPosition = 0;
                [self setTimeLabelWithFeedbackCheck:YES checkMax:YES];
                [self setNeedsLayout];
                [self layoutIfNeeded]; // update frames immediately before send delegation methods
                [gesture setTranslation:CGPointZero inView:self];
                if ([self.delegate respondsToSelector:@selector(videoRangeDidHoldToChangeByOffset:movedType:)]) {
                    [self.delegate videoRangeDidHoldToChangeByOffset:fabs(_leftPosition) movedType:AWEThumbTypeLeft];
                    CGFloat leftHoldDragOffset = _leftPosition;
                    @weakify(self);
                        self.holdDragOnSliderTimer = [NSTimer acc_scheduledTimerWithTimeInterval:0.1 block:^(NSTimer * _Nonnull timer) {
                            @strongify(self);
                            [self setTimeLabelWithFeedbackCheck:YES checkMax:YES];
                            //手指停留在超出裁剪框位置时持续滑动, keep sliding when the finger stays outside the crop frame
                            [self.delegate videoRangeDidHoldToChangeByOffset:fabs(leftHoldDragOffset) movedType:AWEThumbTypeLeft];
                        } repeats:YES];
                }
                // Early return, 让delegate专心做holdLeft的变化
                return;
            } else if (_leftPosition >= 0) {
                if (self.holdLeftToDragOn) {
                    self.holdLeftToDragOn = NO;
                }
            }
        } else {
            if (_leftPosition < 0) {
                [self setTimeLabelWithFeedbackCheck:YES checkMax:YES];
            }
            _leftPosition = [self validActualLeftPositionForPosition:_leftPosition];
            if (ACCConfigEnum(kConfigInt_text_reader_multiple_sound_effects, ACCTextReaderPhase2Type) != ACCTextReaderPhase2TypeDisable && self.audioDuration > 0) { /* ***** handle snap feedback ***** */
                CGFloat validRightPosition = [self validActualLeftPositionForPosition:_rightPosition];
                CGFloat snapLeft = _leftPosition + self.bodyWidth / self.maxGap * (self.audioDuration - 0.02);
                CGFloat snapRight = _leftPosition + self.bodyWidth / self.maxGap * (self.audioDuration + 0.02);
                if (validRightPosition > snapLeft && validRightPosition < snapRight) {
                    [self p_toggleToastHidden:NO];
                    if (!self.isInSnappingRange) {
                        [self setTimeLabelWithFeedbackCheck:YES checkMax:YES];
                        [self p_vibrate];
                        self.isInSnappingRange = YES;
                    }
                } else {
                    self.isInSnappingRange = NO;
                    [self p_toggleToastHidden:YES];
                }
            }
        }
        
        if ((((self.maxGap > 0) && (self.rightPosition - self.leftPosition > self.maxGap)) && !self.fixedBodyWidthMode) ||
            ((self.minGap > 0) && (self.rightPosition - self.leftPosition < self.minGap))) {
            _leftPosition -= translation.x;
            if (!self.fixedBodyWidthMode) {
                _leftPosition = _rightPosition - self.minGap * self.bodyWidth / self.maxGap;
                if ((_rightPosition - _leftPosition) > self.bodyWidth) {
                    _leftPosition = _rightPosition - self.bodyWidth;
                }
            }
        }
    
        //滑动左右滑杆，游标跟手
        _cursorPosition = self.fixedBodyWidthMode && self.holdLeftToDragOn ? 0 : _leftPosition;
        [self setTimeLabelWithFeedbackCheck:YES];
        if (self.showSideHandlerInfo) {
            self.leftHandlerBottomLabel.text = [NSString stringWithFormat:@"%0.1fs", self.leftPosition];
            [self.leftHandlerBottomLabel sizeToFit];
        }
        [self setNeedsLayout];
        [self layoutIfNeeded]; // update frames immediately before send delegation methods
        [gesture setTranslation:CGPointZero inView:self];
        [self videoRangeChangedByThumbType:AWEThumbTypeLeft];
        
    } else if (gesture.state == UIGestureRecognizerStateEnded ||
               gesture.state == UIGestureRecognizerStateCancelled ||
               gesture.state == UIGestureRecognizerStateFailed) {
        if (gesture.state == UIGestureRecognizerStateEnded) {
            if ([self.delegate respondsToSelector:@selector(trackSliderAdjustment)]) {
                [self.delegate trackSliderAdjustment];
            }
        }
        [self p_toggleToastHidden:YES];
        self.leftHandleInPan = NO;
        if (self.fixedBodyWidthMode) {
            if (self.holdLeftToDragOn) {
                self.holdLeftToDragOn = NO;
                if ([self.delegate respondsToSelector:@selector(videoRangeDidEndHoldToChangeByType:)]) {
                    [self.delegate videoRangeDidEndHoldToChangeByType:AWEThumbTypeLeft];
                }
                self.leftPosition = 0;
//                [self restoreRightThumbBackToNormal];
//                return;
            } else if (self.leftPosition > 0) {
                self.leftPosition = 0;
            }
            [self restoreRightThumbBackToNormal];
        }
        [self gestureDidEndByType:AWEThumbTypeLeft];
    }
}

- (void)handleRightPan:(UIPanGestureRecognizer *)gesture
{
    if (self.holdDragOnSliderTimer) {
        //滑动滑杆时取消持续拖动定时器, cancel the continuous drag timer when sliding the slider
        [self p_invalidSliderTimer];
    }
    
    if (self.thumbHandlerMoveTogetherWithGesture) {
        [self handleSlidePan:gesture forThumbType:AWEThumbTypeRight];
        return;
    }
    if (self.fixedBodyWidthMode && self.leftHandleInPan) {
        return;
    }
    self.rightHandleInPan = YES;
    if (gesture.state == UIGestureRecognizerStateBegan) {
        [self gestureDidBeginByType:AWEThumbTypeRight];
        { /* ***** handle snap feedback ***** */
            self.rightPositionDuringGestureChanging = _rightPosition;
            CGFloat validRightPosition = [self validActualLeftPositionForPosition:self.rightPositionDuringGestureChanging];
            CGFloat snapLeft = _leftPosition + self.bodyWidth / self.maxGap * (self.audioDuration - 0.1);
            CGFloat snapRight = _leftPosition + self.bodyWidth / self.maxGap * (self.audioDuration + 0.1);
            self.isInSnappingRange = validRightPosition > snapLeft && validRightPosition < snapRight;
        }
    } else if (gesture.state == UIGestureRecognizerStateChanged) {
        CGPoint translation = [gesture translationInView:self];
        _rightPosition += translation.x;
        if (_rightPosition < 0) {
            _rightPosition = 0;
        }
        
        if (self.fixedBodyWidthMode) {
            if (_rightPosition > self.bodyWidth) {
//                if (self.dragRightControlInsideRange) {
//                    self.dragRightControlInsideRange = NO;
//                    _rightPosition = self.bodyWidth;
//                }
                if (!self.holdRightToDragOn) {
                    self.holdRightToDragOn = YES;
                    _cursorPosition = self.bodyWidth;
                    // 开始Hold来向左滑
                    if ([self.delegate respondsToSelector:@selector(videoRangeDidBeginHoldToChangeByType:offset:)]) {
                        [self.delegate videoRangeDidBeginHoldToChangeByType:AWEThumbTypeRight offset:fabs(_rightPosition - self.bodyWidth)];
                    }
                    [gesture setTranslation:CGPointZero inView:self];
                    if ([self.delegate respondsToSelector:@selector(videoRangeSliderShouldShowExpandAnimationByType:)] &&
                        [self.delegate videoRangeSliderShouldShowExpandAnimationByType:AWEThumbTypeRight]) {
                        [self expandLeftThumbToLeft];
                    }
                    return;
                }
                [self setTimeLabelWithFeedbackCheck:YES checkMax:YES];
                _cursorPosition = self.bodyWidth;
                if ([self.delegate respondsToSelector:@selector(videoRangeDidHoldToChangeByOffset:movedType:)]) {
                    [self.delegate videoRangeDidHoldToChangeByOffset:fabs(_rightPosition - self.bodyWidth) movedType:AWEThumbTypeRight];
                    CGFloat rightHoldDragOffset = _rightPosition - self.bodyWidth;
                    @weakify(self);
                        self.holdDragOnSliderTimer = [NSTimer acc_scheduledTimerWithTimeInterval:0.1 block:^(NSTimer * _Nonnull timer) {
                            @strongify(self);
                            [self setTimeLabelWithFeedbackCheck:YES checkMax:YES];
                            //手指停留在超出裁剪框位置时持续滑动, keep sliding when the finger stays outside the crop frame
                            [self.delegate videoRangeDidHoldToChangeByOffset:fabs(rightHoldDragOffset) movedType:AWEThumbTypeRight];
                        } repeats:YES];
                }
                [self setNeedsLayout];
                [self layoutIfNeeded]; // update frames immediately before send delegation methods
                [gesture setTranslation:CGPointZero inView:self];
                // Early return, 让delegate专心做holdLeft的变化
                return;
            } else if (_rightPosition <= self.bodyWidth) {
                if (self.holdRightToDragOn) {
                    self.holdRightToDragOn = NO;
                    if ([self.delegate respondsToSelector:@selector(videoRangeDidTransferHoldDragToInnerDragByType:)]) {
                        [self.delegate videoRangeDidTransferHoldDragToInnerDragByType:AWEThumbTypeRight];
                    }
                }
//                if (!self.dragRightControlInsideRange) {
//                    self.dragRightControlInsideRange = YES;
//                }
            }
        } else { // NOT fixedBodyWidthMode
            if (_rightPosition > self.bodyWidth) {
                [self setTimeLabelWithFeedbackCheck:YES checkMax:YES];
                _rightPosition = self.bodyWidth;
            }
            if (ACCConfigEnum(kConfigInt_text_reader_multiple_sound_effects, ACCTextReaderPhase2Type) == ACCTextReaderPhase2TypeDisable) {
                _rightPosition = [self validActualRightPositionForPosition:_rightPosition];
            } else {
                if (self.audioDuration > 0) { /* ***** handle snap feedback ***** */
                    self.rightPositionDuringGestureChanging += translation.x;
                    CGFloat validRightPosition = [self validActualLeftPositionForPosition:self.rightPositionDuringGestureChanging];
                    CGFloat snapPosition = _leftPosition + self.bodyWidth / self.maxGap * self.audioDuration;
                    CGFloat snapLeft = _leftPosition + self.bodyWidth / self.maxGap * (self.audioDuration - 0.1);
                    CGFloat snapRight = _leftPosition + self.bodyWidth / self.maxGap * (self.audioDuration + 0.1);
                    
                    if (validRightPosition > snapLeft && validRightPosition < snapRight) {
                        _rightPosition = snapPosition;
                        [self p_toggleToastHidden:NO];
                        if (!self.isInSnappingRange) {
                            [self setTimeLabelWithFeedbackCheck:YES checkMax:YES];
                            [self p_vibrate];
                            self.isInSnappingRange = YES;
                        }
                    } else {
                        self.isInSnappingRange = NO;
                        [self p_toggleToastHidden:YES];
                        _rightPosition = [self validActualRightPositionForPosition:validRightPosition];
                    }
                }
            }
        }
        
        if (_rightPosition - _leftPosition <= 0){
            _rightPosition -= translation.x;
        }
        
        if ((((self.maxGap > 0) && (self.rightPosition-self.leftPosition > self.maxGap)) && !self.fixedBodyWidthMode) ||
            ((self.minGap > 0) && (self.rightPosition-self.leftPosition < self.minGap))) {
            _rightPosition -= translation.x;
            if (!self.fixedBodyWidthMode) {
                _rightPosition = self.minGap * self.bodyWidth / self.maxGap + _leftPosition;
                if ((_rightPosition - _leftPosition) > self.bodyWidth) {
                    _rightPosition = _leftPosition + self.bodyWidth;
                }
            }
        }
        
        //滑动左右滑杆，游标跟手
        _cursorPosition = self.fixedBodyWidthMode && self.holdRightToDragOn ? self.bodyWidth : _rightPosition;
        [self setTimeLabelWithFeedbackCheck:YES];
        if (self.showSideHandlerInfo) {
            self.rightHandlerBottomLabel.text = [NSString stringWithFormat:@"%0.1fs", self.rightPosition];
            [self.rightHandlerBottomLabel sizeToFit];
        }
        [self setNeedsLayout];
        [self layoutIfNeeded]; // update frames immediately before send delegation methods
        [gesture setTranslation:CGPointZero inView:self];
        [self videoRangeChangedByThumbType:AWEThumbTypeRight];
        
    }  else if (gesture.state == UIGestureRecognizerStateEnded ||
                gesture.state == UIGestureRecognizerStateCancelled ||
                gesture.state == UIGestureRecognizerStateFailed) {
        if (gesture.state == UIGestureRecognizerStateEnded) {
            if ([self.delegate respondsToSelector:@selector(trackSliderAdjustment)]) {
                [self.delegate trackSliderAdjustment];
            }
        }
        [self p_toggleToastHidden:YES];
        self.rightHandleInPan = NO;
        if (self.fixedBodyWidthMode) {
            if (self.holdRightToDragOn) {
                self.holdRightToDragOn = NO;
                if ([self.delegate respondsToSelector:@selector(videoRangeDidEndHoldToChangeByType:)]) {
                    [self.delegate videoRangeDidEndHoldToChangeByType:AWEThumbTypeRight];
                }
                self.rightPosition = self.bodyWidth;
//                [self restoreLeftThumbBackToNormal];
//                return;
            } else if (self.rightPosition < self.bodyWidth) {
                // 设置右位置为bodywidth
                self.rightPosition = self.bodyWidth;
                self.cursorPosition = self.bodyWidth;
            }
            [self restoreLeftThumbBackToNormal];
        }
        [self gestureDidEndByType:AWEThumbTypeRight];
    }
}

- (void)handleSlidePan:(UIPanGestureRecognizer *)gesture forThumbType:(AWEThumbType)thumbType
{
    switch (gesture.state) {
        case UIGestureRecognizerStateBegan:
        {
            [self gestureDidBeginByType:thumbType];
        }
            break;
        case UIGestureRecognizerStateChanged:
        {
            CGPoint translation = [gesture translationInView:self];
            _leftPosition += translation.x;
            _rightPosition += translation.x;

            _leftPosition = [self validActualLeftPositionForPosition:_leftPosition];
            _rightPosition = [self validActualRightPositionForPosition:_rightPosition];

            if (_rightPosition - _leftPosition != self.lockWidth) {
                if (_leftPosition <= 0) {
                    _leftPosition = 0;
                    _rightPosition = self.lockWidth;
                }
                if (_rightPosition >= self.bodyWidth) {
                    _leftPosition = _rightPosition - self.lockWidth;
                    _rightPosition = self.bodyWidth;
                }
//                if (_leftPosition + self.lockWidth > self.bodyWidth) {
//                    _leftPosition = _rightPosition - self.lockWidth;
//                }
//                if (_rightPosition - self.lockWidth < 0) {
//                    _leftPosition = 0;
//                    _rightPosition = self.lockWidth;
//                }
            }
            //滑动左右滑杆，游标跟手
            _cursorPosition = _leftPosition;
            [self setTimeLabelWithFeedbackCheck:YES];
            if (self.showSideHandlerInfo) {
                self.rightHandlerBottomLabel.text = [NSString stringWithFormat:@"%0.1fs", self.rightPosition];
                [self.rightHandlerBottomLabel sizeToFit];
            }
            [self setNeedsLayout];
            [self layoutIfNeeded]; // update frames immediately before send delegation methods
            [gesture setTranslation:CGPointZero inView:self];
            [self videoRangeChangedByThumbType:thumbType];
        }
            break;
        case UIGestureRecognizerStateEnded:
        {
            [self gestureDidEndByType:thumbType];
        }
            break;
        default:
            break;
    }
}

- (void)handleCursorPan:(UIPanGestureRecognizer *)gesture
{
    if (self.leftHandleInPan || self.rightHandleInPan) {
        return;
    }
    
    if (gesture.state == UIGestureRecognizerStateBegan) {
        [self gestureDidBeginByType:AWEThumbTypeCursor];
        
    } else if (gesture.state == UIGestureRecognizerStateChanged) {
        
        CGPoint translation = [gesture translationInView:self];
        
        if (!self.cursorCanOverrunMaxGap) {
            if (CGRectGetMaxX(self.leftThumb.frame) >= CGRectGetMidX(_cursor.frame) + translation.x) {
                _cursorPosition = _leftPosition;
            }
            
            if (CGRectGetMinX(self.rightThumb.frame) <= CGRectGetMidX(_cursor.frame) + translation.x) {
                _cursorPosition = _rightPosition;
            }
        
            if (CGRectGetMaxX(self.leftThumb.frame) < CGRectGetMidX(_cursor.frame) + translation.x &&
                CGRectGetMinX(self.rightThumb.frame) > CGRectGetMidX(_cursor.frame) + translation.x) {
                _cursorPosition += translation.x;
            }
        } else {
            if (self.leftThumb.acc_width >= CGRectGetMidX(_cursor.frame) + translation.x) {
                _cursorPosition = 0;
            }
            
            if (self.acc_width - self.rightThumb.acc_width <= CGRectGetMidX(_cursor.frame) + translation.x) {
                _cursorPosition = self.bodyWidth;
            }
            
            if (self.leftThumb.acc_width < CGRectGetMidX(_cursor.frame) + translation.x && self.acc_width - self.rightThumb.acc_width > CGRectGetMidX(_cursor.frame) + translation.x) {
                _cursorPosition += translation.x;
            }
        }
        
        [self setNeedsLayout];
        [gesture setTranslation:CGPointZero inView:self];
        [self videoRangeChangedByThumbType:AWEThumbTypeCursor];
        
    } else if (gesture.state == UIGestureRecognizerStateEnded){
        [self gestureDidEndByType:AWEThumbTypeCursor];
    }
}

- (CGFloat)validActualLeftPositionForPosition:(CGFloat)position
{
    if (ACC_FLOAT_LESS_THAN(position, 0)) {
        return 0;
    }
    return position;
}

- (CGFloat)validActualRightPositionForPosition:(CGFloat)position
{
    if (ACC_FLOAT_LESS_THAN(position, 0)) {
        return 0;
    }
    if (ACC_FLOAT_GREATER_THAN(position, self.bodyWidth)) {
        return self.bodyWidth;
    }
    return position;
}

#pragma mark - Bubble

- (void)updateTimeLabel
{
    [self setTimeLabelWithFeedbackCheck:NO];
}

- (void)updateTimeLabelFrame:(CGRect)frame forIPhoneXS:(BOOL)forIPhoneXS
{
    self.bubleText.frame = frame;
    
    if (!forIPhoneXS) {
        CGFloat x = (ACC_SCREEN_WIDTH - DraggingBubleTextWidth) / 2.0;
        CGFloat y = frame.origin.y - (DraggingBubleTextHeight - frame.size.height) / 2.0;
        self.draggingBubleText.frame = CGRectMake(x, y, DraggingBubleTextWidth, DraggingBubleTextHeight);
    }
}

- (void)setTimeLabelWithFeedbackCheck:(BOOL)checkFeedback
{
    [self setTimeLabelWithFeedbackCheck:checkFeedback checkMax:NO];
}

- (void)setTimeLabelWithFeedbackCheck:(BOOL)checkFeedback checkMax:(BOOL)checkMax
{
    CGFloat delta = [self delta];
    if (checkFeedback) {
        BOOL reachedMaxDuration = delta >= self.maxGap;
        if (reachedMaxDuration && [self.delegate respondsToSelector:@selector(checkVideoRangeHasReachedMaxDuration)]) {
            reachedMaxDuration = [self.delegate checkVideoRangeHasReachedMaxDuration];
        }
        if (delta <= self.minGap + 0.05 || reachedMaxDuration) {
            if (!self.hasFeedback) {
                self.hasFeedback = YES;
                [self p_vibrate];
                if (delta <= self.minGap + 0.05 && [self.delegate respondsToSelector:@selector(videoRangeHasReachedMinDuration)]) {
                    [self.delegate videoRangeHasReachedMinDuration];
                }
                if (reachedMaxDuration && [self.delegate respondsToSelector:@selector(videoRangeHasReachedMaxDuration)] && checkMax) {
                    [self.delegate videoRangeHasReachedMaxDuration];
                }
            }
        } else {
            self.hasFeedback = NO;
        }
    }
    if (self.enterFromType == AWEEnterFromTypeStickerSelectTime && delta <= self.minGap + 0.05) {
        // 只有在选时长界面，且达到了最小时长的情况下，调整文字颜色
        self.bubleText.attributedText = [self timeAdjustedStr];
        self.draggingBubleText.attributedText = [self timeAdjustedStr];
    } else {
        self.bubleText.text = [self trimDurationStr];
        self.draggingBubleText.text = [self trimDurationStr];
        
        // 更新frame
        [self.draggingBubleText sizeToFit];
        CGSize size = self.draggingBubleText.frame.size;
        CGRect frame = self.bubleText.frame;
        CGFloat x = (ACC_SCREEN_WIDTH - size.width - 16) / 2.0;
        CGFloat y = frame.origin.y - (DraggingBubleTextHeight - frame.size.height) / 2.0;
        self.draggingBubleText.frame = CGRectMake(x, y, size.width + 16, DraggingBubleTextHeight);
    }
    if (self.showSideHandlerInfo) {
        self.leftHandlerBottomLabel.text = [NSString stringWithFormat:@"%0.1fs", self.leftPosition];
        self.rightHandlerBottomLabel.text = [NSString stringWithFormat:@"%0.1fs", self.rightPosition];
        [self.leftHandlerBottomLabel sizeToFit];
        [self.rightHandlerBottomLabel sizeToFit];
    }
    return;
}

- (NSString *)trimDurationStr
{
    CGFloat delta = [self delta];
    if (delta > 0.01 && delta < 0.1) {
        delta = 0.1;
    }
    NSString *title = @"";
    switch (self.enterFromType) {
        case AWEEnterFromTypeUpload:
        case AWEEnterFromTypeUploadSegment: {
            title = [self rangeSliderTextFormatForDelta:delta];
            break;
        }
        case AWEEnterFromTypeStickerSelectTime: {
            title = [NSString stringWithFormat:ACCLocalizedString(@"com_mig_selected_sticker_lasts_for_1fs", nil), delta];
            break;
        }
    }
    return title;
}

- (NSString *)rangeSliderTextFormatForDelta:(double)delta
{
    return [NSString stringWithFormat:ACCLocalizedCurrentString(@"longervideo_trim_time"), [self formattedStrForDelta:delta]];
}

- (NSString *)formattedStrForDelta:(CGFloat)delta
{
    NSString *str = @"";
    if (delta > 60.5) {
        int trimmedDelta = (int)(round(delta));
        int mins = trimmedDelta / 60;
        int secs = trimmedDelta - mins * 60;
        str = [NSString stringWithFormat:@"%02d:%02d", mins, secs];
    } else {
        str = [NSString stringWithFormat:@"%.1fs", delta];
    }
    
    return str;
}

- (NSAttributedString *)timeAdjustedStr
{
    CGFloat delta = [self delta];
    NSString *timeString = [NSString stringWithFormat:ACCLocalizedString(@"com_mig_selected_sticker_lasts_for_1fs", nil), delta];
    NSMutableAttributedString *desc = [[NSMutableAttributedString alloc] initWithString:timeString];
    [desc addAttribute:NSFontAttributeName
                 value:[ACCFont() systemFontOfSize:13]
                 range:NSMakeRange(0, desc.length)];
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"1.0" options:NSRegularExpressionCaseInsensitive error:nil];
    NSArray<NSTextCheckingResult *> *result = [regex matchesInString:timeString options:0 range:NSMakeRange(0, timeString.length)];
    if (result.count > 0) {
        [desc addAttribute:NSForegroundColorAttributeName
                     value:ACCResourceColor(ACCUIColorPrimary)
                     range:result.firstObject.range];
    }
    return [desc copy];
}

- (CGFloat)delta
{
    CGFloat delta = self.rightPosition - self.leftPosition + 0.001;
    
    if (self.fixedBodyWidthMode) {
        // 在动态模式下，由delegate来提供时间
        if ([self.delegate respondsToSelector:@selector(currentlyValidDelta)]) {
            delta = [self.delegate currentlyValidDelta];
        }
    }
    
    return delta;
}

- (NSString *)trimIntervalStr{
    
    NSString *from = [self timeToStr:self.leftPosition];
    NSString *to = [self timeToStr:self.rightPosition];
    return [NSString stringWithFormat:@"%@ - %@", from, to];
}

#pragma mark - Update Indicator

- (void)showVideoIndicator
{
    self.cursor.hidden = NO;
}

- (void)hiddenVideoIndicator
{
    self.cursor.hidden = YES;
}

- (void)updateVideoIndicatorByPosition:(CGFloat)position
{
    _cursorPosition = self.bodyWidth * position / _maxGap;
    if (isnan(_cursorPosition)) {
        _cursorPosition = 0;
    }
    
    if (!self.cursorCanOverrunMaxGap) {
        if (_cursorPosition < _leftPosition) {
            _cursorPosition = _leftPosition;
        }
        
        if (_cursorPosition > _rightPosition) {
            _cursorPosition = _rightPosition;
        }
    }
    
    _cursor.center = CGPointMake(_cursorPosition + CGRectGetMaxX(self.leftThumb.bounds), CGRectGetMidY(self.bounds));
}

- (void)showSliderAreaShow:(BOOL)show animated:(BOOL)animated
{
    [UIView animateWithDuration:animated ? 0.2 : 0.0 animations:^{
        self.bgView.alpha = show ? 0.5 : 0.0;
        self.leftThumb.alpha = show ? 1.0 : 0.0;
        self.leftHandlerBottomLabel.alpha = show ? 1.0 : 0.0;
        self.rightThumb.alpha = show ? 1.0 : 0.0;
        self.rightHandlerBottomLabel.alpha = show ? 1.0 : 0.0;
        self.topBorder.alpha = show ? 1.0 : 0.0;
        self.bottomBorder.alpha = show ? 1.0 : 0.0;
    }];
}

- (void)lockSliderWidth
{
    self.leftThumb.lockThumb = YES;
    self.rightThumb.lockThumb = YES;
    self.thumbHandlerMoveTogetherWithGesture = YES;
    self.lockWidth = _rightPosition - _leftPosition;
}

- (void)unlock
{
    self.leftThumb.lockThumb = NO;
    self.rightThumb.lockThumb = NO;
    self.thumbHandlerMoveTogetherWithGesture = NO;
}

#pragma mark - Helpers

// Right Thumb
- (void)expandRightThumbToRight
{
    self.animationInFlight = YES;
    [UIView animateWithDuration:0.3 animations:^{
        self.rightThumb.frame = CGRectMake(screenSize().width , 0, CGRectGetWidth(self.rightThumb.bounds), CGRectGetHeight(self.rightThumb.bounds));
        self.topBorder.frame = CGRectMake(CGRectGetMaxX(self.leftThumb.frame) - 5, 0, CGRectGetMinX(self.rightThumb.frame) - CGRectGetMaxX(self.leftThumb.frame) + 10, SLIDER_BORDERS_SIZE);
        
        self.bottomBorder.frame = CGRectMake(CGRectGetMinX(self.topBorder.frame), CGRectGetMaxY(self.leftThumb.frame) - SLIDER_BORDERS_SIZE, CGRectGetMinX(self.rightThumb.frame) - CGRectGetMaxX(self.leftThumb.frame) + 10, SLIDER_BORDERS_SIZE);
    } completion:^(BOOL finished) {
        self.animationInFlight = NO;
    }];
    self.rightThumbFlyToRight = YES;
}

- (void)restoreRightThumbBackToNormal
{
    if (!self.fixedBodyWidthMode) {
        return;
    }
    self.animationInFlight = YES;
    [UIView animateWithDuration:0.3 animations:^{
        self.leftThumb.frame = CGRectMake(0, 0, CGRectGetWidth(self.leftThumb.bounds), CGRectGetHeight(self.leftThumb.bounds));
        self.rightThumb.frame = CGRectMake(self.bodyWidth + CGRectGetMaxX(self.leftThumb.bounds) , 0, CGRectGetWidth(self.rightThumb.bounds), CGRectGetHeight(self.rightThumb.bounds));
        self.topBorder.frame = CGRectMake(CGRectGetMaxX(self.leftThumb.frame) - 5, 0, self.bodyWidth + 10, SLIDER_BORDERS_SIZE);
        self.bottomBorder.frame = CGRectMake(CGRectGetMinX(self.topBorder.frame), CGRectGetMaxY(self.leftThumb.frame) - SLIDER_BORDERS_SIZE, self.bodyWidth + 10, SLIDER_BORDERS_SIZE);
    } completion:^(BOOL finished) {
        self.animationInFlight = NO;
    }];
    self.rightThumbFlyToRight = NO;
}

// Left Thumb
- (void)expandLeftThumbToLeft
{
    self.animationInFlight = YES;
    CGFloat leftX = (screenSize().width - self.bodyWidth) / 2.0 + CGRectGetWidth(self.rightThumb.bounds);
    [UIView animateWithDuration:0.3 animations:^{
        self.leftThumb.frame = CGRectMake(-leftX, 0, CGRectGetWidth(self.rightThumb.bounds), CGRectGetHeight(self.rightThumb.bounds));
        self.topBorder.frame = CGRectMake(CGRectGetMaxX(self.leftThumb.frame) - 5, 0, CGRectGetMinX(self.rightThumb.frame) - CGRectGetMaxX(self.leftThumb.frame) + 10, SLIDER_BORDERS_SIZE);
        self.bottomBorder.frame = CGRectMake(CGRectGetMinX(self.topBorder.frame), CGRectGetMaxY(self.leftThumb.frame) - SLIDER_BORDERS_SIZE, CGRectGetMinX(self.rightThumb.frame) - CGRectGetMaxX(self.leftThumb.frame) + 10, SLIDER_BORDERS_SIZE);
    } completion:^(BOOL finished) {
        self.animationInFlight = NO;
    }];
    self.leftThumbFlyToLeft = YES;
}

- (void)restoreLeftThumbBackToNormal
{
    if (!self.fixedBodyWidthMode) {
        return;
    }
    self.animationInFlight = YES;
    [UIView animateWithDuration:0.3 animations:^{
        self.leftThumb.frame = CGRectMake(0, 0, CGRectGetWidth(self.leftThumb.bounds), CGRectGetHeight(self.leftThumb.bounds));
        self.rightThumb.frame = CGRectMake(self.bodyWidth + CGRectGetMaxX(self.leftThumb.bounds) , 0, CGRectGetWidth(self.rightThumb.bounds), CGRectGetHeight(self.rightThumb.bounds));
        self.topBorder.frame = CGRectMake(CGRectGetMaxX(self.leftThumb.frame) - 5, 0, self.bodyWidth + 10, SLIDER_BORDERS_SIZE);
        
        self.bottomBorder.frame = CGRectMake(CGRectGetMinX(self.topBorder.frame), CGRectGetMaxY(self.leftThumb.frame) - SLIDER_BORDERS_SIZE, self.bodyWidth + 10, SLIDER_BORDERS_SIZE);
    } completion:^(BOOL finished) {
        self.animationInFlight = NO;
    }];
    self.leftThumbFlyToLeft = NO;
}

- (NSString *)timeToStr:(CGFloat)time
{
    // time - seconds
    NSInteger min = floor(time / 60);
    NSInteger sec = floor(time - min * 60);
    NSString *minStr = [NSString stringWithFormat:min >= 10 ? @"%li" : @"0%li", (long)min];
    NSString *secStr = [NSString stringWithFormat:sec >= 10 ? @"%li" : @"0%li", (long)sec];
    return [NSString stringWithFormat:@"%@:%@", minStr, secStr];
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    CGFloat insetX = 0;
    if (self.isAdapitionOptimize && self.fixedBodyWidthMode) {
        insetX = -50;
    }
    CGRect leftRect = UIEdgeInsetsInsetRect(self.leftThumb.frame, UIEdgeInsetsMake(0, insetX, 0, 0));
    CGRect rightRect = UIEdgeInsetsInsetRect(self.rightThumb.frame, UIEdgeInsetsMake(0, 0, 0, insetX));

    CGRect cursorRect = self.cursor.frame;
    CGFloat offsetL = CGRectGetMinX(_cursor.frame) - CGRectGetMaxX(self.leftThumb.frame);
    CGFloat offsetR = CGRectGetMinX(self.rightThumb.frame) - CGRectGetMaxX(_cursor.frame);
    
    if (fabs(offsetL) < 15) {
        cursorRect = UIEdgeInsetsInsetRect(self.cursor.frame, UIEdgeInsetsMake(0, 0, 0, -15));
    } else if (fabs(offsetR) < 15) {
        cursorRect = UIEdgeInsetsInsetRect(self.cursor.frame, UIEdgeInsetsMake(0, -15, 0, 0));
    } else {
        cursorRect = UIEdgeInsetsInsetRect(self.cursor.frame, UIEdgeInsetsMake(0, -13, 0, -13));
        leftRect = UIEdgeInsetsInsetRect(self.leftThumb.frame, UIEdgeInsetsMake(0, insetX, 0, -15));
        rightRect = UIEdgeInsetsInsetRect(self.rightThumb.frame, UIEdgeInsetsMake(0, -15, 0, insetX));
    }

    if (CGRectContainsPoint(cursorRect, point)) {
        if (self.cursor.hidden) {
            return nil;
        } else {
            return self.cursor;
        }
    } else if (CGRectContainsPoint(leftRect, point)) {
        return self.leftThumb;
    } else if (CGRectContainsPoint(rightRect, point)) {
        return self.rightThumb;
    }
    
    return nil;
}

#pragma mark - AWEVideoRangeSliderDelegate

- (void)gestureDidBeginByType:(AWEThumbType)type
{
    if ([self.delegate respondsToSelector:@selector(videoRangeDidBeginByType:)]) {
        [self.delegate videoRangeDidBeginByType:type];
    }
    
    [self bubleTextAnimationWithDragging:YES thumbType:type];
}

- (void)gestureDidEndByType:(AWEThumbType)type
{
    if ([self.delegate respondsToSelector:@selector(videoRangeDidEndByType:)]) {
        [self.delegate videoRangeDidEndByType:type];
    }
    
    [self bubleTextAnimationWithDragging:NO thumbType:type];
}

- (void)videoRangeChangedByThumbType:(AWEThumbType)type
{
    if ([self.delegate respondsToSelector:@selector(videoRangeDidChangByPosition:movedType:)]) {
        CGFloat position = self.leftPosition;
        
        switch (type) {
            case AWEThumbTypeLeft:
                position = self.leftPosition;
                break;
                
            case AWEThumbTypeRight:
                position = self.rightPosition;
                break;
            
            case AWEThumbTypeCursor:
                position = self.cursorPosition;
                break;
        }
    
        [self.delegate videoRangeDidChangByPosition:position movedType:type];
    }
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if ([self.delegate respondsToSelector:@selector(videoRangeIgnoreGesture)]) {
        return ![self.delegate videoRangeIgnoreGesture];
    }
    
    return YES;
}

#pragma mark - Private Methods

- (void)p_vibrate
{
    
    if (@available(iOS 10.0, *)) {
        if ([UIDevice acc_isBetterThanIPhone7]) {
            if (!self.feedBackGenertor) {
                self.feedBackGenertor = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
            }
            [self.feedBackGenertor impactOccurred];
        }
    } else {
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
    }
}

- (void)p_toggleToastHidden:(BOOL)shouldHide
{
    if (ACCConfigEnum(kConfigInt_text_reader_multiple_sound_effects, ACCTextReaderPhase2Type) == ACCTextReaderPhase2TypeDisable) {
        self.textReaderHintView.hidden = YES;
        return;
    }
    if (self.textReaderHintView.isHidden == shouldHide) {
        return;
    }
    [self.textReaderHintView.layer removeAllAnimations];
    if (shouldHide) {
        self.textReaderHintView.transform = CGAffineTransformIdentity;
        [UIView animateWithDuration:0.1 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.textReaderHintView.transform = CGAffineTransformMakeScale(0.01, 0.01);
        } completion:^(BOOL finished){
            self.textReaderHintView.hidden = YES;
        }];
    } else {
        self.textReaderHintView.transform = CGAffineTransformMakeScale(0.01, 0.01);
        [UIView animateWithDuration:0.1 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.textReaderHintView.transform = CGAffineTransformIdentity;
        } completion:^(BOOL finished){
            self.textReaderHintView.hidden = NO;
        }];
    }
}

#pragma mark - getter/setter

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    
    _rightPosition = self.bodyWidth;
    _leftPosition = 0;
    _cursorPosition = 0;
    
    
    if (_hasSelectMask) {
        CGRect _bgViewFrame = CGRectMake(self.leftThumb.acc_width, SLIDER_BORDERS_SIZE, frame.size.width, frame.size.height - 2 * SLIDER_BORDERS_SIZE);
        _bgView.frame = _bgViewFrame;
    }
    
    [self layoutSubviews];
    [self layoutIfNeeded];
}

- (CGFloat)leftPosition
{
    return _leftPosition * _maxGap / self.bodyWidth;
}

- (CGFloat)rightPosition
{
    return _rightPosition * _maxGap / self.bodyWidth;
}

- (CGFloat)cursorPosition
{
    return _cursorPosition * _maxGap / self.bodyWidth;
}

- (CGFloat)bodyWidth
{
    return CGRectGetWidth(self.bounds) - CGRectGetWidth(self.leftThumb.frame) - CGRectGetWidth(self.rightThumb.frame);
}

- (void)setMaxGap:(CGFloat)maxGap
{
    _leftPosition = 0;
    _rightPosition = self.bodyWidth;
    _cursorPosition = 0;
    _maxGap = maxGap;
}

- (void)setShowSideHandlerInfo:(BOOL)showSideHandlerInfo
{
    _showSideHandlerInfo = showSideHandlerInfo;
    self.leftHandlerBottomLabel.hidden = !showSideHandlerInfo;
    self.rightHandlerBottomLabel.hidden = !showSideHandlerInfo;
}

- (void)setMinGap:(CGFloat)minGap
{
    _leftPosition = 0;
    _rightPosition = self.bodyWidth;
    _cursorPosition = 0;
    _minGap = minGap;
}

- (void)updateActualLeftPosition:(CGFloat)leftPosition
{
    if (isnan(leftPosition)) {
        return;
    }
    _leftPosition = leftPosition;
    _cursorPosition = leftPosition;
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

- (void)updateActualRightPosition:(CGFloat)rightPosition
{
    if (isnan(rightPosition)) {
        return;
    }
    _rightPosition = rightPosition;
    
    [self setNeedsLayout];
    [self layoutIfNeeded];
    [self updateTimeLabel];
}

- (CGFloat)getActualLeftPosition
{
    return _leftPosition;
}

- (CGFloat)getActualRightPosition
{
    return _rightPosition;
}

- (CGFloat)convertActualPositionWithTime:(NSTimeInterval)time
{
    CGFloat position = (time * self.bodyWidth) / _maxGap;

    if (isnan(position) || position < 0) {
        NSAssert(NO, @"invalid position");
        return 0;
    }
    return position;
}

- (void)setCursorWidth:(CGFloat)width height:(CGFloat)height
{
    CGFloat x = CGRectGetMaxX(self.leftThumb.frame);
    CGFloat y = (CGRectGetHeight(self.leftThumb.frame) - height) / 2.0;
    _cursorPosition = _leftPosition;
    _cursor.frame = CGRectMake(x, y, width, height);
    

    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:_cursor.bounds cornerRadius:width / 2.0];
    self.cursorLayer.path = path.CGPath;
    
    _cursor.layer.shadowOffset = CGSizeMake(0, 2);
    _cursor.layer.shadowRadius = 4;
    _cursor.layer.shadowOpacity = 1.0;
    _cursor.layer.shadowColor = [[UIColor blackColor] colorWithAlphaComponent:0.4].CGColor;
    
    _cursor.userInteractionEnabled = YES;
    _cursor.backgroundColor = [UIColor clearColor];
    [self bringSubviewToFront:_cursor];
}

- (void)setIsAdapitionOptimize:(BOOL)isAdapitionOptimize
{
    _isAdapitionOptimize = isAdapitionOptimize;
    
    [self updateTimeLabelFrame:self.bubleText.frame forIPhoneXS:NO];
}

- (UILabel *)draggingBubleText
{
    if (!_draggingBubleText) {
        _draggingBubleText = [[UILabel alloc] init];
        _draggingBubleText.font = [ACCFont() systemFontOfSize:13 weight:ACCFontWeightMedium];
        _draggingBubleText.backgroundColor = [UIColor clearColor];
        _draggingBubleText.textColor = ACCResourceColor(ACCUIColorConstTextInverse2);
        _draggingBubleText.layer.shadowColor = ACCResourceColor(ACCUIColorConstSDInverse).CGColor;
        _draggingBubleText.layer.shadowOffset = CGSizeMake(0, 0.5f);
        _draggingBubleText.layer.shadowRadius = 2.0;
        _draggingBubleText.textAlignment = NSTextAlignmentCenter;
        _draggingBubleText.alpha = 0.0;
        
        CGRect frame = self.bubleText.frame;
        CGFloat x = (ACC_SCREEN_WIDTH - DraggingBubleTextWidth) / 2.0;
        CGFloat y = frame.origin.y - (DraggingBubleTextHeight - frame.size.height) / 2.0;
        _draggingBubleText.frame = CGRectMake(x, y, DraggingBubleTextWidth, DraggingBubleTextHeight);
        
        [self addSubview:_draggingBubleText];
    }
    
    return _draggingBubleText;
}

- (ACCTextReaderToastView *)textReaderHintView
{
    if (!_textReaderHintView) {
        _textReaderHintView = [[ACCTextReaderToastView alloc] initWithType:ACCTextReaderToastViewTypeLight];
        [_textReaderHintView updateTitle:@"朗读结束"];
    }
    return _textReaderHintView;
}

#pragma mark - BubleLable Animation

- (void)bubleTextAnimationWithDragging:(BOOL)isDragging thumbType:(AWEThumbType)type
{
    if (!self.isAdapitionOptimize || type == AWEThumbTypeCursor) {
        return;
    }
    
    if (isDragging) {
        [UIView animateWithDuration:0.25 animations:^{
            self.bubleText.alpha = 0.0;
            self.draggingBubleText.alpha = 1.0;
        } completion:^(BOOL finished) {
            self.bubleText.alpha = 0.0;
            self.draggingBubleText.alpha = 1.0;
        }];
    } else {
        [UIView animateWithDuration:0.25 animations:^{
            self.bubleText.alpha = 1.0;
            self.draggingBubleText.alpha = 0.0;
        } completion:^(BOOL finished) {
            self.bubleText.alpha = 1.0;
            self.draggingBubleText.alpha = 0.0;
        }];
    }
}

- (BOOL)isActive
{
    if (self.leftHandleInPan || self.rightHandleInPan) {
        return YES;
    }
    
    return NO;
}

- (void)updateSliderWithHeight:(CGFloat)height cursorHeight:(CGFloat)cursorHeight
{
    CGRect originalFrame = self.frame;
    originalFrame.size.height = height;
    self.frame = originalFrame;
    self.topBorder.frame = CGRectMake(self.topBorder.frame.origin.x, self.topBorder.frame.origin.y, self.topBorder.frame.size.width, self.topBorder.frame.size.height);
    self.bottomBorder.frame = CGRectMake(self.bottomBorder.frame.origin.x, CGRectGetMaxY(self.bounds) - self.bottomBorder.frame.size.height, self.bottomBorder.frame.size.width, self.bottomBorder.frame.size.height);
    self.leftThumb.frame = CGRectMake(self.leftThumb.frame.origin.x, self.leftThumb.frame.origin.y, self.leftThumb.frame.size.width, height);
    self.rightThumb.frame = CGRectMake(self.rightThumb.frame.origin.x, self.rightThumb.frame.origin.y, self.rightThumb.frame.size.width, height);
    [self setCursorWidth:self.cursor.frame.size.width height:cursorHeight];
    [self setNeedsDisplay];
    [self setNeedsLayout];
}

#pragma mark - life circle

- (void)p_invalidSliderTimer
{
    if (_holdDragOnSliderTimer) {
        [_holdDragOnSliderTimer invalidate];
        _holdDragOnSliderTimer = nil;
    }
}

- (void)dealloc
{
    [self p_invalidSliderTimer];
}

@end
