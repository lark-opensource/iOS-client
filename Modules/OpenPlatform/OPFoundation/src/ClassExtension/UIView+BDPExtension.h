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

#define BDPCornerRadiusRatioNoExisted   OPCornerRadiusRatioNoExisted
#define BDPCornerRadiusRatioAlwaysCircle OPCornerRadiusRatioAlwaysCircle

@interface UIView (BDPExtension)

@property (nonatomic) CGFloat bdp_left;
@property (nonatomic) CGFloat bdp_top;
@property (nonatomic) CGFloat bdp_right;
@property (nonatomic) CGFloat bdp_bottom;
@property (nonatomic) CGFloat bdp_width;
@property (nonatomic) CGFloat bdp_height;
@property (nonatomic) CGFloat bdp_centerX;
@property (nonatomic) CGFloat bdp_centerY;
@property (nonatomic, readonly) CGFloat bdp_screenViewX;
@property (nonatomic, readonly) CGFloat bdp_screenViewY;
@property (nonatomic, readonly) CGRect bdp_screenFrame;
@property (nonatomic) CGPoint bdp_origin;
@property (nonatomic) CGSize bdp_size;
@property (nonatomic, readonly) CGRect bdp_originalFrame;

/// 通用的背景遮罩层view
+ (instancetype)bdp_dimmingView;

// Find First ViewController
- (UIViewController *)bdp_findFirstViewController;

- (BOOL)bdp_isVisible;

@end
