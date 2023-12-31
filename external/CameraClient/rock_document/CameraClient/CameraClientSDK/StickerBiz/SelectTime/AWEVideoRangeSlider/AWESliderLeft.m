//
//  AWESliderLeft.m
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

#import <CreationKitInfra/UIView+ACCMasonry.h>
#import "AWESliderLeft.h"
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <YYWebImage/UIImage+YYWebImage.h>
#import <Masonry/View+MASAdditions.h>

@interface AWESliderLeft()
@property (nonatomic, strong, readwrite) UIImageView *sliderImageView;
@property (nonatomic, strong) UIView *verticalLine;
@end

@implementation AWESliderLeft

- (void)setLockThumb:(BOOL)lockThumb
{
    if (_lockThumb != lockThumb) {
        _lockThumb = lockThumb;

        if (_lockThumb) {
            CGFloat w = 2;
            CGFloat h = self.frame.size.height;
            _sliderImageView.image = [UIImage yy_imageWithColor:self.useEnhancedStyle ? [UIColor whiteColor] : ACCResourceColor(ACCUIColorPrimary)
                                                           size:CGSizeMake(w, h)];
            _sliderImageView.acc_left = CGRectGetMaxX(self.bounds) - w;
            _sliderImageView.acc_width = w;
            _sliderImageView.layer.cornerRadius = 2;
            _sliderImageView.layer.masksToBounds = YES;
            self.verticalLine.hidden = YES;
        } else {
            UIImage *image = self.useEnhancedStyle ? ACCResourceImage(@"imgChooseLeftEnhance") : ACCResourceImage(@"imgChoseLeft");
            _sliderImageView.image = image;
            CGRect imageFrame = _sliderImageView.frame;

            imageFrame.origin.x = CGRectGetMaxX(self.bounds) - CGRectGetWidth(imageFrame);
            _sliderImageView.frame = imageFrame;
        }
    }
}

- (CGFloat)visibleWidth
{
    return self.sliderImageView.bounds.size.width;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        UIImage *image = ACCResourceImage(@"imgChoseLeft");
        _sliderImageView = [[UIImageView alloc] initWithImage:image];
        CGRect imageFrame = _sliderImageView.frame;
        imageFrame.size.height = CGRectGetHeight(frame);
        imageFrame.origin.x = CGRectGetMaxX(self.bounds) - CGRectGetWidth(imageFrame);
        _sliderImageView.frame = imageFrame;
        _sliderImageView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleLeftMargin;
        [self addSubview:_sliderImageView];
        
        [_sliderImageView addSubview:self.verticalLine];
        self.verticalLine.hidden = YES;
        ACCMasMaker(self.verticalLine, {
            make.center.equalTo(self.sliderImageView);
            make.width.equalTo(@2);
            make.height.equalTo(@12);
        });
    }
    return self;
}

- (void)setUseEnhancedStyle:(BOOL)useEnhancedStyle
{
    _useEnhancedStyle = useEnhancedStyle;
    _sliderImageView.image = useEnhancedStyle ? ACCResourceImage(@"imgChooseLeftEnhance") : ACCResourceImage(@"imgChoseLeft");
    self.verticalLine.hidden = !useEnhancedStyle || self.lockThumb;
}

- (UIView *)verticalLine
{
    if (!_verticalLine) {
        _verticalLine = [[UIView alloc] init];
        _verticalLine.backgroundColor = ACCResourceColor(ACCColorPrimary);
        _verticalLine.layer.cornerRadius = 1.f;
        _verticalLine.layer.masksToBounds = YES;
    }
    return _verticalLine;
}

@end
