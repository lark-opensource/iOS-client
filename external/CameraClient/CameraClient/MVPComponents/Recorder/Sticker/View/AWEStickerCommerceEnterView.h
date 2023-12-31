//
//  AWEStickerCommerceEnterView.h
//  Pods
//
//  Created by 郭祁 on 2019/6/9.
//

#import <UIKit/UIKit.h>

@class IESEffectModel;

@interface AWEStickerCommerceEnterView : UIView

@property (nonatomic, strong, readonly) UIButton *enterButton;
@property (nonatomic, strong, readonly) IESEffectModel *effectModel;

- (void)updateStickerDataWithEffectModel:(IESEffectModel *)effectModel;

@end
