//
//  CJPayBindCardHeaderView.m
//  CJPay
//
//  Created by 尚怀军 on 2019/10/11.
//

#import "CJPayBindCardHeaderView.h"
#import "CJPayUIMacro.h"
#import "CJPayUserInfo.h"
#import "CJPayMethodCellTagView.h"

@implementation BDPayBindCardHeaderViewDataModel

+ (NSDictionary <NSString *, NSString *> *)keyMapperDict {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    [dict addEntriesFromDictionary:@{
        @"firstStepMainTitle" : CJPayBindCardShareDataKeyFirstStepMainTitle
    }];
    
    [dict addEntriesFromDictionary:[super keyMapperDict]];
    
    return dict;
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

@end
@interface CJPayBindCardHeaderView()

#pragma mark - model
@property (nonatomic, strong) BDPayBindCardHeaderViewDataModel *dataModel;
#pragma mark - flag
@property (nonatomic, assign) BOOL isFirstStep;

@property (nonatomic, strong) CJPayButton *searchCardNoBtn;
@property (nonatomic, strong) UILabel *mainTitleLabel;
@property (nonatomic, strong) UIImageView *arrowImageView;

@end

@implementation CJPayBindCardHeaderView

+ (NSArray <NSString *>*)dataModelKey {
    return [BDPayBindCardHeaderViewDataModel keysOfParams];
}

- (instancetype)initWithBindCardDictonary:(NSDictionary *)dict isFirstStep:(BOOL)isFirstStep {
    if (self = [super init]) {
        if (dict.count > 0) {
            self.dataModel = [[BDPayBindCardHeaderViewDataModel alloc] initWithDictionary:dict error:nil];
        }
        self.isFirstStep = isFirstStep;
        [self p_setupUI];
        [self p_updateData];
    }
    return self;
}

- (void)updateHeaderView:(BDPayBindCardHeaderViewDataModel *)dataModel {
    self.dataModel = dataModel;
    [self p_updateData];
}

#pragma mark - private method

- (void)p_setupUI {
    [self addSubview:self.mainTitleLabel];
    [self addSubview:self.searchCardNoBtn];
    [self addSubview:self.arrowImageView];
    
    CJPayMasMaker(self.mainTitleLabel, {
        make.centerY.equalTo(self);
        make.left.equalTo(self).offset(32);
        make.right.lessThanOrEqualTo(self).offset(-32);
    });
    
    self.arrowImageView.hidden = NO;
    self.arrowImageView.userInteractionEnabled = YES;
    CJPayMasMaker(self.arrowImageView, {
        make.right.equalTo(self).offset(-32);
        make.centerY.equalTo(self.mainTitleLabel);
        make.width.height.mas_equalTo(24);
    });
    
    CJPayMasMaker(self.searchCardNoBtn, {
        make.right.equalTo(self.arrowImageView.mas_left).offset(1);
        make.centerY.equalTo(self.mainTitleLabel);
        make.left.greaterThanOrEqualTo(self.mainTitleLabel.mas_right).offset(8);
    });
    
    [self.searchCardNoBtn cj_setBtnTitle:CJPayLocalizedStr(@"查询卡号")];
    [self.searchCardNoBtn cj_setBtnTitleColor:[UIColor cj_161823WithAlpha:0.75]];
}

- (void)p_updateData {
    self.mainTitleLabel.text = [self p_getMainTitleText];
}

- (NSString *)p_getMainTitleText {
    if (Check_ValidString(self.dataModel.firstStepMainTitle)) {
        return CJString(self.dataModel.firstStepMainTitle);
    }
    return CJPayLocalizedStr(@"输入卡号添加");
}

- (void)p_supportListButtonClick {
    CJ_CALL_BLOCK(self.didSupportListButtonClickBlock);
}

- (void)p_searchCardNo {
    CJ_CALL_BLOCK(self.didClickSearchCardNoBlock);
}

#pragma mark - lazy view

- (UILabel *)mainTitleLabel {
    if (!_mainTitleLabel) {
        _mainTitleLabel = [[UILabel alloc] init];
        _mainTitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _mainTitleLabel.font = [UIFont cj_boldFontOfSize:14];
        _mainTitleLabel.textColor = [UIColor cj_161823ff];
    }
    return _mainTitleLabel;
}

- (CJPayButton *)searchCardNoBtn {
    if (!_searchCardNoBtn) {
        _searchCardNoBtn = [CJPayButton new];
        _searchCardNoBtn.titleLabel.font = [UIFont cj_fontOfSize:12];
        [_searchCardNoBtn addTarget:self action:@selector(p_searchCardNo) forControlEvents:UIControlEventTouchUpInside];
    }
    return _searchCardNoBtn;
}

- (UIImageView *)arrowImageView {
    if (!_arrowImageView) {
        _arrowImageView = [UIImageView new];
        _arrowImageView.hidden = YES;
        [_arrowImageView cj_setImage:@"cj_quick_bindcard_arrow_light_icon"];
        UITapGestureRecognizer *tapG = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(p_searchCardNo)];
        [_arrowImageView addGestureRecognizer:tapG];
    }
    return _arrowImageView;
}

@end
