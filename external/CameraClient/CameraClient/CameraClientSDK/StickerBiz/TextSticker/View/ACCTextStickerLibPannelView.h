//
//  ACCTextStickerLibPannelView.h
//  CameraClient-Pods-Aweme
//
//  Created by 卜旭阳 on 2021/7/30.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class ACCTextStickerLibItem;
@class AWEVideoPublishViewModel;

@interface ACCTextStickerLibPannelView : UIView

@property (nonatomic, weak) AWEVideoPublishViewModel *publishViewModel;
@property (nonatomic, copy) void(^onTitleSelected)(NSString *, NSString *);
@property (nonatomic, copy) void(^onTitleExposured)(NSString *, NSString *);
@property (nonatomic, copy) void(^onGroupSelected)(NSString *);
@property (nonatomic, copy) void(^onDismiss)(BOOL);

- (void)updateWithItems:(NSArray<ACCTextStickerLibItem *> *)items;

+ (CGFloat)panelHeight;

@end

NS_ASSUME_NONNULL_END
