//
//  BDImageCollectionViewController.h
//  BDWebImage_Example
//
//  Created by 陈奕 on 2020/4/2.
//  Copyright © 2020 Bytedance.com. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDImageCollectionViewController : UIViewController

@property (nonatomic, assign) NSInteger index;
@property (nonatomic, copy) NSArray *imageUrls;

@end

NS_ASSUME_NONNULL_END
