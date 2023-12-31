//
//  TMAScanCodeController.m
//  OPPluginBiz
//
//  Created by muhuai on 2017/12/20.
//  Copyright © 2017年 muhuai. All rights reserved.
//

#import "TMAScanCodeController.h"
#import <OPFoundation/EMAAlertController.h>
#import <OPFoundation/BDPI18n.h>
#import <OPFoundation/UIImage+EMA.h>
#import <OPFoundation/UIWindow+EMA.h>
#import <AVFoundation/AVFoundation.h>
#import <OPPluginBiz/OPPluginBiz-Swift.h>
#import <OPPluginBiz/BDPPluginImageCustomImpl.h>
#import <Masonry/Masonry.h>
#import <OPFoundation/BDPAuthorization.h>
#import <OPFoundation/BDPDeviceHelper.h>
#import <OPFoundation/BDPUtils.h>
#import <OPFoundation/UIColor+BDPExtension.h>
#import <OPFoundation/UIView+BDPExtension.h>
#import <OPFoundation/OPFoundation-Swift.h>
#import <UniverseDesignColor/UniverseDesignColor-Swift.h>
#import <OPFoundation/BDPAuthorization+BDPSystemPermission.h>

static const CGFloat kScanCodeCenterYOffset = 35; // 扫描框中心Y轴偏移像素

@interface TMAScanCodeController ()<AVCaptureMetadataOutputObjectsDelegate>

@property (nonatomic, assign) BDPScanCodeType scanType;
@property (nonatomic, assign) BOOL barCodeInput;
@property (nonatomic, assign) BOOL onlyFromCamera;
@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic, strong) EMAHighlightButton *inputCodeButton;
@property (nonatomic, strong) UILabel *forgetLabel;
@property (nonatomic, strong) UIView *maskView;

@end

@implementation TMAScanCodeController

- (instancetype)initWithScanType:(BDPScanCodeType)scanType
                  onlyFromCamera:(BOOL)onlyFromCamera
                    barCodeInput:(BOOL)barCodeInput {
    if (self = [super init]) {
        self.scanType = scanType;
        self.onlyFromCamera = onlyFromCamera;
        self.barCodeInput = barCodeInput;
    }
    return self;
}

- (void)dealloc {
    BOOL responseToSel = [_delegate respondsToSelector:@selector(didDismissScanCodeController:)];
    NSString *msg = @"delegate has not impl didDismissScanCodeController, please fix it";
    NSAssert(responseToSel, msg);
    responseToSel ? [_delegate didDismissScanCodeController:self] : BDPLogError(msg);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.blackColor;
    self.title = BDPI18n.scan;
    [BDPAuthorization checkSystemPermissionWithTips:BDPAuthorizationSystemPermissionTypeCamera completion:^(BOOL isSuccess) {
        if (isSuccess) {
            [self setupCapture];
        }
        [self setupViews];
    }];
    [self setupNaviItems];
    [self updateNavigationBar:UDOCColor.bgBody];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.captureSession.interrupted) {
        [EMAHUD showTips:BDPI18n.LittleApp_TTMicroApp_CameraMsg window:self.view.window];
    }
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(scanCaptureSessionWasInterruptedWithotification:) name:AVCaptureSessionWasInterruptedNotification object:nil];
}

- (void)scanCaptureSessionWasInterruptedWithotification:(NSNotification *)notification {
    if (self.captureSession.interrupted) {
        [EMAHUD showTips:BDPI18n.LittleApp_TTMicroApp_CameraMsg window:self.view.window];
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self resetMaskView];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        self.previewLayer.frame = self.view.bounds;
        [self resetPreviewLayerConnection];
        [self resetMaskView];
    } completion:nil];
}

