//
//  DYOpenUILoadingViewProtocol.h
//  AWEUIKit-Pods-Aweme-AWEUIColor
//
//  Created by jerry on 2020/8/9.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol DYOpenUILoadingViewProtocol <NSObject>

@required

- (void)startAnimating;
- (void)stopAnimating;

- (void)dismiss;
- (void)dismissWithAnimated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
