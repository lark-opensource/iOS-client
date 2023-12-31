//
//  AWETextTopBar.h
//  CameraClient-Pods-Aweme
//
//  Created by imqiuhang on 2021/3/16.
//

#import <UIKit/UIKit.h>
#import "AWETextToolStackView.h"

NS_ASSUME_NONNULL_BEGIN

@interface AWETextTopBar : UIView <AWETextToolStackViewProtocol>

AWETextStcikerViewUsingCustomerInitOnly;

- (instancetype)initWithBarItemIdentityList:(NSArray<AWETextStackViewItemIdentity > *)itemIdentityList NS_DESIGNATED_INITIALIZER;
@end

NS_ASSUME_NONNULL_END
