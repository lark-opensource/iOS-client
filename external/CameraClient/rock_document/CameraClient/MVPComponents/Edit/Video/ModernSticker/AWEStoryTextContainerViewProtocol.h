//
//  AWEStoryTextContainerViewProtocol.h
//  CameraClient
//
//  Created by xulei on 2020/2/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol AWEStoryTextContainerViewProtocol <NSObject>

- (void)updateTextViewsStatusWithCurrentPlayerTime:(CGFloat)currentPlayerTime isSelectTime:(BOOL)isSelectTime;

@end

NS_ASSUME_NONNULL_END
