//
//  AWEVideoRangeSlider.h
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

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
#import "AWESliderLeft.h"
#import "AWESliderRight.h"

typedef NS_ENUM(NSUInteger, AWEThumbType) {
    AWEThumbTypeLeft = 0,
    AWEThumbTypeRight,
    AWEThumbTypeCursor
};

typedef NS_ENUM(NSUInteger, AWEEnterFromType) {
    AWEEnterFromTypeUpload = 0,
    AWEEnterFromTypeUploadSegment,
    AWEEnterFromTypeStickerSelectTime
};


@protocol AWEVideoRangeSliderDelegate;

@interface AWEVideoRangeSlider : UIView

@property (nonatomic, weak) id <AWEVideoRangeSliderDelegate> delegate;
@property (nonatomic, assign) CGFloat leftPosition;
@property (nonatomic, assign) CGFloat rightPosition;
@property (nonatomic, assign) CGFloat cursorPosition;
@property (nonatomic, assign) CGFloat bodyWidth;
@property (nonatomic, assign) CGFloat audioDuration;

@property (nonatomic, strong) UILabel *bubleText;
@property (nonatomic, strong) UILabel *draggingBubleText;   // 拖拽时显示的TimeLable
@property (nonatomic, strong) AWESliderLeft *leftThumb;
@property (nonatomic, strong) AWESliderRight *rightThumb;

@property (nonatomic, assign) CGFloat maxGap;
@property (nonatomic, assign) CGFloat minGap;
@property (nonatomic, assign) BOOL cursorCanOverrunMaxGap; // defaut NO
@property (nonatomic, assign) AWEEnterFromType enterFromType;
@property (nonatomic, assign) BOOL showSideHandlerInfo; // defauts to NO
@property (nonatomic, assign) BOOL fixedBodyWidthMode;  // 是否是自适应模式，defaults to NO.
@property (nonatomic, assign) BOOL isAdapitionOptimize; // 是否是交互优化，defaults to NO.
@property (nonatomic, assign, readonly) BOOL isActive;
@property (nonatomic, assign) NSInteger rangeChangeCount;// for log

- (instancetype)initWithFrame:(CGRect)frame slideWidth:(CGFloat)slideWidth;
- (instancetype)initWithFrame:(CGRect)frame slideWidth:(CGFloat)slideWidth cursorWidth:(CGFloat)cursorWidth height:(CGFloat)cursorHeight hasSelectMask:(BOOL)hasSelectMask;

- (void)updateActualLeftPosition:(CGFloat)leftPosition;
- (void)updateActualRightPosition:(CGFloat)rightPosition;
- (CGFloat)getActualLeftPosition;
- (CGFloat)getActualRightPosition;

- (CGFloat)convertActualPositionWithTime:(NSTimeInterval)time;

- (void)showVideoIndicator;
- (void)hiddenVideoIndicator;
- (void)updateVideoIndicatorByPosition:(CGFloat)position;
- (void)updateTimeLabel;
- (void)updateTimeLabelFrame:(CGRect)frame forIPhoneXS:(BOOL)forIPhoneXS;
- (CGFloat)delta;

- (void)showSliderAreaShow:(BOOL)show animated:(BOOL)animated;

- (void)lockSliderWidth;
- (void)unlock;

- (void)updateSliderWithHeight:(CGFloat)height cursorHeight:(CGFloat)cursorHeight;

@end


@protocol AWEVideoRangeSliderDelegate <NSObject>

@optional
- (void)trackSliderAdjustment;

/// 是否响应拖动
- (BOOL)videoRangeIgnoreGesture;

/// 拖动开始
/// @param type 把手类型
- (void)videoRangeDidBeginByType:(AWEThumbType)type;

/// 拖动结束
/// @param type 把手类型
- (void)videoRangeDidEndByType:(AWEThumbType)type;

/// 选中范围改变
/// @param position 位置
/// @param type 把手类型
- (void)videoRangeDidChangByPosition:(CGFloat)position movedType:(AWEThumbType)type;

//- (BOOL)shouldBeginHoldToChangeByType:(AWEThumbType)type;

/// 拖动开始（自适应）
/// @param type 把手类型
/// @param offset 位移
- (void)videoRangeDidBeginHoldToChangeByType:(AWEThumbType)type offset:(CGFloat)offset;

/// 拖动结束（自适应）
/// @param type 把手类型
- (void)videoRangeDidEndHoldToChangeByType:(AWEThumbType)type;

- (void)videoRangeDidTransferHoldDragToInnerDragByType:(AWEThumbType)type;

//- (void)videoRangeDidTransferInnerDragToHoldDragByType:(AWEThumbType)type;

/// 选中范围改变（自适应）
/// @param offset 偏移
/// @param type 把手类型
- (void)videoRangeDidHoldToChangeByOffset:(CGFloat)offset movedType:(AWEThumbType)type;

/// 是否显示收缩动画
/// @param type 把手类型
- (BOOL)videoRangeSliderShouldShowExpandAnimationByType:(AWEThumbType)type;

/// 检测是否已到最大范围
- (BOOL)checkVideoRangeHasReachedMaxDuration;

/// 已到最小范围
- (void)videoRangeHasReachedMinDuration;

/// 已到最大范围
- (void)videoRangeHasReachedMaxDuration;

/// 有效增量
- (CGFloat)currentlyValidDelta;

@end

