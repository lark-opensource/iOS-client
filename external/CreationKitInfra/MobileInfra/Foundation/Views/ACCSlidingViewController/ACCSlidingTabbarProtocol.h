//
//  AWESlidingTabbarProtocol.h
//  AWEUIKit
//
//  Created by gongyanyun  on 2018/6/22.
//

#import <Foundation/Foundation.h>
@class ACCSlidingViewController;

@protocol ACCSlidingTabbarProtocol <NSObject>

@property (nonatomic, weak) ACCSlidingViewController *slidingViewController;
@property (nonatomic, assign) NSInteger selectedIndex;

- (void)slidingControllerDidScroll:(UIScrollView *)scrollView;

@optional
- (void)updateSelectedLineFrame;
- (void)setSelectedIndex:(NSInteger)selectedIndex animated:(BOOL)animated tapped:(BOOL)tapped;

@end
