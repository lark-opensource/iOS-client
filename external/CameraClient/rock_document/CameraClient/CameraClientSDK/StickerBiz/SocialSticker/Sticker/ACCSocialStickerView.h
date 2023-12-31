//
//  ACCSocialStickerView.h
//  CameraClient-Pods-Aweme-CameraResource_base
//
//  Created by qiuhang on 2020/8/5.
//

#import <UIKit/UIKit.h>
#import "ACCStickerEditContentProtocol.h"
#import "ACCSocialStickerModel.h"

NS_ASSUME_NONNULL_BEGIN

@class IESEffectModel;
@interface ACCSocialStickerView : UIView <ACCStickerEditContentProtocol>

#pragma mark - public init
/**
 @param stickerModel will copy in,  so make sure stickerModel is valid before init
 @param socialStickerUniqueId  auto creat if nil
 @return instance of SocialStickerView
 */
ACCSocialStickerViewUsingCustomerInitOnly;
- (instancetype)initWithStickerModel:(ACCSocialStickerModel *_Nonnull)stickerModel
               socialStickerUniqueId:(NSString *_Nullable)socialStickerUniqueId;

#pragma mark - getter
@property (nonatomic, strong, readonly) ACCSocialStickerModel *stickerModel;
@property (nonatomic, assign, readonly) ACCSocialStickerType stickerType;
@property (nonatomic, copy,   readonly) NSString * socialStickerUniqueId;
@property (nonatomic, copy,   readonly) NSString * currentSearchKeyword;
@property (nonatomic, strong, readonly) ACCSocialStickeMentionBindingModel * currentMentionBindingModel;

#pragma mark binding action
@property (nonatomic, copy) void (^_Nullable onSearchKeywordChanged)(void);
@property (nonatomic, copy) void (^_Nullable onMentionBindingDataChanged)(void);

- (BOOL)bindingWithMentionModel:(ACCSocialStickeMentionBindingModel *_Nullable)bindingUserModel;
- (BOOL)bindingWithHashTagModel:(ACCSocialStickeHashTagBindingModel *_Nullable)hashTagModel;

#pragma mark - transport
- (void)bindInputAccessoryView:(__kindof UIView *)accessoryView;

- (void)updateKeyboardHeight:(CGFloat)height;

- (void)transportToEditWithSuperView:(UIView *)superView
                           animation:(void (^)(void))animationBlock
                   animationDuration:(CGFloat)duration;

- (void)restoreToSuperView:(UIView *)superView
         animationDuration:(CGFloat)duration
            animationBlock:(void (^)(void))animationBlock
                completion:(void (^)(void))completion;

@property (nonatomic, copy) void (^onDidEndEditing)(void);

@end


@interface ACCSocialStickerViewViewModel : NSObject

// text view
@property (nonatomic, copy,   readonly) NSAttributedString *textPlaceholder;
@property (nonatomic, strong, readonly) UIColor  *textColor;
@property (nonatomic, strong, readonly) UIFont   *textFont;
@property (nonatomic, assign, readonly) UIEdgeInsets textViewPadding;
@property (nonatomic, strong, readonly) NSArray  *textGradientColors;
@property (nonatomic, assign, readonly) NSInteger gradientdiRect;
// icon
@property (nonatomic, strong, readonly) UIColor  *tintColor;
@property (nonatomic, strong, readonly) UIFont   *iconFont;
@property (nonatomic, copy,   readonly) NSString *iconFontGlyph;
@property (nonatomic, assign, readonly) CGFloat  iconViewLeftInset;
@property (nonatomic, strong, readonly) UIImage  *iconFontImage;
@property (nonatomic, copy  , readonly) NSString *iconURL;
// content
@property (nonatomic, assign, readonly) CGFloat contentHorizontalMinMargin;
@property (nonatomic, assign, readonly) CGFloat contentHeight;
@property (nonatomic, strong, readonly) UIColor  *backgroundColor;
@property (nonatomic, assign, readonly) CGFloat cornerRadius;
// border
@property (nonatomic, assign, readonly) CGFloat borderHeight;
// view
@property (nonatomic, assign, readonly) CGFloat viewHeight;
@property (nonatomic, assign, readonly) CGFloat textMaxWidth;
@property (nonatomic, strong) IESEffectModel *effectModel;

+ (instancetype)constModelWithSocialType:(ACCSocialStickerType)type effectModelInfo:(NSString *)effectModelExtraInfo;

@end


NS_ASSUME_NONNULL_END
