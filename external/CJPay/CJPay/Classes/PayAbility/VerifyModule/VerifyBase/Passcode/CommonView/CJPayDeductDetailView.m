//
//  CJPayDeductDetailView.m
//  CJPaySandBox
//
//  Created by ZhengQiuyu on 2023/7/20.
//

#import "CJPayDeductDetailView.h"
#import "CJPayResultDetailItemView.h"
#import "CJPayUIMacro.h"
#import <math.h>

@interface CJPayDeductDetailView ()

@property (nonatomic, copy) NSArray<CJPayResultDetailItemView *> *itemViewArray;

@end

@implementation CJPayDeductDetailView

- (void)updateDeductDetailWithTitleArray:(NSArray<NSString *> *)titleArray descArray:(NSArray<NSString *> *)descArray isDescHighLightArray:(nonnull NSArray<NSNumber *> *)isDescHighLightArray {
    if ([self isNeedHideSelf:titleArray descArray:descArray]) {
        self.hidden = YES;
        return;
    }
    self.hidden = NO;
    [self cj_removeAllSubViews];
    
    NSInteger count = MIN(titleArray.count, descArray.count);
    NSMutableArray<CJPayResultDetailItemView *> *itemViewArray = [NSMutableArray new];
    for (NSInteger index = 0; index < count ; index++) {
        NSString *title = [titleArray cj_objectAtIndex:index];
        NSString *desc = [descArray cj_objectAtIndex:index];
        BOOL isDescHighLight = [[isDescHighLightArray cj_objectAtIndex:index] boolValue];
        if (!(Check_ValidString(title) && Check_ValidString(desc))) {
            continue;
        }
        CJPayResultDetailItemView *itemView = [self p_makeResultDetailItemView:title desc:desc isDescHighLight:isDescHighLight];
        [itemViewArray btd_addObject:itemView];
    }
    self.itemViewArray = [itemViewArray copy];
    for (NSInteger index = 0;index < self.itemViewArray.count; index++) {
        CJPayResultDetailItemView *itemView = [self.itemViewArray btd_objectAtIndex:index];
        [self addSubview:itemView];
        CJPayMasReMaker(itemView, {
            if (index == 0) {
                make.top.mas_equalTo(self);
            } else {
                make.top.mas_equalTo([itemViewArray cj_objectAtIndex:index - 1].mas_bottom).mas_offset(8);
            }
            make.left.right.mas_equalTo(self);
            make.height.mas_equalTo(20);
            if (index == self.itemViewArray.count - 1) {
                make.bottom.mas_equalTo(self);
            }
        });
    }
}

- (BOOL)isNeedHideSelf:(NSArray<NSString *> *)titleArray descArray:(NSArray<NSString *> *)descArray {
    NSInteger titleCount = titleArray.count;
    NSInteger descCount = descArray.count;
    if (titleCount != descCount || titleCount == 0) {
        return YES;
    }
    for (NSInteger index = 0; index < titleArray.count ;index++) { // 只要有一组title 和 descArray都不为空 都不会隐藏self。
        if (Check_ValidString(titleArray[index]) && Check_ValidString(descArray[index])) {
            return NO;
        }
    }
    return YES;
}

- (CJPayResultDetailItemView *)p_makeResultDetailItemView:(NSString *)title desc:(NSString *)desc isDescHighLight:(BOOL)isDescHightLight {
    CJPayResultDetailItemView *itemView = [CJPayResultDetailItemView new];
    [itemView updateWithTitle:title detail:desc];
    itemView.titleLabel.font = [UIFont cj_fontOfSize:14];
    itemView.detailLabel.textColor = isDescHightLight ? [UIColor cj_ff6e26ff] :[UIColor cj_161823WithAlpha:0.6];
    itemView.detailLabel.numberOfLines = 2;
    return itemView;
}

@end
