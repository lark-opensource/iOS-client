//
//  ACCPanelViewController.h
//  CameraClient
//
//  Created by Liu Deping on 2020/2/25.
//

#import <Foundation/Foundation.h>
#import "ACCPanelViewProtocol.h"

@protocol ACCPanelViewController;
@protocol ACCPanelAnimator;
@protocol ACCPanelViewDelegate <NSObject>

@optional
- (void)panelViewController:(id<ACCPanelViewController>)panelViewController willShowPanelView:(id<ACCPanelViewProtocol>)panelView;
- (void)panelViewController:(id<ACCPanelViewController>)panelViewController didShowPanelView:(id<ACCPanelViewProtocol>)panelView;
- (void)panelViewController:(id<ACCPanelViewController>)panelViewController willDismissPanelView:(id<ACCPanelViewProtocol>)panelView;
- (void)panelViewController:(id<ACCPanelViewController>)panelViewController didDismissPanelView:(id<ACCPanelViewProtocol>)panelView;


@end


@protocol ACCPanelViewController <NSObject>

- (void)registerObserver:(id<ACCPanelViewDelegate>)observer;

- (void)unregisterObserver:(id<ACCPanelViewDelegate>)observer;

- (void)removeAllObserver;

- (void)showPanelView:(id<ACCPanelViewProtocol>)panelView;

- (void)showPanelView:(id<ACCPanelViewProtocol>)panelView duration:(NSTimeInterval)duration;

- (void)dismissPanelView:(id<ACCPanelViewProtocol>)panelView;

- (void)dismissPanelView:(id<ACCPanelViewProtocol>)panelView duration:(NSTimeInterval)duration;

- (void)animatePanelView:(id<ACCPanelViewProtocol>)panelView withAnimator:(id<ACCPanelAnimator>)animator;

@end

NS_ASSUME_NONNULL_BEGIN

@interface ACCPanelViewController : NSObject <ACCPanelViewController>

- (instancetype)initWithContainerView:(UIView *)contaienrView;

@end

NS_ASSUME_NONNULL_END
