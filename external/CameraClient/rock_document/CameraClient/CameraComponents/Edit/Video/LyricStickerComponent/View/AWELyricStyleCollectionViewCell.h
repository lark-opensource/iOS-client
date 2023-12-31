//
//  AWELyricStyleCollectionViewCell.h
//  AWEStudio
//
//  Created by Liu Deping on 2019/10/16.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class IESEffectModel;

@interface AWELyricStyleCollectionViewCell : UICollectionViewCell

@property (nonatomic, strong) IESEffectModel *currentEffectModel;
@property (nonatomic, assign, readonly) BOOL isCurrent;

- (void)setIsCurrent:(BOOL)isCurrent;
- (void)showLoadingAnimation:(BOOL)show;

@end

NS_ASSUME_NONNULL_END
