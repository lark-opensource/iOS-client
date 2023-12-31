//
//  AWEAudioWaveformView.m
//  Aweme
//
//  Created by 旭旭 on 2017/11/8.
//  Copyright © 2017年 Bytedance. All rights reserved.
//

#import "AWEAudioWaveformView.h"
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/UIColor+CameraClientResource.h>

static const CGFloat kAWEAudioWaveformWidthScaling = 1;
static const CGFloat kAWEAudioWaveformHeightScaling = 0.85;
extern CGFloat kAWEAudioWaveformBackgroundHeight;

@interface AWEAudioWaveformView()

@property (nonatomic, strong) NSArray *filteredSamples;//数据数组
@property (nonatomic, strong) AVAsset *asset;

@property (nonatomic, strong) UIColor *hasRecordedColor;//已经录制过的音段颜色
@property (nonatomic, strong) UIColor *playingColor;//播放时颜色
@property (nonatomic, strong) UIColor *toBePlayedColor;//将要被播放的颜色
@property (nonatomic, strong) UIColor *notPlayedColor;//不需要播放的颜色

@end

@implementation AWEAudioWaveformView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        
        _toBePlayedLocation = 1;
        
        _hasRecordedColor = ACCUIColorFromRGBA(0x0FFCF5, 0.9);
        _playingColor = ACCUIColorFromRGBA(0xAAD75F, 1.0);
        _toBePlayedColor = ACCUIColorFromRGBA(0xFACE15, 0.9);
        _notPlayedColor = ACCResourceColor(ACCUIColorSDTertiary2);
    }
    return self;
}

- (void)setPlayingLocation:(CGFloat)playingLocation
{
    if (playingLocation < self.toBePlayedLocation) {
        _playingLocation = playingLocation;
        [self setNeedsDisplay];
    }
}

- (void)drawRect:(CGRect)rect
{
    if (!self.filteredSamples) {
        return;
    }
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextScaleCTM(context, kAWEAudioWaveformWidthScaling, kAWEAudioWaveformHeightScaling);
    CGFloat xOffset = self.bounds.size.width - (self.bounds.size.width * kAWEAudioWaveformWidthScaling);
    CGFloat yOffset = self.bounds.size.height - (self.bounds.size.height * kAWEAudioWaveformHeightScaling);
    
    CGContextTranslateCTM(context, xOffset / 2, yOffset / 2);
    
    [self drawWithStartLocation:0 endLocation:self.hasRecordedLocation rect:rect filterSamples:self.filteredSamples context:context color:self.hasRecordedColor];
    [self drawWithStartLocation:self.hasRecordedLocation endLocation:self.playingLocation rect:rect filterSamples:self.filteredSamples context:context color:self.playingColor];
    [self drawWithStartLocation:self.playingLocation endLocation:self.toBePlayedLocation rect:rect filterSamples:self.filteredSamples context:context color:self.toBePlayedColor];
    [self drawWithStartLocation:self.toBePlayedLocation endLocation:1 rect:rect filterSamples:self.filteredSamples context:context color:self.notPlayedColor];
}

- (void)drawWithStartLocation:(CGFloat)startLocation endLocation:(CGFloat)endLocation rect:(CGRect)rect filterSamples:(NSArray *)filteredSamples context:(CGContextRef)context color:(UIColor *)color
{
    CGFloat midY = CGRectGetMidY(rect);
    NSUInteger count = filteredSamples.count;
    CGMutablePathRef halfPath1 = CGPathCreateMutable();
    CGPathMoveToPoint(halfPath1, NULL, startLocation * count, midY);
    for (NSUInteger i = startLocation * count; i < endLocation * count; i++) {
        if (i >= count) {
            break;
        }
        float sample = [filteredSamples[i] floatValue];
        CGPathAddLineToPoint(halfPath1, NULL, i, midY - sample);
    }
    CGPathAddLineToPoint(halfPath1, NULL, endLocation * count, midY);
    CGMutablePathRef fullPath1 = CGPathCreateMutable();
    CGPathAddPath(fullPath1, NULL, halfPath1);
    CGAffineTransform transform1 = CGAffineTransformIdentity;
    transform1 = CGAffineTransformTranslate(transform1, 0, CGRectGetHeight(rect));
    transform1 = CGAffineTransformScale(transform1, 1.0, -1.0);
    CGPathAddPath(fullPath1, &transform1, halfPath1);
    CGContextAddPath(context, fullPath1);
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextDrawPath(context, kCGPathFill);
    CGPathRelease(halfPath1);
    CGPathRelease(fullPath1);
}

@end
