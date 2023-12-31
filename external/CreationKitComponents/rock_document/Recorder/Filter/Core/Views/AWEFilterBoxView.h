//
//  AWEFilterBoxView.h
//  Pods
//
//  Created by zhangchengtao on 2019/5/7.
//

#import <UIKit/UIKit.h>
#import <EffectPlatformSDK/IESCategoryModel.h>
#import <EffectPlatformSDK/IESEffectModel.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^AWEFilterBoxViewDidSelectDownloadedFilterModel)(IESEffectModel *filterModel);
typedef void(^AWEFilterBoxViewDidUnselectFilterModel)(IESEffectModel *filterModel);

//Filter management box
@interface AWEFilterBoxView : UIView

@property (nonatomic, readonly) NSArray *checkArray;
@property (nonatomic, readonly) NSArray *uncheckArray;
@property (nonatomic, copy) NSArray<IESCategoryModel *> *categories;

@property (nonatomic, copy) AWEFilterBoxViewDidSelectDownloadedFilterModel selectionBlock;
@property (nonatomic, copy) AWEFilterBoxViewDidUnselectFilterModel unselectionBlock;

- (void)showLoading:(BOOL)showOrHide;
- (void)showError:(BOOL)showOrHide;

@end

NS_ASSUME_NONNULL_END