- (void)setupViews {
    [self.view addSubview:self.maskView];
    [self.maskView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    /// 开启了输入二维码功能
    if (self.barCodeInput) {
        [self.view addSubview:self.forgetLabel];
        [self.view addSubview:self.inputCodeButton];
        [self resetForgetLabelAndInputCodeButton];
    }
}

/// 设置导航按钮
- (void)setupNaviItems {
    //  添加取消按钮
    UIBarButtonItem *cancelItem = [[UIBarButtonItem alloc] initWithTitle:BDPI18n.cancel style:UIBarButtonItemStylePlain target:self action:@selector(dismissSelf)];
    cancelItem.tintColor = UDOCColor.textTitle;
    self.navigationItem.leftBarButtonItem = cancelItem;

    if (self.onlyFromCamera) {
        return;
    }
    //  添加相册选图按钮
    UIBarButtonItem *scanFromPhotoLibraryButton = [[UIBarButtonItem alloc] initWithTitle:BDPI18n.album style:UIBarButtonItemStylePlain target:self action:@selector(scanFromPhotoLibrary)];
    scanFromPhotoLibraryButton.tintColor = UDOCColor.textTitle;
    self.navigationItem.rightBarButtonItem = scanFromPhotoLibraryButton;
}

- (void)updateNavigationBar:(UIColor *)backgroundColor {
    // https://developer.apple.com/forums/thread/682420
    if (@available(iOS 15.0, *)) {
        UINavigationBarAppearance *appearance = [[UINavigationBarAppearance alloc] init];
        [appearance configureWithOpaqueBackground];
        appearance.backgroundColor = backgroundColor;
        self.navigationController.navigationBar.standardAppearance = appearance;
        self.navigationController.navigationBar.scrollEdgeAppearance = appearance;
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleDefault;
}

- (CGSize)sqSize {
    CGFloat padSqLength = 446;
    CGFloat iphoneSqLength = 250;
    if (BDPDeviceHelper.isPadDevice) {
        return CGSizeMake(padSqLength, padSqLength);
    } else {
        return CGSizeMake(iphoneSqLength, iphoneSqLength);
    }
}
//  之前的魔数实在猜不出来是啥含义，真的坑！！！！！！！！！！！！！！！！
- (void)resetMaskView {
    CGSize maskRectSize = [self sqSize];
    UIBezierPath *maskPath = [UIBezierPath bezierPathWithRect:self.view.bounds];
    CGFloat x = (self.view.bdp_width - maskRectSize.width) / 2;
    CGFloat y = (self.view.bdp_height - maskRectSize.height) / 2 - kScanCodeCenterYOffset;
    [maskPath appendPath:[[UIBezierPath bezierPathWithRect:CGRectMake(x, y, maskRectSize.width, maskRectSize.height)] bezierPathByReversingPath]];
    CAShapeLayer *shapeLayer = CAShapeLayer.layer;
    shapeLayer.path = maskPath.CGPath;
    self.maskView.layer.mask = shapeLayer;
}
- (void)resetForgetLabelAndInputCodeButton {
    CGSize maskRectSize = [self sqSize];
    CGFloat h = self.view.bdp_height / 2 + maskRectSize.height / 2 - kScanCodeCenterYOffset + 40;
    [self.forgetLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_top).offset(h);
        make.centerX.equalTo(self.view.mas_centerX);
        make.height.equalTo(@(20));
    }];
    [self.inputCodeButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.forgetLabel.mas_bottom).offset(12);
        make.centerX.equalTo(self.view.mas_centerX);
        make.height.equalTo(@(40));
    }];
}

/// 调整摄像头显示方向
- (void)resetPreviewLayerConnection {
    AVCaptureConnection *previewLayerConnection = self.previewLayer.connection;
    UIInterfaceOrientation or;
    if (@available(iOS 13.0, *)) {
        or = (self.view.window ?: OPWindowHelper.fincMainSceneWindow).windowScene.interfaceOrientation;
    } else {
        or = UIApplication.sharedApplication.statusBarOrientation;
    }
    //  Fix：修复之前写死只能iPhone竖屏扫描的Bug
    if ([previewLayerConnection isVideoOrientationSupported]) {
        switch (or) {
            case UIInterfaceOrientationUnknown:
                [previewLayerConnection setVideoOrientation:AVCaptureVideoOrientationPortrait];
                break;
            case UIInterfaceOrientationPortrait:
                [previewLayerConnection setVideoOrientation:AVCaptureVideoOrientationPortrait];
                break;
            case UIInterfaceOrientationPortraitUpsideDown:
                [previewLayerConnection setVideoOrientation:AVCaptureVideoOrientationPortraitUpsideDown];
                break;
            case UIInterfaceOrientationLandscapeLeft:
                [previewLayerConnection setVideoOrientation:AVCaptureVideoOrientationLandscapeLeft];
                break;
            case UIInterfaceOrientationLandscapeRight:
                [previewLayerConnection setVideoOrientation:AVCaptureVideoOrientationLandscapeRight];
                break;
        }
    }
}

