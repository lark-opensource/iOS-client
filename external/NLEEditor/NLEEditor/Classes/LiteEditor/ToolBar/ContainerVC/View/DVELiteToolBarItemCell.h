//
//  DVELiteToolBarItemCell.h
//  Pods
//
//  Created by Lincoln on 2022/1/4.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#define kDVELiteToolBarCellWidth 52
#define kDVELiteToolBarBottomCellHeight 45

@class DVELiteBarComponentModel;

@interface DVELiteToolBarItemCell : UICollectionViewCell

- (void)configCellWithModel:(DVELiteBarComponentModel *)model;

+ (NSString *)identifier;

@end

NS_ASSUME_NONNULL_END
