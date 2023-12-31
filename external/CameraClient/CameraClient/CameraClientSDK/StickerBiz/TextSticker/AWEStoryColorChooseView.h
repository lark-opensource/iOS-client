//
//  AWEStoryColorChooseView.h
//  AWEStudio
//
//  Created by hanxu on 2018/11/19.
//  Copyright © 2018 bytedance. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CreationKitArch/AWEStoryTextImageModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface AWEStoryColorChooseView : UIView
@property (nonatomic, strong, readonly) NSArray<AWEStoryColor *> *storyColors;
@property (nonatomic, copy) void (^didSelectedColorBlock) (AWEStoryColor *selectColor, NSIndexPath *indexPath);
- (void)selectWithIndexPath:(NSIndexPath *)indexPath;
- (void)selectWithColor:(UIColor *)color;
- (void)updateSelectedColorWithIndexPath:(NSIndexPath *)indexPath;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong, readonly) AWEStoryColor *selectedColor;

+ (NSArray<AWEStoryColor *> *)storyColors;

@end

NS_ASSUME_NONNULL_END
