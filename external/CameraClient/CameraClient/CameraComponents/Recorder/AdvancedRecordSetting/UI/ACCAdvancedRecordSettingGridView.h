//
//  ACCAdvancedRecordSettingGridView.h
//  Indexer
//
//  Created by Shichen Peng on 2021/11/8.
//

#import <UIKit/UIKit.h>

@interface ACCAdvancedRecordSettingGridView : UIView

@property (nonatomic, assign) NSUInteger numOfseparation;
@property (nonatomic, assign) CGFloat lineWidth;

- (void)updateGrid;

@end
