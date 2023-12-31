//
//  AWEExploreStickerViewController.h
//  Indexer
//
//  Created by wanghongyu on 2021/9/6.
//

#import <UIKit/UIKit.h>

@protocol IESServiceProvider;

@interface AWEExploreStickerViewController : UIViewController

@property (nonatomic, weak, nullable) id<IESServiceProvider> serviceProvider;

@end

