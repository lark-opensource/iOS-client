//
//  AWELyricStickerPanelView.h
//  AWEStudio-Pods-Aweme
//
//  Created by Liu Deping on 2019/10/8.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ACCMusicModelProtocol;
@class IESEffectModel, AWEStoryColor;

@interface AWELyricStickerPanelView : UIView

- (instancetype)initWithFrame:(CGRect)frame
               selectEffectId:(nullable NSString *)effectId
                        color:(nullable UIColor *)color
                    isKaraoke:(BOOL)isKaraoke
               viewController:(UIViewController *)viewController;

- (void)updateWithEffectModels:(NSArray<IESEffectModel *> *)effectModels;
- (void)updateWithMusicModel:(id<ACCMusicModelProtocol>)musicModel enableClip:(BOOL)enableClip;
- (void)resetStickerPanelState;

@property (nonatomic, assign) BOOL showing;
@property (nonatomic, copy) void (^showHandler)(void);
@property (nonatomic, copy) void (^dismissHandler)(void);
@property (nonatomic, copy) void (^clickMusicNameHandler)(void);
@property (nonatomic, copy) void (^clickClipMusicHandler)(void);
@property (nonatomic, copy) void (^selectColorHandler)(AWEStoryColor *selectColor);
@property (nonatomic, copy) void (^selectStickerStyleHandler)(IESEffectModel * _Nullable effectModel, AWEStoryColor *_Nullable selectColor, NSError * _Nullable error);
@property (nonatomic, strong, readonly) IESEffectModel *firstEffectModel;
@property (nonatomic, copy) NSString *creationId;
@property (nonatomic, copy) NSString *shootWay;
@property (nonatomic, strong, readonly) IESEffectModel *currentEffectModel;
@property (nonatomic, strong, readonly) AWEStoryColor *currentSelectColor;
@property (nonatomic, assign, readonly) BOOL isEmptyEffect;
@property (nonatomic, assign) BOOL disableChangeMusic;
 
- (void)show;
- (void)showWithEffectId:(NSString *)effectId color:(UIColor *)color;
- (void)dismiss;
- (void)hide:(void(^)(BOOL finished))completion;

@end

NS_ASSUME_NONNULL_END
