//
//  CJPayBindCardChooseIDTypeCell.m
//  CJPay
//
//  Created by 尚怀军 on 2019/10/14.
//

#import "CJPayBindCardChooseIDTypeCell.h"
#import "CJPayUIMacro.h"
#import "CJPayUIMacro.h"
#import "CJPayStyleCheckMark.h"

@implementation CJPayBindCardChooseIDTypeModel

- (void)setIdType:(CJPayBindCardChooseIDType)idType {
    _idType = idType;
    self.titleStr = [[self class] getIDTypeStr:_idType];
}

+ (NSString *)getIDTypeStr:(CJPayBindCardChooseIDType)idType {
    switch (idType) {
        case CJPayBindCardChooseIDTypeNormal:
            return CJPayLocalizedStr(@"居民身份证");
        case CJPayBindCardChooseIDTypeHK:
            return CJPayLocalizedStr(@"港澳居民来往内地通行证");
        case CJPayBindCardChooseIDTypeTW:
            return CJPayLocalizedStr(@"台湾居民来往大陆通行证");
        case CJPayBindCardChooseIDTypePD:
            return CJPayLocalizedStr(@"护照");
        case CJPayBindCardChooseIDTYpeHKRP:
            return CJPayLocalizedStr(@"港澳居民居住证");
        case CJPayBindCardChooseIDTYpeTWRP:
            return CJPayLocalizedStr(@"台湾居民居住证");
        default:
            return CJPayLocalizedStr(@"居民身份证");
    }
}

+ (NSString *)getIDTypeWithCardTypeStr:(NSString *)cardType {
    if ([cardType isEqualToString:@"ID_CARD"]) {
        return CJPayLocalizedStr(@"居民身份证");
    }
    
    if ([cardType isEqualToString:@"HKMPASS"]) {
        return CJPayLocalizedStr(@"港澳居民来往内地通行证");
    }
    
    if ([cardType isEqualToString:@"TAIWANPASS"]) {
        return CJPayLocalizedStr(@"台湾居民来往大陆通行证");
    }
    
    if ([cardType isEqualToString:@"PASSPORT"]) {
        return CJPayLocalizedStr(@"护照");
    }
    return @"";
}

@end

@interface CJPayBindCardChooseIDTypeCell()

@property(nonatomic,strong)UILabel *leftLabel;
@property (nonatomic,strong) CJPayStyleCheckMark *rightImageView;
@property(nonatomic,strong)UIView *bottomLine;

@end

@implementation CJPayBindCardChooseIDTypeCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        [self setupUI];
    }
    
    return self;
}

- (void)setupUI {
   
    self.leftLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 17, CJ_SCREEN_WIDTH - 66, 22)];
    self.leftLabel.font = [UIFont cj_fontOfSize:16];
    self.leftLabel.textColor = [UIColor cj_222222ff];
    
    self.rightImageView = [[CJPayStyleCheckMark alloc] initWithFrame:CGRectMake(CJ_SCREEN_WIDTH - 15 - 20, 16, 20, 20)];
    
    self.bottomLine = [[UIView alloc] initWithFrame:CGRectMake(16, 55, CJ_SCREEN_WIDTH - 16, CJ_PIXEL_WIDTH)];
    self.bottomLine.backgroundColor = [UIColor cj_e8e8e8ff];
    
    [self.contentView addSubview:self.leftLabel];
    [self.contentView addSubview:self.rightImageView];
    [self.contentView addSubview:self.bottomLine];
    
}

- (void)updateWithModel:(CJPayBindCardChooseIDTypeModel *)model {
    self.leftLabel.text = model.titleStr;
    self.rightImageView.hidden = !model.isSelected;
}

@end
