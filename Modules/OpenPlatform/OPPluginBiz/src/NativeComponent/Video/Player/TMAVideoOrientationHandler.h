//
//  TMAVideoOrientationHandler.h
//  OPPluginBiz
//
//  Created by bupozhuang on 2019/1/3.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class TMAPlayerView;

@protocol TMAVideoOrientationDelegate <NSObject>

@property(nullable, nonatomic, weak) TMAPlayerView *targetView;
- (void)interfaceOrientation:(UIInterfaceOrientation)orientation
                isFullScreen:(BOOL)fullscreen
                  completion:(void (^)(BOOL fullScreen))completion;

@end


NS_ASSUME_NONNULL_BEGIN

@interface TMAVideoOrientationHandler : NSObject<TMAVideoOrientationDelegate>

@property(nullable, nonatomic, weak) TMAPlayerView *targetView;

@end

NS_ASSUME_NONNULL_END
