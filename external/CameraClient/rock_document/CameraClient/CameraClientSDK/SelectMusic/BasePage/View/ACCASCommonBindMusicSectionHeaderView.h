//
//  ACCASCommonBindMusicSectionHeaderView.h
//  AWEStudio-iOS8.0
//
//  Created by songxiangwu on 2019/3/4.
//

#import <UIKit/UIKit.h>

@interface ACCASCommonBindMusicSectionHeaderView : UITableViewHeaderFooterView

@property (nonatomic, strong) UIView *topLineView;

- (void)configWithTitle:(NSString *)title rightContent:(NSString *)rightContent cellWidth:(CGFloat)cellWidth;
+ (CGFloat)recommendHeight;
+ (NSString *)identifier;

@end
