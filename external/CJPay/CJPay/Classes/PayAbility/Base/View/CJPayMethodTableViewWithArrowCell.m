//
//  CJPayMethodTableViewWithArrowCell.m
//  Pods
//
//  Created by 易培淮 on 2021/1/26.
//

#import "CJPayMethodTableViewWithArrowCell.h"

@interface CJPayMethodTableViewWithArrowCell()

@property (nonatomic, strong) UIImageView *arrowImageView;

@end

@implementation CJPayMethodTableViewWithArrowCell

#pragma mark - Getter
- (UIImageView *)arrowImageView
{
    if (!_arrowImageView) {
        _arrowImageView = [UIImageView new];
        [_arrowImageView cj_setImage:@"cj_arrow_icon"];
    }
    return _arrowImageView;
}

#pragma mark - CJPayBaseLoadingProtocol
- (void)startLoading {
    CJ_ModalOpenOnCurrentView;
    [self.arrowImageView cj_startLoading];
}

- (void)stopLoading {
    CJ_ModalCloseOnCurrentView;
    [self.arrowImageView cj_stopLoading];
}

#pragma mark - CJPayMethodDataUpdateProtocol
//空实现
- (void)updateContent:(CJPayChannelBizModel *)data {
    
}

//空实现
+ (NSNumber *)calHeight:(CJPayChannelBizModel *)data {
    return @(0);
}

@end
