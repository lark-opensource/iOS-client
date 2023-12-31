//
//  ACCMusicSearchSugViewControllerProtocol.h
//  AWEStudio-Pods-Aweme
//
//  Created by xiaojuan on 2020/9/6.
//

#import "ACCMusicEnumDefines.h"
#import "ACCMusicCommonSearchBarProtocol.h"

#ifndef ACCMusicSearchSugViewControllerProtocol_h
#define ACCMusicSearchSugViewControllerProtocol_h

typedef void (^AWESearchSugKeywordDidTapBlock)(NSString *keyword);

@protocol ACCMusicSearchSugViewControllerProtocol <NSObject>
@property (nonatomic, copy) AWESearchSugKeywordDidTapBlock sugTapBlock;
@property (nonatomic, copy) AWESearchSugKeywordDidTapBlock sugComplementTapBlock;

@property (nonatomic, assign, getter=isWhiteStyle) BOOL whiteStyle;
@property (nonatomic, assign) ACCSearchTabType currentTabType;

@property (nonatomic, copy) NSDictionary *logAdditionParams;

- (void)fetchSugWithQuery:(NSString *)query tabType:(ACCSearchTabType)tabType;

- (void)setBackgroundColor:(UIColor *)color;

- (UIView *)view;

- (void)setViewHidden:(BOOL)hidden;

- (UIViewController *)targetSugVC;

- (void)trackSearchButtonClickReturnWithQuery:(NSString *)query;
@end


@protocol ACCMusicSearchSugVCBuilderProtocol <NSObject>

- (id<ACCMusicSearchSugViewControllerProtocol>)createSugSearchViewController;

- (id<ACCMusicSearchSugViewControllerProtocol>)createKaraokeSugSearchViewController;

- (id<ACCMusicCommonSearchBarProtocol>)createStudioSearchBar;

@end


#endif /* ACCMusicSearchSugViewControllerProtocol_h */