/// 初始化视频信号捕获系统
- (void)setupCapture {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(AVCaptureInputPortFormatDescriptionDidChange:) name:AVCaptureInputPortFormatDescriptionDidChangeNotification object:nil];
    NSError *error;
    //  配置输入设备
    AVCaptureDevice * captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    AVCaptureDeviceInput *inputDevice = [[AVCaptureDeviceInput alloc] initWithDevice:captureDevice error:&error];
    if (error) {
        BDPLogError(@"%@",error)
        return;
    }
    [self.captureSession addInput:inputDevice];
    //  配置输出模式
    AVCaptureMetadataOutput * captureOutput = AVCaptureMetadataOutput.new;
    [captureOutput setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    [self.captureSession addOutput:captureOutput];
    NSMutableArray<AVMetadataObjectType> *metadataObjectTypes = NSMutableArray.array;
    [self.typeMap enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull key, NSArray<AVMetadataObjectType> * _Nonnull obj, BOOL * _Nonnull stop) {
        BDPScanCodeType scanType = [self bdpScanCodeTypeForTMA:(TMAScanCodeType)(key.integerValue)];
        if (self.scanType & scanType) {
            [metadataObjectTypes addObjectsFromArray:obj];
        }
    }];
    [captureOutput setMetadataObjectTypes:metadataObjectTypes];
    //  添加显示内容的layer
    [self.view.layer addSublayer:self.previewLayer];
    [self resetPreviewLayerConnection];
    AVCaptureConnection *focus = [captureOutput connectionWithMediaType:AVMediaTypeVideo];//获得摄像头焦点
    focus.videoScaleAndCropFactor = 1.5;
    [self.captureSession startRunning];
}

- (void)AVCaptureInputPortFormatDescriptionDidChange:(NSNotification *)notification{
    AVCaptureMetadataOutput * output = (AVCaptureMetadataOutput*)self.captureSession.outputs.firstObject;
    output.rectOfInterest = [self.previewLayer metadataOutputRectOfInterestForRect:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height - kScanCodeCenterYOffset)];
}

- (void)captureOutput:(AVCaptureOutput *)output didOutputMetadataObjects:(NSArray<__kindof AVMetadataObject *> *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
    AVMetadataMachineReadableCodeObject *obj = [metadataObjects.firstObject isKindOfClass:[AVMetadataMachineReadableCodeObject class]]? metadataObjects.firstObject: nil;
    
    NSString *stringValue = obj.stringValue;
    TMAScanCodeType type = [self codeTypeWithMetadataObjectType:obj.type];
    
    if ([self.delegate respondsToSelector:@selector(scanCodeController:didDetectCode:type:)]) {
        [self.delegate scanCodeController:self didDetectCode:stringValue type:type];
    }
}

- (TMAScanCodeType)codeTypeWithMetadataObjectType:(AVMetadataObjectType)avType {
    __block TMAScanCodeType codeType = TMAScanCodeTypeUnknow;
    [self.typeMap enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull key, NSArray<AVMetadataObjectType> * _Nonnull obj, BOOL * _Nonnull stop) {
        if ([obj containsObject:avType]) {
            codeType = (TMAScanCodeType)key.integerValue;
            *stop = YES;
        }
    }];
    return codeType;
}

- (NSDictionary<NSNumber *, NSArray<AVMetadataObjectType> *> *)typeMap {
    static NSDictionary *gTypeMap;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        gTypeMap = @{
                    @(TMAScanCodeTypeQRCode):@[AVMetadataObjectTypeQRCode],                 // qrCode       二维码
                    @(TMAScanCodeTypeDataMatrix):@[AVMetadataObjectTypeDataMatrixCode],     // datamatrix   Data Matrix 码
                    @(TMAScanCodeTypePDF147):@[AVMetadataObjectTypePDF417Code],             // pdf417       PDF417 条码
                    @(TMAScanCodeTypeBarCode):@[AVMetadataObjectTypeEAN13Code,              // barCode      一维码
                                                AVMetadataObjectTypeEAN8Code,
                                                AVMetadataObjectTypeUPCECode,
                                                AVMetadataObjectTypeCode39Code,
                                                AVMetadataObjectTypeCode39Mod43Code,
                                                AVMetadataObjectTypeCode93Code,
                                                AVMetadataObjectTypeCode128Code,
                                                AVMetadataObjectTypeAztecCode,
                                                AVMetadataObjectTypeITF14Code,
                                                AVMetadataObjectTypeInterleaved2of5Code
                                                ]
                    };
    });

    return gTypeMap;
}

