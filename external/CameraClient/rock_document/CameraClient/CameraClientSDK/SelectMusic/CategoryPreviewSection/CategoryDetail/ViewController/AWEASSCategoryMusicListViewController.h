//
//  AWEASSCategoryMusicListViewController.h
//  AWEStudio
//
//  Created by 李彦松 on 2018/9/12.
//  Copyright © 2018年 Bytedance. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "HTSVideoAudioSupplier.h"

@interface AWEASSCategoryMusicListViewController : UIViewController<HTSVideoAudioSupplier>

- (instancetype)initWithCategoryId:(NSString *)cid;

@end
