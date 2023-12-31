//
//  ACCSocialStickerEditToolbarItemView.h
//  CameraClient-Pods-Aweme
//
//  Created by qiuhang on 2020/8/11.
//

#import <UIKit/UIKit.h>
#import <CreationKitArch/ACCTextInputServiceProtocol.h>
#import <CreationKitArch/ACCChallengeModelProtocol.h>

NS_ASSUME_NONNULL_BEGIN

@interface  ACCSocialStickerEditToolbarBaseItemCell: UICollectionViewCell

+ (CGSize)maxContentDisplaySize;
- (void)setup NS_REQUIRES_SUPER;

@end

@interface ACCSocialStickerEditToobarMentionItemCell: ACCSocialStickerEditToolbarBaseItemCell

+ (CGSize)sizeWithUser:(id<ACCUserModelProtocol> _Nullable)userModel;

- (void)configWithUser:(id<ACCUserModelProtocol> _Nullable)userModel
            isSelected:(BOOL)isSelected;

@end

@interface ACCSocialStickerEditToolbarHashTagItemCell: ACCSocialStickerEditToolbarBaseItemCell

+ (CGSize)sizeWithHashTag:(id<ACCChallengeModelProtocol> _Nullable)hashTagModel;

- (void)configWithHashTag:(id<ACCChallengeModelProtocol> _Nullable)hashTagModel;

@end

NS_ASSUME_NONNULL_END
