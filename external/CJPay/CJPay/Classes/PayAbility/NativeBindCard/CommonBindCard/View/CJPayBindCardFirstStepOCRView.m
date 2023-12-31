//
//  CJPayBindCardFirstStepOCRView.m
//  Pods
//
//  Created by xiuyuanLee on 2020/12/10.
//

#import "CJPayBindCardFirstStepOCRView.h"
#import "CJPayStyleButton.h"
#import "CJPayUIMacro.h"

@interface CJPayBindCardFirstStepOCRView ()

@property (nonatomic, strong) CJPayButton *ocrButton;

@end

@implementation CJPayBindCardFirstStepOCRView

- (instancetype)init {
    self = [super init];
    if (self) {
        [self p_setupUI];
    }
    return self;
}

- (void)p_setupUI {
    [self addSubview:self.ocrButton];

    CJPayMasMaker(self.ocrButton, {
        make.center.equalTo(self);
        CGFloat height = 24;
        make.size.mas_equalTo(CGSizeMake(height, height));
    });
}

#pragma mark - click method
- (void)p_ocrButtonClick {
    CJ_CALL_BLOCK(self.didOCRButtonClickBlock);
}

#pragma mark - lazy view
- (CJPayButton *)ocrButton {
    if (!_ocrButton) {
        _ocrButton = [CJPayButton new];
        [_ocrButton cj_setBtnImageWithName:@"cj_ocr_scan_camera_icon"];
        [_ocrButton addTarget:self action:@selector(p_ocrButtonClick) forControlEvents:UIControlEventTouchUpInside];
        _ocrButton.alpha = 0.75;
    }
    return _ocrButton;
}

@end
