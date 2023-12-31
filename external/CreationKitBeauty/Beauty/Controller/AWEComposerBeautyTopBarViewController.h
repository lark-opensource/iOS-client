//
//  AWEComposerBeautyTopBarViewController.h
//  CameraClient
//
//  Created by HuangHongsen on 2019/10/31.
//

#import <UIKit/UIKit.h>
#import <CreationKitBeauty/ACCBeautyUIConfigProtocol.h>

@protocol AWEComposerBeautyTopBarViewControllerDelegate <NSObject>

- (void)composerBeautyTopBarDidTapBackButton;

- (void)composerBeautyTopBarDidSelectTabAtIndex:(NSInteger)index;

- (void)composerBeautyTopBarDidTapResetButton;

@optional
- (void)composerBeautyTopBarDidSwitch:(BOOL)isOn isManually:(BOOL)isManually;

@end

@interface AWEComposerBeautyTopBarViewController : UIViewController

@property (nonatomic, weak) id<AWEComposerBeautyTopBarViewControllerDelegate> delegate;
@property (nonatomic, strong, readonly) UIButton *resetButton;
@property (nonatomic, strong, readonly) UIButton *backButton; // unknown caller
@property (nonatomic, strong, readonly) UILabel *detailTitleLabel; // unknown caller
@property (nonatomic, strong, readonly) UICollectionView *collectionView;
@property (nonatomic, copy, readonly) NSArray<NSString *> *titles;
@property (nonatomic, assign) CGFloat itemHeight;
@property (nonatomic, assign, readonly) NSInteger selectedIndex;
@property (nonatomic, strong, readonly) id<ACCBeautyUIConfigProtocol> uiConfig;
@property (nonatomic, assign) BOOL hideResetButton;
@property (nonatomic, assign) BOOL autoAlignCenter;
@property (nonatomic, assign) BOOL hideSelectUnderline;

- (instancetype)initWithTitles:(NSArray<NSString *> *)titles;

- (void)showSubItemsWithTitle:(NSString *)title duration:(NSTimeInterval)duration;

- (void)updateWithTitles:(NSArray<NSString *> *)titles;

- (void)updateUIConfig:(id<ACCBeautyUIConfigProtocol>)uiConfig;

- (void)selectItemAtIndex:(NSInteger)index;

- (void)updateResetButtonToDisabled:(BOOL)disabled;

- (void)setResetButtonHidden:(BOOL)hidden;

- (void)setFlagDotHidden:(BOOL)hidden atIndex:(NSInteger)index;

/// new animation
- (void)showCollectionToTitleWithTitle:(NSString *)title duration:(NSTimeInterval)duration;
- (void)showTitleToSubTitleWithSubTitle:(NSString *)title duration:(NSTimeInterval)duration;
- (void)showSubTitleToTitleWithTitle:(NSString *)title duration:(NSTimeInterval)duration;
- (void)showTitleToCollectionWithDuration:(NSTimeInterval)duration;
/// end

@end
