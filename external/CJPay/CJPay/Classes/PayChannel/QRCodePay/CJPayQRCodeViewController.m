//
// Created by 易培淮 on 2020/10/15.
//

#import "CJPayQRCodeViewController.h"
#import "CJPayQRCodeModel.h"
#import <BDWebImage/BDWebImage.h>
#import <ByteDanceKit/ByteDanceKit.h>
#import "CJPayQRCodeView.h"
#import "CJPayToast.h"
#import "CJPayUIMacro.h"

@interface CJPayQRCodeViewController () <CJPayQRCodeViewDelegate>

@property (nonatomic, strong) CJPayQRCodeModel *qrCodeModel;
@property (nonatomic, strong) CJPayQRCodeView *QRCodeView;
@property (nonatomic, strong) void(^block)(void);

@end

@implementation CJPayQRCodeViewController

- (instancetype)initWithModel:(CJPayQRCodeModel *)model {
    self = [super init];
    if (self) {
        self.animationType = HalfVCEntranceTypeFromRight;
        _qrCodeModel = model;
        _isNeedQueryResult = YES;
        [self setupUI];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setTitle:self.qrCodeModel.payDeskTitle];
    [self p_fetchImage];
}

-(void)setupUI {
    [self.contentView addSubview:self.QRCodeView];
    CJPayMasMaker(self.QRCodeView, {
        make.top.bottom.right.left.equalTo(self.contentView);
    });
}

- (void)close {
    self.isNeedQueryResult = NO;
    [super closeWithAnimation:YES comletion:^(BOOL isSuccess) {
        CJ_CALL_BLOCK(self.closeBlock);
    }];
}

- (CJPayQRCodeView *)QRCodeView {
    if (!_QRCodeView) {
        _QRCodeView = [[CJPayQRCodeView alloc] initWithData:self.qrCodeModel];
        _QRCodeView.delegate = self;
    }
    return _QRCodeView;
}

#pragma mark - Private Methods

- (void)p_queryOrder {
    //控制查单逻辑
    if (!self.queryResultBlock) { //无查单代理
        return;
    }

    @CJWeakify(self)
    
    self.block = ^{
        @CJStrongify(self)
        if (!self.isNeedQueryResult) {
            return;
        }
        if (self.queryResultBlock) {
            self.queryResultBlock(^(BOOL isSuccess){
                @CJStrongify(self)
                if (isSuccess) {
                    self.isNeedQueryResult = NO;
                } else {
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), self.block);
                }
            });
        }
    };
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), self.block);
}

- (void)p_fetchImage {
    [self p_startLoading];
    bool isNeedLogo = Check_ValidString(self.qrCodeModel.logo);
    dispatch_group_t dispatchGroup = dispatch_group_create();
    dispatch_group_enter(dispatchGroup);
    [self.QRCodeView.qrCodeImageView bd_setImageWithURL:[NSURL URLWithString:self.qrCodeModel.imageUrl]
                                            placeholder:nil
                                                options:BDImageRequestDefaultPriority
                                             completion:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
        dispatch_group_leave(dispatchGroup);
    }];
    
    if (isNeedLogo) {
        dispatch_group_enter(dispatchGroup);
        [self.QRCodeView.faviconView bd_setImageWithURL:[NSURL URLWithString:self.qrCodeModel.logo]
                                            placeholder:nil
                                                options:BDImageRequestDefaultPriority
                                             completion:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
            dispatch_group_leave(dispatchGroup);
        }];
    }
    @CJWeakify(self)
    dispatch_group_notify(dispatchGroup, dispatch_get_main_queue(), ^{
        @CJStrongify(self)
        [self p_stopLoading];
        if (self.QRCodeView.qrCodeImageView.image != nil) {
            if (isNeedLogo) { self.QRCodeView.faviconView.hidden = NO; }
            self.QRCodeView.qrCodeImageView.hidden = NO;
            [self p_saveLabelAppear];
            [self p_queryOrder];
        } else {
            [self p_preReload];
            return;
        }
    });
}

- (void)p_preReload {
    self.QRCodeView.faviconView.hidden = YES;
    self.QRCodeView.qrCodeImageView.hidden = YES;
    self.QRCodeView.alertLabel.hidden = NO;
    self.QRCodeView.reloadButton.hidden = NO;
}

- (void)p_startLoading {
    self.QRCodeView.loadingView.hidden = NO;
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
    animation.fromValue = @(0.0f);
    animation.toValue = @(M_PI * 2);
    animation.duration = 0.6;
    animation.repeatCount = MAXFLOAT;
    [self.QRCodeView.loadingView.layer addAnimation:animation forKey:nil];
}

- (void)p_stopLoading {
    [self.QRCodeView.loadingView.layer removeAllAnimations];
    self.QRCodeView.loadingView.hidden = YES;
}

- (void)p_saveLabelAppear {
    if (!self.qrCodeModel.shareImageSwitch) {
        return;
    }
    self.QRCodeView.saveLabel.hidden = NO;
}

#pragma mark - delegate method

- (void)saveImage {
    UIImage *image = [self.QRCodeView getQRCodeImage];
    BTDImageWriteToSavedPhotosAlbum(image,^(NSError *error) {
        if (error == nil) {
            [CJToast toastText:CJPayLocalizedStr(@"已保存至系统相册") inWindow:self.cj_window];
        }
    });
    CJ_CALL_BLOCK(self.trackBlock);
}

- (void)reloadImage {
    self.QRCodeView.alertLabel.hidden = YES;
    self.QRCodeView.reloadButton.hidden = YES;
    [self p_fetchImage];
}

@end
