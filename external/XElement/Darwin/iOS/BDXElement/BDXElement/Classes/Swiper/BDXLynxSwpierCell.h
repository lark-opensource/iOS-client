//
//  BDXLynxSwpierCell.h
//  BDAlogProtocol
//
//  Created by bill on 2020/3/20.
//

#import <UIKit/UIKit.h>

@class LynxUI;

NS_ASSUME_NONNULL_BEGIN

@interface BDXLynxSwpierCell : UICollectionViewCell

@property(nonatomic, weak, readwrite) LynxUI* ui;
- (void)addContent:(UIView*)view;

@end

NS_ASSUME_NONNULL_END
