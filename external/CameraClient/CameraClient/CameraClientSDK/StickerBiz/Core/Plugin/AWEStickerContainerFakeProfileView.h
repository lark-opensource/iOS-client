//
//  AWEStickerContainerFakeProfileView.h
//  Pods
//
//  Created by resober on 2019/7/1.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ACCMusicModelProtocol;
@interface AWEStickerContainerFakeProfileView : UIView
@property (nonatomic, strong, readonly) UIView *bottomContainerView;
@property (nonatomic, strong, readonly) UIView *rightContainerView;
- (instancetype)initWithNeedIgnoreRTL:(BOOL)ignoreRTL;
- (void)updateMusicCoverWithMusicModel:(id<ACCMusicModelProtocol>)model;
- (CGFloat)bottomContainerTopMargin;
@end
NS_ASSUME_NONNULL_END