- (BDPScanCodeType)bdpScanCodeTypeForTMA:(TMAScanCodeType)tmaScanType {
    BDPScanCodeType scanCodeType = BDPScanCodeTypeUnknow;
    switch(tmaScanType) {
        case TMAScanCodeTypeUnknow: {
            scanCodeType = BDPScanCodeTypeUnknow;
            break;
        }
        case TMAScanCodeTypeQRCode: {
            scanCodeType = BDPScanCodeTypeQRCode;
            break;
        }
        case TMAScanCodeTypeBarCode: {
            scanCodeType = BDPScanCodeTypeBarCode;
            break;
        }
        case TMAScanCodeTypePDF147: {
            scanCodeType = BDPScanCodeTypePDF417;
            break;
        }
        case TMAScanCodeTypeDataMatrix: {
            scanCodeType = BDPScanCodeTypeDatamatrix;
            break;
        }
    }
    return scanCodeType;
}

- (void)didTapInputCodeButton {
    EMAAlertController *alertVC = [EMAAlertController alertControllerWithTitle:BDPI18n.scan_please_enter_barcode message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alertVC addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        textField.placeholder = BDPI18n.scan_please_enter_barcode;
    }];
    [alertVC addAction:[EMAAlertAction actionWithTitle:BDPI18n.cancel style:UIAlertActionStyleCancel handler:nil]];
    WeakSelf;
    __weak typeof(alertVC) weakAlertVC = alertVC;
    [alertVC addAction:[EMAAlertAction actionWithTitle:BDPI18n.confirm style:UIAlertActionStyleDefault handler:^(EMAAlertAction *action) {
        StrongSelfIfNilReturn
        __strong EMAAlertController *strongAlertVC = weakAlertVC;
        if (BDPIsEmptyString(strongAlertVC.textFields.firstObject.text) || ![self.delegate respondsToSelector:@selector(scanCodeController:didDetectCode:type:)]) {
            return ;
        }
        /// 回调
        [self.delegate scanCodeController:self didDetectCode:strongAlertVC.textFields.firstObject.text type:TMAScanCodeTypeUnknow];
    }]];
    [self presentViewController:alertVC animated:YES completion:nil];
}

#pragma mark - getter

- (UILabel *)forgetLabel {
    if (!_forgetLabel) {
        _forgetLabel = [[UILabel alloc] init];
        _forgetLabel.text = BDPI18n.scan_cannot_identify_barcode;
        _forgetLabel.textColor = UIColor.whiteColor;
        _forgetLabel.font = [UIFont systemFontOfSize:14];
    }
    return _forgetLabel;
}

- (EMAHighlightButton *)inputCodeButton {
    if (!_inputCodeButton) {
        _inputCodeButton = [EMAHighlightButton buttonWithType:UIButtonTypeCustom];
        [_inputCodeButton setTitle:BDPI18n.scan_enter_barcode forState:normal];
        _inputCodeButton.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
        _inputCodeButton.titleLabel.textAlignment = NSTextAlignmentCenter;
        _inputCodeButton.layer.cornerRadius = 20;
        _inputCodeButton.layer.borderColor = [[UIColor alloc] initWithWhite:1 alpha:0.6].CGColor;
        _inputCodeButton.layer.borderWidth = 1;
        _inputCodeButton.contentEdgeInsets = UIEdgeInsetsMake(10, 40, 10, 40);
        [_inputCodeButton addTarget:self action:@selector(didTapInputCodeButton) forControlEvents:UIControlEventTouchUpInside];
    }
    return _inputCodeButton;
}

- (AVCaptureSession *)captureSession {
    if (!_captureSession) {
        _captureSession = AVCaptureSession.new;
    }
    return _captureSession;
}

- (AVCaptureVideoPreviewLayer *)previewLayer {
    if (!_previewLayer) {
        _previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.captureSession];
        _previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        _previewLayer.masksToBounds = YES;
        _previewLayer.frame = self.view.bounds;
    }
    return _previewLayer;
}

- (UIView *)maskView {
    if (!_maskView) {
        _maskView = [[UIView alloc] initWithFrame:self.view.bounds];
        _maskView.backgroundColor = UIColor.blackColor;
        _maskView.alpha = 0.6;
    }
    return _maskView;
}

