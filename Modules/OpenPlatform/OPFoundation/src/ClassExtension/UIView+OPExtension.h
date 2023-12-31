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

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

FOUNDATION_EXTERN const CGFloat OPCornerRadiusRatioNoExisted;
FOUNDATION_EXTERN const CGFloat OPCornerRadiusRatioAlwaysCircle;

@interface UIView (OPExtension)

@property (nonatomic) CGFloat op_left;
@property (nonatomic) CGFloat op_top;
@property (nonatomic) CGFloat op_right;
@property (nonatomic) CGFloat op_bottom;
@property (nonatomic) CGFloat op_width;
@property (nonatomic) CGFloat op_height;
@property (nonatomic) CGFloat op_centerX;
@property (nonatomic) CGFloat op_centerY;
@property (nonatomic, readonly) CGFloat op_screenViewX;
@property (nonatomic, readonly) CGFloat op_screenViewY;
@property (nonatomic, readonly) CGRect op_screenFrame;
@property (nonatomic) CGPoint op_origin;
@property (nonatomic) CGSize op_size;
@property (nonatomic, readonly) CGRect op_originalFrame;

/// 通用的背景遮罩层view
+ (instancetype)op_dimmingView;

// Find First ViewController
- (UIViewController *)op_findFirstViewController;

- (BOOL)op_isVisible;

@end
