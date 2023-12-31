//
//  ACCPanelViewProtocol.h
//  CameraClient
//
//  Created by Liu Deping on 2020/2/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ACCPanelViewProtocol <NSObject>

- (void *)identifier;

- (CGFloat)panelViewHeight;

@optional

- (void)transitionStart;

- (void)transitionEnd;

- (void)panelWillShow;
- (void)panelDidShow;
- (void)panelWillDismiss;
- (void)panelDidDismiss;


@end

NS_ASSUME_NONNULL_END
