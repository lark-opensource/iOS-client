//
//  ACCSwitchLengthCell.h
//  DouYin
//
//  Created by shaohua yang on 6/29/20.
//  Copyright © 2020 United Nations. All rights reserved.
//

#import <UIKit/UIKit.h>

#define SUBMODE_CELL_WIDTH 52
#define SUBMODE_CELL_HEIGHT 44

NS_ASSUME_NONNULL_BEGIN

@interface ACCSwitchLengthCell : UICollectionViewCell

@property (nonatomic, copy) NSString *text;

@property (nonatomic, assign) NSInteger modeId;

- (void)setProgress:(CGFloat)progress;

@end

NS_ASSUME_NONNULL_END
