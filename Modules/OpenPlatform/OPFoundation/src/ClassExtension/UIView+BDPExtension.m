//
// Copyright 2009-2011 Facebook
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import "UIView+OPExtension.h"
#import "UIView+BDPExtension.h"

@implementation UIView (BDPExtension)

#pragma mark - Factory

+ (instancetype)bdp_dimmingView
{
    return [UIView op_dimmingView];
}

#pragma mark - Style

- (CGFloat)bdp_left {
    return [self op_left];
}

- (void)setBdp_left:(CGFloat)x {
    [self setOp_left:x];
}

- (CGFloat)bdp_top {
    return [self op_top];
}

- (void)setBdp_top:(CGFloat)y {
    [self setOp_top:y];
}

- (CGFloat)bdp_right {
    return [self op_right];
}

- (void)setBdp_right:(CGFloat)right {
    [self setOp_right:right];
}

- (CGFloat)bdp_bottom {
    return [self op_bottom];
}

- (void)setBdp_bottom:(CGFloat)bottom {
    [self setOp_bottom:bottom];
}

- (CGFloat)bdp_centerX {
    return [self op_centerX];
}

- (void)setBdp_centerX:(CGFloat)centerX {
    [self setOp_centerX:centerX];
}

- (CGFloat)bdp_centerY {
    return [self op_centerY];
}

- (void)setBdp_centerY:(CGFloat)centerY {
    [self setOp_centerY:centerY];
}

- (CGFloat)bdp_width {
    return [self op_width];
}

- (void)setBdp_width:(CGFloat)width {
    [self setOp_width:width];
}

- (CGFloat)bdp_height {
    return [self op_height];
}

- (void)setBdp_height:(CGFloat)height {
    [self setOp_height:height];
}

- (CGFloat)bdp_screenViewX {
    return [self op_screenViewX];
}

- (CGFloat)bdp_screenViewY {
    return [self op_screenViewY];
}

- (CGRect)bdp_screenFrame {
    return [self op_screenFrame];
}

- (CGPoint)bdp_origin {
    return [self op_origin];
}

- (void)setBdp_origin:(CGPoint)origin {
    [self setOp_origin:origin];
}

- (CGSize)bdp_size {
    return [self op_size];
}

- (void)setBdp_size:(CGSize)size {
    [self setOp_size:size];
}

- (CGRect)bdp_originalFrame {
    return [self op_originalFrame];
}

- (UIViewController *)bdp_findFirstViewController
{
    return [self op_findFirstViewController];
}

- (BOOL)bdp_isVisible {
    return [self op_isVisible];
}

@end
