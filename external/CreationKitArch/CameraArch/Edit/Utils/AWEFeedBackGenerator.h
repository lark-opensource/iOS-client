//
//  AWEFeedBackGenerator.h
//  AWEStudio
//
//  Created by hanxu on 2018/11/25.
//  Copyright © 2018 bytedance. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface AWEFeedBackGenerator : NSObject

+ (AWEFeedBackGenerator *)sharedInstance;
- (void)doFeedback;
- (void)doFeedback:(UIImpactFeedbackStyle)style;

@end

NS_ASSUME_NONNULL_END
