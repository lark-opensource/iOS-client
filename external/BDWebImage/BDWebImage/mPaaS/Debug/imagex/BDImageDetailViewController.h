//
//  BDImageDetailViewController.h
//  BDWebImage_Example
//
//  Created by 陈奕 on 2020/4/2.
//  Copyright © 2020 Bytedance.com. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef enum : NSUInteger {
    BDImageDetailTypeStatic,
    BDImageDetailTypeAnim,
} BDImageDetailType;

@interface BDImageDetailViewController : UIViewController

@property(nonatomic, copy)NSString *url;
@property(nonatomic, copy)NSString *record;
@property (nonatomic, assign) BDImageDetailType showType;

@end

NS_ASSUME_NONNULL_END
