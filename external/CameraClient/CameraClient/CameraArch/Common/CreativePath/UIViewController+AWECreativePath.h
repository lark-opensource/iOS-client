//
//  UIViewController+AWECreativePath.h
//  CameraClient-Pods-Aweme
//
//  Created by Fengfanhua.byte on 2021/1/18.
//

#import <UIKit/UIKit.h>
#import "ACCCreativePage.h"

NS_ASSUME_NONNULL_BEGIN

@interface UIViewController (AWECreativePath)

@property (nonatomic, strong) UIViewController *awe_pathObserver;

@end


@interface AWECreativePathObserverViewController : UIViewController

@property (nonatomic, assign) ACCCreativePage page;
@property (nonatomic, assign, readonly) BOOL onWindow;

@end


NS_ASSUME_NONNULL_END
