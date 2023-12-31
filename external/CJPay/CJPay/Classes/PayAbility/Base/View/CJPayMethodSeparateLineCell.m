//
//  CJPayMethodSeparateLineCell.m
//  Aweme
//
//  Created by shanghuaijun on 2023/2/28.
//

#import "CJPayMethodSeparateLineCell.h"
#import "CJPayUIMacro.h"
#import "CJPaySDKMacro.h"
#import "CJPayChannelBizModel.h"

@interface CJPayMethodSeparateLineCell ()

@property (nonatomic, strong) UIView *separatorLineView;

@end

@implementation CJPayMethodSeparateLineCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style
              reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        [self p_setupUI];
    }
    return self;
}

- (void)p_setupUI {
    [self.contentView addSubview:self.separatorLineView];
    
    CJPayMasMaker(self.separatorLineView, {
        make.centerY.equalTo(self.contentView);
        make.left.equalTo(self.contentView).offset(54);
        make.right.equalTo(self.contentView).offset(-16);
        make.height.mas_equalTo(CJ_PIXEL_WIDTH);
    })

}

+ (NSNumber *)calHeight:(CJPayChannelBizModel *)data {
    return @(16);
}

- (void)updateContent:(CJPayChannelBizModel *)data {
    
}

- (UIView *)separatorLineView {
    if (!_separatorLineView) {
        _separatorLineView = [UIView new];
        _separatorLineView.backgroundColor = [UIColor cj_161823WithAlpha:0.08];
    }
    return _separatorLineView;
}


@end