#pragma mark - scanFromPhotoLibrary
- (void)scanFromPhotoLibrary {
    [EMAImagePicker pickImageWithMaxCount:1
                           allowAlbumMode:YES
                          allowCameraMode:NO
                         isOriginalHidden:YES
                               isOriginal:NO
                             singleSelect:YES
                             cameraDevice:@"back"
                                       in:self
                           resultCallback:^(NSArray<UIImage *> * _Nullable photos, BOOL isOriginal, BDPImageAuthResult authResult) {
        UIImage *image = photos.firstObject;
        if (!image) {
            return; // 没有选择图片
        }
        if (self.scanType & BDPScanCodeTypeQRCode) {
            // 从相册图片目前只能识别qrCode，不支barCode，datamatrix，pdf417
            NSString *stringValue = image.ema_qrCode;
            if (!BDPIsEmptyString(stringValue)) {
                if ([self.delegate respondsToSelector:@selector(scanCodeController:didDetectCode:type:)]) {
                    [self.delegate scanCodeController:self didDetectCode:stringValue type:TMAScanCodeTypeQRCode];
                }
                return;
            }
        }else {
            // 不能识别的什么也不做
        }

        EMAAlertController *alert = [EMAAlertController alertControllerWithTitle:nil message:BDPI18n.qrcode_not_found preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[EMAAlertAction actionWithTitle:BDPI18n.determine style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    }];
}

@end

/**
 * 关于条形码的扫描
 * 条形码种类繁多，对于各种条形码的扫描不能完全实现或对齐，目前只能部分支持。
 * 这里列出了实际测试的扫描识别种类和结果，WX扫码作为对照，识别样本及相关介绍参见 https://www.tec-it.com/zh-cn/support/knowbase/barcode-overview/linear/Default.aspx
 *
 * 条形码类型            WX扫码               本扫码             备注                        应用
 * Code 128            🙂                   🙂                                          广泛使用在所有领域中
 * 2 of 5 Interleaved                       🙂                                          广泛使用在所有领域中(商品编号方式，工业应用...)
 * 3 of 9 (Code 39)    🙂                   🙂                                          广泛应用于工业领域，著作业和商业(非零售)
 * 3 of 9 Ext (ASCII)  🙂                   🙂                                          具有较低的伸展性，因为条码128提供同样的字符集，但是，其加密更紧凑
 * EAN8                🙂                   🙂                                          欧洲零售产品市场(European retail product marking)
 * EAN8 P2             🙂                   🙂              部分识别                      适用于杂志和平装本
 * EAN8 P5             🙂                                   部分识别                      适用于杂志和平装本
 * EAN13               🙂                   🙂                                          零售商品市场(European Article Numbering)
 * EAN13 P2            🙂                                   部分识别                      适用于杂志和平装本
 * EAN13 P5            🙂                                   部分识别                      "ISBN"的加密 — 大量用于书本(零售产品市场)
 * EAN14               😨                                   信息不一致                     从GS1系统中使用14位GTIN (全球商业项目号"Global Trade Item Nummer")加密
 * EAN128 / GS1-128    🙂                   🙂                                           普遍可用于例如零售商品市场或航运(等等)；还可用于产品的数量，重量，价格
 * UPC Version A       🙂                   🙂                                           零售商品市场(使用销售点现金出纳机系统)
 * UPC Version E       🙂                   🙂                                           零售产品标记和小物品条形码
 * UCC 128             🙂                   🙂                                           参考EAN128
 * CodaBar 2 Width     😨                                   丢失部分信息                   适用于零售产品市场的市场系统
 * Code93              🙂                   🙂                                           获取比Code39提供的更高信息密度
 * ISBN                😨                                   部分信息不一致 & 部分识别        与EAN13 P5相似
 * LOGMARS             😨                                   信息不一致                     Code39军队使用标准化
 * PZN Code            🙂                   🙂                                           药品的识别
 * DP Leitcode         🙂                                                                对于在货运中心的货运装船自动化档案区分
 * UPU S10             🙂                   🙂                                           在国际上用于邮件的分类和跟踪
 *
 * WX扫码和本扫码都不能识别的条形码类型：Postnet5，Postnet 9，Australian Post Custom，Royal Mail 4 State Customer Code，USPS Intelligent Mail，ISBT 128
 * One-Track Pharmacode，Two-Track Pharmacode，Flattermarken，MSI，Plessey，Code 11，2 of 5 Standard，2 of 5 IATA，Code 93 Full ASCII，DP Identcode
 **/
