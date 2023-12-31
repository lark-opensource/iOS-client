//
//  TMAStickerInputView.m
//  TMAStickerKeyboard
//
//  Created by houjihu on 2018/8/17.
//  Copyright © 2018年 houjihu. All rights reserved.
//

#import "TMAStickerInputView.h"
#import "TMAStickerKeyboard.h"
#import "TMAStickerTextView.h"
#import <OPFoundation/UIView+BDPExtension.h>
#import "TMAStickerAvatarView.h"
#import "TMAThumnailView.h"
#import <OPFoundation/EMARouteMediator.h>
#import "TMAAtDataBackedString.h"
#import "TMAStickerDataManager.h"
#import "TMAStickerInputModel.h"
#import <ECOInfra/BDPUtils.h>
#import <ECOInfra/BDPLog.h>
#import "TMAButton.h"
#import "NSAttributedString+TMASticker.h"
#import <OPFoundation/UIImage+EMA.h>
#import <ECOInfra/NSURLSession+TMA.h>
#import <OPFoundation/TMASessionManager.h>
#import <OPFoundation/BDPI18n.h>
#import <OPFoundation/TMACustomHelper.h>
#import <ECOInfra/BDPFileSystemHelper.h>
#import <ECOInfra/EMANetworkManager.h>
#import <OPFoundation/EMANetworkAPI.h>
#import <OPFoundation/BDPTimorClient.h>
#import <ECOInfra/NSDictionary+BDPExtension.h>
#import <OPFoundation/UIColor+EMA.h>
#import <ECOInfra/ECOInfra-Swift.h>
#import <OPSDK/OPSDK-Swift.h>

#import <OPFoundation/BDPDeviceHelper.h>
#import <OPFoundation/EMAMonitorHelper.h>
#import <OPFoundation/UIWindow+EMA.h>
#import <OPFoundation/BDPCommonManager.h>
#import <OPFoundation/BDPStorageModuleProtocol.h>
#import <OPFoundation/BDPModuleManager.h>
#import <KVOController/KVOController.h>
#import <OPFoundation/EMANetworkCipher.h>
#import <OPFoundation/EMARequestUtil.h>

#import <OPFoundation/OPFoundation-Swift.h>
#import <UniverseDesignColor/UniverseDesignColor-Swift.h>
#import <TTMicroApp/TTMicroApp-Swift.h>
#import <OPFoundation/BDPMonitorEvent.h>
#import <ECOInfra/JSONValue+BDPExtension.h>
#import <OPFoundation/BDPMediaPluginDelegate.h>
#import <OPPluginBiz/OPPluginBiz-Swift.h>
#import <OPFoundation/EEFeatureGating.h>
#import <LarkOPInterface/LarkOPInterface-Swift.h>
#import "BDPPluginImageCustomImpl.h"

static CGFloat const TMAStickerTextViewHeight = 44.0;

static CGFloat const TMAStickerTextViewTextViewTopMargin = 10.0;
static CGFloat const TMAStickerTextViewTextViewUnfocusLeftRightPadding = 16.0;
static CGFloat const TMAStickerTextViewTextViewLeftRightPadding = 16.0;
static CGFloat const TMAStickerTextViewTextViewBottomMargin = 10.0;
static NSUInteger const TMAStickerTextViewMaxLineCount = 6;
static NSUInteger const TMAStickerTextViewMinLineCount = 1;
static CGFloat const TMAStickerTextViewLineSpacing = 5.0;
static CGFloat const TMAStickerTextViewFontSize = 16.0;

static CGFloat TMAStickerTextViewToolbarHeight = 48.0;
static CGFloat const TMAStickerTextViewToggleButtonLength = 24.0;
static CGFloat const TMAStickerTextViewToggleButtonMarginX = 24.0;
static NSString * const EEFeatureGatingKeyGadgetComponentCustomizedInputUseLarkPhotoPicker = @"openplatform.component.customized_input.use.lark_photo_picker";
static NSString * const EEFeatureGatingKeyGadgetComponentCustomizedInputUserModelSelectOpt = @"openplatform.component.customized_input.user_model_select.refine";
static NSString * const EEFeatureGatingKeyGadgetComponentCustomizedInputContentPlaceholderOpt = @"openplatform.component.customized_input.content_and_placeholder_refine";
static NSString * const EEFeatureGatingKeyApiUniteOpt = @"openplatform.open.interface.api.unite.opt";

@interface TMAStickerInputView () <UITextViewDelegate, TMAStickerKeyboardDelegate, OPComponentKeyboardDelegate>

@property (nonatomic, weak) UIViewController *currentViewController;
@property (nonatomic, strong) BDPUniqueID *uniqueID;

@property (nonatomic, strong) TMAStickerTextView *textView;
@property (nonatomic, strong) TMAThumnailView *thumnailView;
@property (nonatomic, strong) UIView *separatedLine;
@property (nonatomic, strong) TMAButton *emojiToggleButton;
@property (nonatomic, strong) TMAButton *pictureButton;
@property (nonatomic, strong) TMAButton *atButton;
@property (nonatomic, strong) TMAStickerAvatarView *avatarView;
@property (nonatomic, strong) NSMutableArray<TMAButton *> *toolbarButtons;
@property (nonatomic, strong) TMAStickerKeyboard *stickerKeyboard;
@property (nonatomic, strong) UIView *bottomBGView;

/// 点击表情/图片/at按钮后，隐藏光标和键盘；再点击输入框，显示光标和键盘
@property (nonatomic, strong) UIButton *textViewAboveMaskButton;

@property (nonatomic, assign, readwrite) TMAKeyboardType keyboardType;
@property (nonatomic, assign) BOOL keepsPreModeTextViewWillEdited;

/// 标识用户手动输入@字符触发了选择联系人弹窗
@property (nonatomic, assign) BOOL isAtCharaterInputedToAlert;
/// 标识是否显示了选择联系人弹窗
@property (nonatomic, assign) BOOL isSelectChatterNamesVCPresented;
/// 标识是否显示了选择图片弹窗
@property (nonatomic, assign) BOOL isSelectPicturesVCPresented;
/// 标识是否正在选择实名/匿名
@property (nonatomic, assign) BOOL isSelectUserModelPresented;
/// 标识是否正在发送
@property (nonatomic, assign) BOOL isPublishing;

@property (nonatomic, assign) BOOL useLarkPhotoPicker;
@property (nonatomic, assign) BOOL userModelSelectOpt;
@property (nonatomic, assign) BOOL contentPlaceHolderOpt;

@property (nonatomic, assign) BOOL enableKeyboardOpt;
@property (nonatomic, assign) BOOL enableApiUniteOpt;
@property (nonatomic, strong) OPComponentKeyboardHelper *keyboardHelper;

@end

@implementation TMAStickerInputView

- (instancetype)initWithFrame:(CGRect)frame currentViewController:(UIViewController *)currentViewController model:(TMAStickerInputModel *)model uniqueID:(BDPUniqueID *)uniqueID {
    self = [super initWithFrame:frame];
    if (self) {
        _useLarkPhotoPicker = [EEFeatureGating boolValueForKey:EEFeatureGatingKeyGadgetComponentCustomizedInputUseLarkPhotoPicker];
        _userModelSelectOpt = [EEFeatureGating boolValueForKey:EEFeatureGatingKeyGadgetComponentCustomizedInputUserModelSelectOpt];
        _contentPlaceHolderOpt = [EEFeatureGating boolValueForKey:EEFeatureGatingKeyGadgetComponentCustomizedInputContentPlaceholderOpt];
        _enableKeyboardOpt = [EEFeatureGating boolValueForKey:EEFeatureGatingKeyNativeComponentKeyboardOpt];
        _enableApiUniteOpt = [EEFeatureGating boolValueForKey:EEFeatureGatingKeyApiUniteOpt];
        if (_enableKeyboardOpt) {
            _keyboardHelper = [[OPComponentKeyboardHelper alloc] initWithDelegate:self];
        } else {
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
        }
        
        _uniqueID = uniqueID;
        self.currentViewController = currentViewController;
        self.model = model;
        self.exclusiveTouch = YES;
        self.backgroundColor = UDOCColor.bgBody;
        [UDOCLayerBridge setShadowColorWithLayer:self.layer color:UDOCColor.shadowDefaultSm];
        // UDOCColor.shadowDefaultSm颜色自带透明度,这边如果再设置会导致颜色太淡看不见;
        self.layer.shadowOpacity = 1;
        self.layer.shadowOffset = CGSizeMake(0, -0.5);

        _keyboardType = TMAKeyboardTypeNone;

        [self addSubview:self.textView];
        [self addSubview:self.textViewAboveMaskButton];
        [self showTextViewCursor:YES];
        [self addSubview:self.thumnailView];
        [self addSubview:self.separatedLine];
        [self addSubview:self.avatarView];
        [self addSubview:self.emojiToggleButton];
        [self addSubview:self.pictureButton];
        [self addSubview:self.atButton];
        self.toolbarButtons = [[NSMutableArray<TMAButton *> alloc] initWithObjects:self.emojiToggleButton, self.pictureButton, self.atButton, nil];
        
        WeakSelf;
        [self.KVOController observe:self.model keyPath:@"picture" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew block:^(id  _Nullable observer, id  _Nonnull object, NSDictionary<NSString *,id> * _Nonnull change) {
            StrongSelfIfNilReturn;
            if (self.contentPlaceHolderOpt) {
                return;
            }
            NSArray *picture = change[NSKeyValueChangeNewKey];
            if (![picture isKindOfClass:[NSArray class]]) {
                return ;
            }
            if (picture.count > 0) {
                self.textView.enablesReturnKeyAutomatically = NO;
            } else {
                BOOL enable;
                if (self.model.enablesReturnKey) {
                    enable = NO;
                } else {
                    enable = YES;
                }
                self.textView.enablesReturnKeyAutomatically = enable;
            }
        }];
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    }
    return self;
}

- (void)dealloc
{
    if (self.bottomBGView.superview) {
           [self.bottomBGView removeFromSuperview];
    }
    [self.KVOController unobserveAll];
}

- (void)layoutSubviews {
    [super layoutSubviews];

    self.textView.frame = [self frameTextView];
    self.textViewAboveMaskButton.frame = self.textView.frame;
    
    self.thumnailView.bdp_size = CGSizeMake(TMAThumnailViewSize, TMAThumnailViewSize);
    self.thumnailView.bdp_centerY = self.textView.bdp_centerY;
    self.thumnailView.bdp_right = self.bdp_width - TMAStickerTextViewTextViewLeftRightPadding;
    
    NSArray<UIButton *> *buttons = @[self.emojiToggleButton, self.pictureButton, self.atButton];
    NSMutableArray<UIButton *> *mutableButtons = [NSMutableArray<UIButton *> array];
    for (UIButton *btn in buttons) {
        if (!btn.hidden) {
            [mutableButtons addObject:btn];
        }
    }
    buttons = mutableButtons;
    if (!self.keepsPreModeTextViewWillEdited) {
        self.separatedLine.frame = [self frameSeparatedLine];
        self.avatarView.bdp_left = 16;
        self.avatarView.bdp_centerY = CGRectGetHeight(self.bounds) - TMAStickerTextViewToolbarHeight / 2.0;
        CGFloat right = self.bdp_width - TMAStickerTextViewTextViewLeftRightPadding;
        for (UIButton *button in buttons) {
            button.frame = [self frameToolbarButton];
            button.bdp_right = right;
            right += (-TMAStickerTextViewToggleButtonLength - TMAStickerTextViewToggleButtonMarginX);
        }
    } else {
        self.separatedLine.frame = CGRectZero;
        for (UIButton *button in buttons) {
            button.frame = CGRectZero;
        }
    }

    [self refreshTextUI];
}

- (CGFloat)heightThatFits {
    if (self.keepsPreModeTextViewWillEdited) {
        return TMAStickerTextViewHeight;
    } else {
        CGRect textViewRectFit = [self.textView verticalCenterContentSizeToFit];
        CGFloat textViewHeight = CGRectGetHeight(textViewRectFit);
        CGFloat textViewWidth = CGRectGetWidth(textViewRectFit);
        CGFloat minHeight = [self heightWithLine:TMAStickerTextViewMinLineCount textViewWidth:textViewWidth];
        CGFloat maxHeight = [self heightWithLine:TMAStickerTextViewMaxLineCount textViewWidth:textViewWidth];
        CGFloat calculateHeight = MIN(maxHeight, MAX(minHeight, textViewHeight));
        CGFloat height = TMAStickerTextViewTextViewTopMargin + calculateHeight + TMAStickerTextViewTextViewBottomMargin + TMAStickerTextViewToolbarHeight;
        return height;
    }
}

- (CGSize)sizeThatFits:(CGSize)size {
    return CGSizeMake(size.width, [self heightThatFits]);
}

- (void)sizeToFit {
    CGSize size = [self sizeThatFits:self.bounds.size];
    self.frame = CGRectMake(CGRectGetMinX(self.frame), CGRectGetMaxY(self.frame) - size.height, size.width, size.height);
}

- (void)removeFromSuperview {
    [super removeFromSuperview];
    if (self.bottomBGView.superview) {
        [self.bottomBGView removeFromSuperview];
    }
}

#pragma mark - public method

- (void)publishData {
    [self resignFirstResponderAndRemoveFromSuperviewWithPublish:YES];
}

- (void)collectDataWithType:(TMAStickerInputEventType)type uniqueID:(OPAppUniqueID *)uniqueID session:(NSString *)session sessionHandler:(NSDictionary *)sessionHandler completionBlock:(void (^)(void))completionBlock {
    NSString *plainText = self.plainText;
    self.model.content = plainText;
    self.model.at = nil;
    
    NSMutableAttributedString *attributedComment = [[NSMutableAttributedString alloc] initWithAttributedString:self.textView.attributedText];
    // 匹配表情
    [attributedComment tma_replaceTextToEmojiForRange:attributedComment.tma_rangeOfAll];
    // 匹配@
    NSArray<TMAAttributedStringMatchingResult *> *atMatchs = [attributedComment tma_findAllStringForAttributeName:TMAAtDataBackedStringAttributeName backedStringClass:[TMAAtDataBackedString class] inRange:[attributedComment tma_rangeOfAll]];
    NSMutableArray<TMAStickerInputAtModel *> *atsWithLarkID = [[NSMutableArray<TMAStickerInputAtModel *> alloc] init];
    NSMutableArray<TMAStickerInputAtModel *> *atsWithOpenID = [[NSMutableArray<TMAStickerInputAtModel *> alloc] init];
    NSMutableArray<NSString *> *larkIDs = [[NSMutableArray<NSString *> alloc] init];
    for (TMAAttributedStringMatchingResult *result in atMatchs) {
        TMAStickerInputAtModel *atModel = [[TMAStickerInputAtModel alloc] init];
        
        TMAAtDataBackedString *atDataBackedString = result.data;
        if (atDataBackedString && [atDataBackedString isKindOfClass:[TMAAtDataBackedString class]]) {
            atModel.larkID = atDataBackedString.larkID;
            atModel.id = atDataBackedString.openID;
            atModel.name = atDataBackedString.userName;
            atModel.offset = result.range.location;
            atModel.length = result.range.length;
            
            if (atModel.larkID.length > 0) {
                [larkIDs addObject:atModel.larkID];
                [atsWithLarkID addObject:atModel];
            } else {
                [atsWithOpenID addObject:atModel];
            }
        }
    }
    if (larkIDs.count == 0) {
        self.model.at = BDPIsEmptyArray(atsWithOpenID) ? nil : (NSArray<TMAStickerInputAtModel> *)atsWithOpenID;
        if (completionBlock) {
            completionBlock();
        }
        if (type == TMAStickerInputEventTypePublish) {
            [self clearData];
        }
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    void (^handleResult)(NSDictionary<NSString *, NSString *> *openIDs, NSError *error) = ^(NSDictionary<NSString *, NSString *> *openIDs, NSError *error) {
        __strong typeof(weakSelf) self = weakSelf;
        if (error || BDPIsEmptyDictionary(openIDs)) {
            self.model.at = BDPIsEmptyArray(atsWithOpenID) ? nil : (NSArray<TMAStickerInputAtModel> *)atsWithOpenID;
            if (type == TMAStickerInputEventTypePublish) {
                [self clearData];
            }
            !self.onError ?: self.onError(TMAStickerInputErrorTypeRequestOpenID, type);
            return;
        }
        NSMutableArray<TMAStickerInputAtModel *> *newAts = [[NSMutableArray<TMAStickerInputAtModel *> alloc] init];
        for (TMAStickerInputAtModel *atModel in atsWithLarkID) {
            NSString *larkID = atModel.larkID;
            if (larkID.length == 0) {
                continue;
            }
            NSString *openID = openIDs[larkID];
            if (openID.length > 0) {
                atModel.id = openID;
                [newAts addObject:atModel];
            }
        }
        
        NSArray<TMAStickerInputAtModel *> *mergedAtModel = [atsWithOpenID arrayByAddingObjectsFromArray:newAts];
        self.model.at = BDPIsEmptyArray(mergedAtModel) ? nil : (NSArray<TMAStickerInputAtModel> *)mergedAtModel;
        if (completionBlock) {
            completionBlock();
        }
        if (type == TMAStickerInputEventTypePublish) {
            [self clearData];
        }
    };
    
    if (self.enableApiUniteOpt) {
        OpenIDsByUserIDsModel *model = [[OpenIDsByUserIDsModel alloc] initWithUserIDs:larkIDs session:session];
        [FetchIDUtils fetchOpenIDsByUserIDsWithUniqueID:uniqueID model:model header:sessionHandler completionHandler:^(NSDictionary<NSString *,NSString *> *openIDs, NSError *error) {
            OPMonitorEvent *monitor = BDPMonitorWithName(kEventName_mp_fetch_openid, uniqueID).timing();
            if (error) {
                monitor.kv(kEventKey_result_type, kEventValue_fail).setError(error).flush();
            } else {
                monitor.kv(kEventKey_result_type, kEventValue_success).timing().flush();
            }
            handleResult(openIDs, error);
        }];
    } else {
        [self fetchOpenIDsByLarkIDs:larkIDs uniqueID:uniqueID session:session sessionHandler:sessionHandler completionHandler:^(NSDictionary<NSString *, NSString *> *openIDs, NSError *error) {
            
            handleResult(openIDs, error);
        }];
    }
}
- (void)fetchOpenIDsByLarkIDs:(NSArray<NSString *> *)larkIDs uniqueID:(OPAppUniqueID *)uniqueID session:(NSString *)session sessionHandler:(NSDictionary *)sessionHandler completionHandler:(void (^)(NSDictionary<NSString *, NSString *> *openIDs, NSError *error))completionHandler {
    if (larkIDs.count == 0) {
        return;
    }
    NSString *url = [EMAAPI openIdURL];
    if (session == nil) {
        // 新版的session在入参传入，这里适配旧版
        BDPCommon *common = [[BDPCommonManager sharedManager] getCommonWithUniqueID:uniqueID];
        session = [[TMASessionManager sharedManager] getSession:common.sandbox] ?: @"";
    }
    EMANetworkCipher *cipher = [EMANetworkCipher cipher];
    NSDictionary *params = @{
                     @"appid": uniqueID.appID ?: @"",
                     @"session": session,
                     @"userids": larkIDs,
                     @"ttcode": cipher.encryptKey ?: @""
                     };
    OPMonitorEvent *monitor = BDPMonitorWithName(kEventName_mp_fetch_openid, uniqueID).timing();
    NSMutableDictionary *header = [[NSMutableDictionary alloc] init];
    if (sessionHandler) {
        [header addEntriesFromDictionary:sessionHandler];
    }
    
    void (^handleResult)(NSData * _Nullable data, NSError * _Nullable error) = ^(NSData * _Nullable data, NSError * _Nullable error) {
        if (error) {
            monitor.kv(kEventKey_result_type, kEventValue_fail).setError(error).flush();
        } else {
            monitor.kv(kEventKey_result_type, kEventValue_success).timing().flush();
        }
        NSError *serializationError = nil;
        NSDictionary *openIDDict = [data JSONValueWithOptions:NSJSONReadingAllowFragments error:&serializationError];
        NSDictionary<NSString *, NSString *> *openIDs;
        if (!serializationError && [openIDDict isKindOfClass:[NSDictionary class]]) {
            NSString *encryptedContent = [openIDDict bdp_stringValueForKey:@"encryptedData"];
            NSDictionary *decryptedDict = [EMANetworkCipher decryptDictForEncryptedContent:encryptedContent cipher:cipher];
            if ([decryptedDict isKindOfClass:[NSDictionary class]]) {
                openIDs = [decryptedDict bdp_dictionaryValueForKey:@"openids"];
            }
            if (![openIDs isKindOfClass:[NSDictionary class]]) {
                openIDs = nil;
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completionHandler) {
                completionHandler(openIDs, serializationError ?: error);
            }
        });
    };
    
    //TODO: 网络专用 Trace, 派生了一级,勿直接使用.目前网络层级混乱,直接调了底层网络类,所以只能在这里派生(否者会和 EMARequestUtil 的封装冲突),网络重构后会统一修改 --majiaxin
    OPTrace *tracing = [EMARequestUtil generateRequestTracing:uniqueID];
    if ([OPECONetworkInterface enableECOWithPath:OPNetworkAPIPath.getOpenIDsByUserIDs]) {
        OpenECONetworkAppContext *networkContext = [[OpenECONetworkAppContext alloc] initWithTrace:tracing
                                                                                          uniqueId:uniqueID
                                                                                            source:ECONetworkRequestSourceApi];
        [OPECONetworkInterface postForOpenDomainWithUrl:url context:networkContext params:params header:header completionHandler:^(id _Nullable json, NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            handleResult(data, error);
        }];
    } else {
        [[EMANetworkManager shared] postUrl:url params:params header:header completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            handleResult(data, error);
        } eventName:@"getOpenIDsByUserIDs" requestTracing:tracing];
    }
}

- (void)clearData {
    self.model.picture = nil;
    self.model.at = nil;
    self.model.content = nil;
    
    [self clearText];
    [self.thumnailView showImageWithPath:nil];
    self.isPublishing = NO;
}

- (void)clearText {
    self.textView.text = nil;
    self.textView.font = [UIFont systemFontOfSize:TMAStickerTextViewFontSize];
    [self sizeToFit];
}

- (void)updateViews {
    NSString *text = self.model.content;
    self.textView.text = text;
    if (self.contentPlaceHolderOpt) {
        self.textView.placeholderStr = self.model.placeholder;
    } else {
        if (self.model.placeholder) {
            self.textView.placeholderStr = self.model.placeholder;
        }
    }
    self.textView.enablesReturnKeyAutomatically = !self.model.enablesReturnKey;
    NSArray<TMAStickerInputAtModel> *ats = self.model.at;

    /**
    // test @
    text = @"ii @houzhiyou word";
    self.textView.text = text;
    TMAStickerInputAtModel *atModel = [[TMAStickerInputAtModel alloc] init];
    atModel.id = @"232143214254";
    atModel.name = @"houzhiyou";
    atModel.offset = 3;
    atModel.length = 11;
    ats = (NSArray<TMAStickerInputAtModel> *)@[atModel];
     */
    
    self.atButton.hidden = !ats;
    if (ats.count > 0) {
        // 处理@联系人和表情
        [self updateText:text ats:ats];
    } else {
        // 处理表情
        [self textViewDidChange:self.textView];
    }
    
    self.avatarView.hidden = !self.model.userModelSelect;
    
    if (self.userModelSelectOpt) {
        if (BDPIsEmptyString(self.model.userModelSelect.data) || (!BDPIsEmptyArray(self.model.userModelSelect.items) && ![self.model.userModelSelect.items containsObject:self.model.userModelSelect.data])) {
            self.model.userModelSelect.data = self.model.userModelSelect.items.firstObject;
        }
    }
    __weak typeof(self) weakSelf = self;
    
    [self.avatarView configureViewsWithAvatarURL:[OPPathTransformHelper buildURLWithPath:self.model.avatar uniqueID:self.uniqueID tag:@"showRichText"] userSelectModel:self.model.userModelSelect showPickerViewCompletionBlock:^(BOOL shows) {
        __strong typeof(weakSelf) self = weakSelf;
        self.isSelectUserModelPresented = shows;
        if (shows) {
            self.textView.inputView = [[UIView alloc] init];
            // 调用reloadInputViews方法会立刻进行键盘的切换
            [self.textView reloadInputViews];
            if (![self.textView isFirstResponder]) {
                [self.textView becomeFirstResponder];
            }
            // 上面那两行 字是被新弹出的页面盖住了
            if (self.window != nil && self.window.windowLevel != UIWindowLevelNormal
                && [TMAStickerInputView wkwebviewInput]) {
                [self setHidden: YES];
            }
        } else {
            TMAKeyboardType type = self.keyboardType;
            [self changeKeyboardTo:type force:YES];
        }
    }];
    self.emojiToggleButton.hidden = !self.model.showEmoji;
    BOOL hidePicture = !self.model.picture;
    self.pictureButton.hidden = hidePicture;
    
    BOOL shouldShowImage = YES;
    NSString *absImagePath = nil;
    if (!hidePicture && (self.model.picture.count > 0)) {
        NSString *imagePath = self.model.picture.firstObject;
        OPFileObject *fileObj = [[OPFileObject alloc] initWithRawValue:imagePath];
        if (!fileObj || !self.uniqueID) {
            shouldShowImage = NO;
        } else {
            OPFileSystemContext *fsContext = [[OPFileSystemContext alloc] initWithUniqueId:self.uniqueID
                                                                                    trace:nil
                                                                                      tag:@"showRichText"
                                                                              isAuxiliary:YES];
            NSError *error = nil;
            absImagePath = [OPFileSystemCompatible getSystemFileFrom:fileObj context:fsContext error:&error];
            if (error) {
                fsContext.trace.error(@"get system file failed, hasPath: %@, error: %@", @(absImagePath != nil), error.description);
                shouldShowImage = NO;
            }
        }
    } else {
        shouldShowImage = NO;
    }
    [self.thumnailView showImageWithPath:absImagePath];
    [self showThumnailView:shouldShowImage];
    self.textView.hasPicture = shouldShowImage;
    // 当rich text各个按钮都隐藏后，同时隐藏toolBar，移除所占的空白区域
    BOOL allHidden = self.thumnailView.hidden && self.avatarView.hidden && self.atButton.hidden && self.pictureButton.hidden && self.emojiToggleButton.hidden;
    TMAStickerTextViewToolbarHeight = allHidden ? 0.0 : 48.0;

    [self setNeedsLayout];
    [self layoutIfNeeded];
}

- (NSString *)plainText {
    NSAttributedString *attributedString = self.textView.attributedText;
    if (self.contentPlaceHolderOpt) {
        NSString *text = [attributedString tma_plainTextForRange:NSMakeRange(0, attributedString.length)];
        return [text stringByReplacingOccurrencesOfString:kTMAStickerTextEmptyChar withString:@""];
    } else {
        return [attributedString tma_plainTextForRange:NSMakeRange(0, attributedString.length)];
    }
}

- (void)changeKeyboardTo:(TMAKeyboardType)toType {
    [self changeKeyboardTo:toType force:NO];
}

- (void)changeKeyboardTo:(TMAKeyboardType)toType force:(BOOL)force {
    if (!force && self.keyboardType == toType) {
        return;
    }

    switch (toType) {
        case TMAKeyboardTypeNone:
            for (TMAButton *btn in self.toolbarButtons) {
                btn.selected = NO;
            }
            self.textView.inputView = nil;
            break;
        case TMAKeyboardTypeSystem:
            // 切换到系统键盘
            self.textView.inputView = nil;
            break;
        case TMAKeyboardTypeSticker:
            // 切换到自定义的表情键盘  和志友对了一下，目前只对头条圈开放表情
            self.textView.inputView = self.stickerKeyboard;
            break;
        case TMAKeyboardTypePicture: {
//            // 使用新的输入框形式选择图片界面
//            self.textView.inputView = self.imagePickerKeyboard;
            
            UIWindow *window = self.window ?: OPWindowHelper.fincMainSceneWindow;
            
            // 使用之前的全屏选择图片界面
            TMAKeyboardType type = self.keyboardType;
            self.textView.inputView = [[UIView alloc] init];
            UIViewController *rootViewController = window.rootViewController;
            while (rootViewController.presentedViewController) {
                rootViewController = rootViewController.presentedViewController;
            }
            UIViewController *controller = self.currentViewController;
            self.isSelectPicturesVCPresented = YES;
            
            void(^callback)(NSArray<UIImage *> *images, BOOL isOriginal, BDPImageAuthResult authResut) = ^(NSArray<UIImage *> *images, BOOL isOriginal, BDPImageAuthResult authResut) {
                self.isSelectPicturesVCPresented = NO;
                [self changeKeyboardTo:type force:YES];
                if (![self.textView isFirstResponder]) {
                    [self.textView becomeFirstResponder];
                }

                if (images.count >= 1) {
                    UIImage *image = images.firstObject;
                    // image -> path
                    NSData *imageData = UIImageJPEGRepresentation(image, 0.8);
                    //Destination AbsPath
                    NSString *fileExtension = [TMACustomHelper contentTypeForImageData:imageData];

                    OPFileObject *fileObj = [OPFileObject generateRandomTTFile:BDPFolderPathTypeTemp fileExtension:fileExtension];
                    OPFileSystemContext *fsContext = [[OPFileSystemContext alloc] initWithUniqueId:self.uniqueID trace:nil tag:@"customizedInput"];

                    NSError *error = nil;
                    BOOL result = [OPFileSystemCompatible writeSystemData:imageData to:fileObj context:fsContext error:&error];
                    if (!result || error) {
                        fsContext.trace.error(@"write systemData failed, result: %@, error: %@", @(result), error.description);
                        return;
                    }
                    [self selectPicture:image path:fileObj.rawValue];
                }
            };
            
            if (self.useLarkPhotoPicker) {
                BDPChooseImagePluginModel *model = [[BDPChooseImagePluginModel alloc] init];
                model.count = 1;
                model.bdpSourceType = BDPImageSourceTypeAlbum | BDPImageSourceTypeCamera;
                model.bdpSizeType = BDPImageSizeTypeCompressed;
                model.cameraDevice = @"back";
                [BDPPluginImageCustomImpl.sharedPlugin bdp_chooseImageWithModel:model fromController:controller completion:callback];
            } else {
                [EMAImagePicker pickImageWithMaxCount:1
                                       allowAlbumMode:YES
                                      allowCameraMode:YES
                                     isOriginalHidden:YES
                                           isOriginal:NO
                                         singleSelect:NO
                                         cameraDevice:@"back"
                                                   in:controller
                                       resultCallback:callback];
            }
            break;
        }
        case TMAKeyboardTypeAt: {
            
            __weak typeof(self) weakSelf = self;
            dispatch_block_t _Nullable (^selectedBlock)(NSArray<NSString *> * _Nullable chatterNames, NSArray<NSString *> * _Nullable chatterIDs, NSArray<NSString *> * _Nullable departmentIDs) = ^dispatch_block_t (NSArray<NSString *> * _Nullable chatterNames, NSArray<NSString *> * _Nullable chatterIDs, NSArray<NSString *> * _Nullable departmentIDs) {
                __strong typeof(weakSelf) self = weakSelf;
                if (chatterNames.count > 0 && self.isAtCharaterInputedToAlert) {
                    // 选人成功才需要去掉原先加的@
                    [self removeAtCharacterIfNeeded];
                }
                self.isAtCharaterInputedToAlert = NO;
                for (int i = 0; i < chatterNames.count; i++) {
                    if (i >= chatterIDs.count) {
                        break;
                    }

                    NSString *chatterName = chatterNames[i];
                    NSString *chatterID = chatterIDs[i];
                    [self addAtName:chatterName ID:chatterID];
                }

                if (!self.isSelectChatterNamesVCPresented) {
                    return nil;
                }

                return ^{
                    // 说明已经选择完或者取消选择联系人
                    self.isSelectChatterNamesVCPresented = NO;
                    
                    TMAKeyboardType type = self.keyboardType;
                    if (type == TMAKeyboardTypeSticker) {
                        [self toolbarButtonClicked:self.emojiToggleButton];
                    }
                    [self changeKeyboardTo:type force:YES];
                    
                    if (![self.textView isFirstResponder]) {
                        [self.textView becomeFirstResponder];
                    }
                };
            };

            if ([EMARouteMediator sharedInstance].getPickChatterVCBlock) {
                self.textView.inputView = [[UIView alloc] init];
                
                UIViewController *vc = [EMARouteMediator sharedInstance].getPickChatterVCBlock(YES, NO, self.model.externalContact, nil, nil, NO, nil, NO, 0, nil, nil, nil);
                __weak typeof(self) weakSelf = self;
                [EMARouteMediator sharedInstance].selectChatterNamesBlock = selectedBlock;
                self.isSelectChatterNamesVCPresented = YES;
                vc.modalPresentationStyle = UIModalPresentationFullScreen;
                [self.currentViewController presentViewController:vc animated:YES completion:nil];
            } else {
                BDPLogError(@"getPickChatterVC error: noBlock");
            }
        }
        default:
            break;
    }
    // 调用reloadInputViews方法会立刻进行键盘的切换
    [self.textView reloadInputViews];
    if (toType != TMAKeyboardTypeAt && toType != TMAKeyboardTypePicture) {
        self.keyboardType = toType;
    } else if (toType == TMAKeyboardTypeAt) {
        // 由于调起Lark的选择联系人界面后，如果没有取消选择，则没有回调，故这里先把键盘收起
        [self.textView resignFirstResponder];
        [self deselectToolbarButtons];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self.textView.inputView = nil;
        });
    }
    
    if (self.window != nil && self.window.windowLevel != UIWindowLevelNormal
        && [TMAStickerInputView wkwebviewInput]) {
        BOOL hide = toType == TMAKeyboardTypeAt || toType == TMAKeyboardTypePicture;
        [self setHidden:hide];
    }
}

#pragma mark - getter / setter

- (TMAStickerTextView *)textView {
    if (!_textView) {
        _textView = [[TMAStickerTextView alloc] initWithFrame:self.bounds returnKeyOpt:self.contentPlaceHolderOpt];
        _textView.delegate = self;
        _textView.backgroundColor = [UIColor clearColor];
        _textView.font = [UIFont systemFontOfSize:TMAStickerTextViewFontSize];
        _textView.textColor = UDOCColor.textTitle;
        _textView.scrollsToTop = NO;
        /* todo: @孟令伟说3.7暂时不上，安卓需要调研
        if ([self.model.confirmType isEqualToString:@"send"]) {
            _textView.returnKeyType = UIReturnKeySend;
        } else if ([self.model.confirmType isEqualToString:@"search"]) {
            _textView.returnKeyType = UIReturnKeySearch;
        } else if ([self.model.confirmType isEqualToString:@"next"]) {
            _textView.returnKeyType = UIReturnKeyNext;
        } else if ([self.model.confirmType isEqualToString:@"go"]) {
            _textView.returnKeyType = UIReturnKeyGo;
        } else if ([self.model.confirmType isEqualToString:@"done"]) {
            _textView.returnKeyType = UIReturnKeyDone;
        } else {
            _textView.returnKeyType = UIReturnKeySend;
        }
         */
        _textView.returnKeyType = UIReturnKeySend;
        if (self.model.enablesReturnKey) {
            _textView.enablesReturnKeyAutomatically = NO;
        } else {
            _textView.enablesReturnKeyAutomatically = YES;
        }
        if (!self.contentPlaceHolderOpt) {
            _textView.placeholderStr = BDPI18n.comments_write;
        }
        _textView.emaPlaceholderColor = UDOCColor.textPlaceholder;
        _textView.textDragInteraction.enabled = NO;
    }
    return _textView;
}

- (TMAThumnailView *)thumnailView {
    if (!_thumnailView) {
        _thumnailView = ({
            TMAThumnailView *view = [[TMAThumnailView alloc] init];
            __weak typeof(self) weakSelf = self;
            view.deleteImageCompletionBlock = ^{
                __strong typeof(weakSelf) self = weakSelf;
                self.model.picture = @[];
                [self.thumnailView showImageWithPath:nil];
                [self showThumnailView:NO];
                self.textView.hasPicture = NO;
            };
            view;
        });
    }
    return _thumnailView;
}

- (UIView *)separatedLine {
    if (!_separatedLine) {
        _separatedLine = [[UIView alloc]init];
        _separatedLine.backgroundColor = UDOCColor.lineDividerDefault;
        _separatedLine.hidden = YES;
    }
    return _separatedLine;
}

- (TMAStickerAvatarView *)avatarView {
    if (!_avatarView) {
        _avatarView = [[TMAStickerAvatarView alloc] initWithFrame:CGRectZero currentViewController:self.currentViewController userModelSelectOpt:self.userModelSelectOpt];
        [_avatarView sizeToFit];
    }
    return _avatarView;
}

- (TMAButton *)toolBarButtonWithImageName:(NSString *)imageName selectedImageName:(NSString *)selectedImageName selector:(SEL)selector {
    TMAButton *button = [[TMAButton alloc] init];
    [button setImage:[UIImage ema_imageNamed:imageName] forState:UIControlStateNormal];
    [button setImage:[UIImage ema_imageNamed:selectedImageName] forState:UIControlStateSelected];
    button.touchInsets = UIEdgeInsetsMake(-12, -20, -12, -20);
    [button addTarget:self action:selector forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (TMAButton *)emojiToggleButton {
    if (!_emojiToggleButton) {
        _emojiToggleButton = [self toolBarButtonWithImageName:@"tma_emoji_bottombar" selectedImageName:@"tma_emoji_bottombar_selected" selector:@selector(toggleEmojiButtonClicked:)];
        _emojiToggleButton.tintColor = UDOCColor.iconN3;
    }
    return _emojiToggleButton;
}

- (TMAButton *)pictureButton {
    if (!_pictureButton) {
        _pictureButton = [self toolBarButtonWithImageName:@"tma_picture_bottombar" selectedImageName:@"tma_picture_bottombar_selected" selector:@selector(pictureButtonClicked:)];
        _pictureButton.tintColor = UDOCColor.iconN3;
    }
    return _pictureButton;
}

- (TMAButton *)atButton {
    if (!_atButton) {
        _atButton = [self toolBarButtonWithImageName:@"tma_at_bottombar" selectedImageName:@"tma_at_bottombar_selected" selector:@selector(atButtonClicked:)];
        _atButton.tintColor = UDOCColor.iconN3;
    }
    return _atButton;
}

- (TMAStickerKeyboard *)stickerKeyboard {
    if (!_stickerKeyboard) {
        _stickerKeyboard = [[TMAStickerKeyboard alloc] init];
        _stickerKeyboard.frame = CGRectMake(0, 0, CGRectGetWidth(self.bounds), [self.stickerKeyboard heightThatFits]);
        _stickerKeyboard.delegate = self;
    }
    return _stickerKeyboard;
}

- (UIView *)bottomBGView {
    if (!_bottomBGView) {
        _bottomBGView = [[UIView alloc] init];
        _bottomBGView.backgroundColor = UDOCColor.bgBody;
    }
    return _bottomBGView;
}

- (UIButton *)textViewAboveMaskButton {
    if (!_textViewAboveMaskButton) {
        _textViewAboveMaskButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_textViewAboveMaskButton addTarget:self action:@selector(textViewAboveMaskButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _textViewAboveMaskButton;
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    CGFloat containerHeight = [UIWindow ema_currentContainerSize:self.uniqueID.window].height;
    self.bottomBGView.frame = CGRectMake(0, CGRectGetMaxY(frame), CGRectGetWidth(self.bounds), containerHeight - CGRectGetMaxY(frame));
}

- (void)setFrame:(CGRect)frame animated:(BOOL)animated {
    if (CGRectEqualToRect(frame, self.frame)) {
        return;
    }

    if (self.window != nil && self.window.windowLevel != UIWindowLevelNormal
        && [TMAStickerInputView wkwebviewInput]) {
        NSLayoutConstraint *constraint = [self constraints].firstObject;
        constraint.constant = frame.size.height;
    }
    void (^ changesAnimations)(void) = ^{
        [self setFrame:frame];
        [self setNeedsLayout];
        [self layoutIfNeeded];
    };

    if (changesAnimations) {
        if (animated) {
            [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:changesAnimations completion:nil];
        } else {
            changesAnimations();
        }
    }
}

- (void)setKeepsPreModeTextViewWillEdited:(BOOL)keepsPreModeTextViewWillEdited {
    _keepsPreModeTextViewWillEdited = keepsPreModeTextViewWillEdited;
    if (!keepsPreModeTextViewWillEdited) {
        self.separatedLine.hidden = NO;
        self.separatedLine.frame = [self frameSeparatedLine];
    } else {
        self.separatedLine.hidden = YES;
        self.separatedLine.frame = CGRectZero;
    }
}

- (void)setModel:(TMAStickerInputModel *)model {
    _model = model;
    
    [self updateViews];
}

- (void)setModelChangedBlock:(void (^)(TMAStickerInputEventType))modelChangedBlock {
    _modelChangedBlock = modelChangedBlock;
    
    self.avatarView.modelChangedBlock = _modelChangedBlock;
}

#pragma mark - private method

- (void)refreshTextUI {
    if (!self.textView.text.length) {
        return;
    }

    UITextRange *markedTextRange = [self.textView markedTextRange];
    UITextPosition *position = [self.textView positionFromPosition:markedTextRange.start offset:0];
    if (position) {
        return;     // 正处于输入拼音还未点确定的中间状态
    }

    NSRange selectedRange = self.textView.selectedRange;

    NSMutableAttributedString *attributedComment = [[NSMutableAttributedString alloc] initWithAttributedString:self.textView.attributedText];
    [attributedComment addAttributes:@{ NSFontAttributeName: [UIFont systemFontOfSize:TMAStickerTextViewFontSize], NSForegroundColorAttributeName: UDOCColor.textTitle} range:attributedComment.tma_rangeOfAll];
    
    // 匹配@
    NSAttributedString *str = self.textView.attributedText;
    NSArray<TMAAttributedStringMatchingResult *> *atMatchs = [str tma_findAllStringForAttributeName:TMAAtDataBackedStringAttributeName backedStringClass:[TMAAtDataBackedString class] inRange:[str tma_rangeOfAll]];
    for (TMAAttributedStringMatchingResult *result in atMatchs) {
        TMAAtDataBackedString *atDataBackedString = result.data;
        if (atDataBackedString && [atDataBackedString isKindOfClass:[TMAAtDataBackedString class]]) {
            [attributedComment addAttributes:[self attributesForAtText] range:result.range];
        }
    }

    // 匹配表情
    [attributedComment tma_replaceTextToEmojiForRange:attributedComment.tma_rangeOfAll];
    [TMAStickerDataManager.sharedInstance replaceEmojiForAttributedString:attributedComment font:[UIFont systemFontOfSize:TMAStickerTextViewFontSize]];

    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineSpacing = TMAStickerTextViewLineSpacing;
    [attributedComment addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:attributedComment.tma_rangeOfAll];

    NSUInteger offset = self.textView.attributedText.length - attributedComment.length;
    self.textView.attributedText = attributedComment;
    self.textView.selectedRange = NSMakeRange(selectedRange.location - offset, 0);
}

- (CGFloat)heightWithLine:(NSInteger)lineNumber textViewWidth:(CGFloat)textViewWidth {
    NSString *onelineStr = [[NSString alloc] init];
    CGRect onelineRect = [onelineStr boundingRectWithSize:CGSizeMake(textViewWidth, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{ NSFontAttributeName: [UIFont systemFontOfSize:TMAStickerTextViewFontSize] } context:nil];
    CGFloat heigth = lineNumber * onelineRect.size.height + (lineNumber - 1) * TMAStickerTextViewLineSpacing;
    return heigth;
}

- (CGRect)frameTextView {
    CGFloat minX = (self.textView.isFirstResponder ? TMAStickerTextViewTextViewLeftRightPadding : TMAStickerTextViewTextViewUnfocusLeftRightPadding);
    CGFloat width = self.bounds.size.width - (2 * minX) - (self.thumnailView.hidden ? 0 : self.thumnailView.bdp_width);
    
    CGFloat height = 0;
    if (self.keepsPreModeTextViewWillEdited) {
        height = CGRectGetHeight(self.bounds) - 2 * TMAStickerTextViewTextViewTopMargin;
    } else {
        height = CGRectGetHeight(self.bounds) - TMAStickerTextViewTextViewTopMargin - TMAStickerTextViewTextViewBottomMargin - TMAStickerTextViewToolbarHeight;
    }
    if (height < 0) {
        height = self.bounds.size.height;
    }
    
    return CGRectMake(minX, TMAStickerTextViewTextViewTopMargin, width, height);
}

- (CGRect)frameSeparatedLine {
    return CGRectMake(0, CGRectGetHeight(self.bounds) - TMAStickerTextViewToolbarHeight, self.bounds.size.width, BDPDeviceHelper.ssOnePixel);
}

- (CGRect)frameToolbarButton {
    return CGRectMake(TMAStickerTextViewTextViewLeftRightPadding, CGRectGetHeight(self.bounds) - (TMAStickerTextViewToolbarHeight + TMAStickerTextViewToggleButtonLength) / 2, TMAStickerTextViewToggleButtonLength, TMAStickerTextViewToggleButtonLength);
}

+ (BOOL)wkwebviewInput {
    BDPPlugin(appEnginePlugin, EMAAppEnginePluginDelegate);
    return [appEnginePlugin.onlineConfig wkwebviewInput];
}

#pragma mark actions

- (void)deselectToolbarButtons {
    for (TMAButton *btn in self.toolbarButtons) {
        btn.selected = NO;
    }
}

- (void)toolbarButtonClicked:(id)sender {
    [self deselectToolbarButtons];
    UIButton *button = (UIButton *)sender;
    button.selected = !button.selected;
    [self showTextViewCursor:NO];
}

- (void)toggleEmojiButtonClicked:(id)sender {
    [self toolbarButtonClicked:sender];
    [self changeKeyboardTo:TMAKeyboardTypeSticker];
    
    if (![self.textView isFirstResponder]) {
        [self.textView becomeFirstResponder];
    }
}

- (void)pictureButtonClicked:(id)sender {
//    // 使用新的输入框形式选择图片界面
//    [self toolbarButtonClicked:sender];
    
    [self changeKeyboardTo:TMAKeyboardTypePicture];
    if (![self.textView isFirstResponder]) {
        [self.textView becomeFirstResponder];
    }
}

- (void)atButtonClicked:(id)sender {
//    [self toolbarButtonClicked:sender];
    [self changeKeyboardTo:TMAKeyboardTypeAt];

    /*
    // test @
    NSArray<NSString *> *chatterNames = @[@"houzhiyou"];
    NSArray<NSString *> *chatterIDs = @[@"232143214254"];
    for (int i = 0; i < chatterNames.count; i++) {
        if (i >= chatterIDs.count) {
            break;
        }

        NSString *chatterName = chatterNames[i];
        NSString *chatterID = chatterIDs[i];
        [self addAtName:chatterName ID:chatterID];
    }
     */
    
}

- (void)textViewAboveMaskButtonClicked:(id)sender {
    [self showTextViewCursor:YES];
    [self deselectToolbarButtons];
    [self changeKeyboardTo:TMAKeyboardTypeSystem];
}

// 显示/隐藏UITextView的光标
- (void)showTextViewCursor:(BOOL)showsCursor {
    self.textView.tintColor = !showsCursor ? [UIColor clearColor] : nil;
    self.textViewAboveMaskButton.hidden = showsCursor;
}

#pragma mark - UITextView

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
//    self.keepsPreModeTextViewWillEdited = NO;
    if (self.keyboardType == TMAKeyboardTypeNone) {
        [self changeKeyboardTo:TMAKeyboardTypeSystem];
    }

    if ([self.delegate respondsToSelector:@selector(stickerInputViewShouldBeginEditing:)]) {
        return [self.delegate stickerInputViewShouldBeginEditing:self];
    } else {
        return YES;
    }
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    self.isAtCharaterInputedToAlert = NO;
    if ([@"\n" isEqualToString:text]) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(stickerInputViewDidClickSendButton:)]) {
            [self.delegate stickerInputViewDidClickSendButton:self];
        }
        [self publishData];
        return NO;
    }
    
    if ([text isEqualToString:@""]) {
        NSRange selectRange = textView.selectedRange;
        if (selectRange.length > 0) {
            //用户长按选择文本时不处理
            return YES;
        }
        // 判断删除的是一个@中间的字符就整体删除
        NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithAttributedString:textView.attributedText];
        NSArray<TMAAttributedStringMatchingResult *> *matches = [self findAllAts];
        BOOL inAt = NO;
        NSInteger index = range.location;
        for (TMAAttributedStringMatchingResult *match in matches) {
            NSRange newRange = NSMakeRange(match.range.location + 1, match.range.length - 1);
            if (NSLocationInRange(range.location, newRange))
            {
                inAt = YES;
                index = match.range.location;
                [attributedText replaceCharactersInRange:match.range withString:@""];
                break;
            }
        }
        if (inAt) {
            textView.attributedText = attributedText;
            textView.selectedRange = NSMakeRange(index, 0);
            [self textViewDidChange:textView];
            return NO;
        }
    } else if ([text isEqualToString:@"@"]) {
        // 在匿名回复状态下，是不能触发@的
        if (self.model.at) {
            self.isAtCharaterInputedToAlert = YES;
        }
    }

    return YES;
}

- (void)textViewDidChangeSelection:(UITextView *)textView {
    // 光标不能点落在@词中间
    NSRange range = textView.selectedRange;
    if (range.length > 0) {
        // 选择文本时可以
        return;
    }
    NSArray<TMAAttributedStringMatchingResult *> *matches = [self findAllAts];
    for (TMAAttributedStringMatchingResult *match in matches) {
        NSRange newRange = NSMakeRange(match.range.location + 1, match.range.length - 1);
        if (NSLocationInRange(range.location, newRange)) {
            textView.selectedRange = NSMakeRange(match.range.location + match.range.length, 0);
            break;
        }
    }
}

- (void)textViewDidEndEditing:(UITextView *)textView {
//    self.keepsPreModeTextViewWillEdited = YES;
//    if (kIsRefreshingForEnablesReturnKeyAutomatically) {
//        return;
//    }
    CGSize size = [self sizeThatFits:self.bounds.size];
    CGRect newFrame = CGRectMake(CGRectGetMinX(self.frame), CGRectGetMaxY(self.frame) - size.height, size.width, size.height);
    [self setFrame:newFrame animated:NO];
    
    if ([self.delegate respondsToSelector:@selector(stickerInputViewDidEndEditing:)]) {
        [self.delegate stickerInputViewDidEndEditing:self];
    }
}

- (void)textViewDidChange:(UITextView *)textView {
    [self refreshTextUI];
    
    CGSize size = [self sizeThatFits:self.bounds.size];
    CGRect newFrame = CGRectMake(CGRectGetMinX(self.frame), CGRectGetMaxY(self.frame) - size.height, size.width, size.height);
    [self setFrame:newFrame animated:NO];
    [self.textView scrollRangeToVisible:self.textView.selectedRange];

    if ([self.delegate respondsToSelector:@selector(stickerInputViewDidChange:)]) {
        [self.delegate stickerInputViewDidChange:self];
    }
    if (self.isAtCharaterInputedToAlert) {
        [self atButtonClicked:self.atButton];
    }
    [self.textView updateEmptyCharaterIfNeeded];
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    if ([self.textView isFirstResponder]) {
        return YES;
    }
    return [super pointInside:point withEvent:event];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint touchPoint = [touch locationInView:self];
    if (!CGRectContainsPoint(self.bounds, touchPoint)) {
        [self resignFirstResponderAndRemoveFromSuperviewWithPublish:NO];
    } else {
        [super touchesBegan:touches withEvent:event];
    }
}

- (BOOL)isFirstResponder {
    return [self.textView isFirstResponder];
}

- (BOOL)becomeFirstResponder {
    return [self.textView becomeFirstResponder];
}

- (BOOL)resignFirstResponder {
    [super resignFirstResponder];
//    self.keepsPreModeTextViewWillEdited = YES;
    [self deselectToolbarButtons];
    [self changeKeyboardTo:TMAKeyboardTypeNone];
    [self setNeedsLayout];
    if (self.enableKeyboardOpt && [self isHardwareOrFloatingKeyboard]) {
        [self hideViewWithDuration:0.25];
    }
    return [self.textView resignFirstResponder];
}

- (void)resignFirstResponderAndRemoveFromSuperviewWithPublish:(BOOL)publish {
    self.isPublishing = publish;
    // option 1. 发送：立即向js发消息
    // option 2. 隐藏：等待键盘收起事件再向js发消息
    if (publish) {
        [self publishOrHideText:publish];
    }
    
    if ([self isFirstResponder]) {
        [self resignFirstResponder];
    }
}

- (void)publishOrHideText:(BOOL)publish {
    TMAStickerInputEventType eventType = publish ? TMAStickerInputEventTypePublish : TMAStickerInputEventTypeHide;
    if (self.modelChangedBlock) {
        self.modelChangedBlock(eventType);
    }
}

#pragma mark - OPComponentKeyboardDelegate

- (void)keyboardWillShowWithKeyboardInfo:(OPComponentKeyboardInfo *)keyboardInfo {
    [self showViewWithKeyboardFrame:keyboardInfo.keyboardFrame duration:keyboardInfo.animDuration];
}

- (void)keyboardWillHideWithKeyboardInfo:(OPComponentKeyboardInfo *)keyboardInfo {
    if ([self isHardwareOrFloatingKeyboard]) {
        [self showViewWithKeyboardFrame:keyboardInfo.keyboardFrame duration:keyboardInfo.animDuration];
        return;
    }
    [self hideViewWithDuration:keyboardInfo.animDuration];
}

- (BOOL)isOwningViewFirstResponder {
    return self.isFirstResponder;
}

#pragma mark - Keyboard

- (void)showViewWithKeyboardFrame:(CGRect)keyboardFrame duration:(NSTimeInterval)duration {
    if (!self.superview) {
        return;
    }
    
    if (self.window != nil && self.window.windowLevel != UIWindowLevelNormal && [TMAStickerInputView wkwebviewInput]) {
        return;
    }
    
    [self.superview insertSubview:self.bottomBGView belowSubview:self];
    
    CGRect inputViewFrame = self.frame;
    CGFloat inputViewHeightFit = [self heightThatFits];
    inputViewFrame.size.height = inputViewHeightFit;
    if ([self isHardwareOrFloatingKeyboard]) {
        inputViewFrame.origin.y = self.superview.bounds.size.height - inputViewHeightFit - self.superview.safeAreaInsets.bottom;
    } else {
        inputViewFrame.origin.y = keyboardFrame.origin.y - inputViewHeightFit;
    }
    
    [UIView animateWithDuration:duration animations:^{
        self.frame = inputViewFrame;
    }];
}

- (void)hideViewWithDuration:(NSTimeInterval)duration {
    if (self.bottomBGView.superview) {
        [self.bottomBGView removeFromSuperview];
    }
    
    if (!self.superview) {
        return;
    }
    
    BOOL isPublishOrHide = (!self.isSelectPicturesVCPresented && !self.isSelectChatterNamesVCPresented && !self.isSelectUserModelPresented && !self.isPublishing);
    [UIView animateWithDuration:duration animations:^{
        if (self.window != nil && self.window.windowLevel != UIWindowLevelNormal && [TMAStickerInputView wkwebviewInput]) {
            return;
        }
        self.bdp_top = CGRectGetHeight(self.superview.bounds);
    } completion:^(BOOL finished) {
        // 确保不是以下情况才向js传递hide事件，即确保是要收起键盘不再评论:
        // 1. 不是正在选择图片
        // 2. 不是正在选择联系人
        // 3. 不是正在选择实名/匿名
        // 4. 不是正在发送
        if (isPublishOrHide) {
            [self publishOrHideText:NO];
        }
    }];
}

- (BOOL)isHardwareOrFloatingKeyboard {
    return [self.keyboardHelper isHardwareKeyboard] || [self.keyboardHelper isFloatOrSplitKeyboard];
}

- (void)keyboardWillShow:(NSNotification *)notification {
    if (!self.superview) {
        return;
    }
    
    if (self.window != nil && self.window.windowLevel != UIWindowLevelNormal
        && [TMAStickerInputView wkwebviewInput]) {
        return;
    }
    
    [self.superview insertSubview:self.bottomBGView belowSubview:self];
    
    UIWindow *window = self.window ?: OPWindowHelper.fincMainSceneWindow;
    
    NSDictionary *userInfo = [notification userInfo];
    NSTimeInterval duration = [userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    CGRect keyboardFrame = [userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect convertedKeyboardFrame = [window convertRect:keyboardFrame toView:self.superview];
    CGRect inputViewFrame = self.frame;
    CGFloat inputViewHeightFit = [self heightThatFits];
    inputViewFrame.size.height = inputViewHeightFit;
    inputViewFrame.origin.y = convertedKeyboardFrame.origin.y - inputViewHeightFit;
    
    [UIView animateWithDuration:duration animations:^{
        self.frame = inputViewFrame;
    }];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    NSDictionary *userInfo = [notification userInfo];
    NSTimeInterval duration = [userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    [self hideViewWithDuration:duration];
}

#pragma mark - TMAStickerKeyboardDelegate

- (void)stickerKeyboard:(TMAStickerKeyboard *)stickerKeyboard didClickEmoji:(TMAEmoji *)emoji {
    if (!emoji) {
        return;
    }

    UIImage *emojiImage = [TMAEmotionResource imageBy:emoji.imageName];
    if (!emojiImage) {
        return;
    }

    NSRange selectedRange = self.textView.selectedRange;
    NSString *emojiString = [NSString stringWithFormat:@"[%@]", emoji.emojiDescription];
    NSMutableAttributedString *emojiAttributedString = [[NSMutableAttributedString alloc] initWithString:emojiString];
    [emojiAttributedString tma_setTextBackedString:[TMATextBackedString stringWithString:emojiString] range:emojiAttributedString.tma_rangeOfAll];

    NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithAttributedString:self.textView.attributedText];
    [attributedText replaceCharactersInRange:selectedRange withAttributedString:emojiAttributedString];
    self.textView.attributedText = attributedText;
    self.textView.selectedRange = NSMakeRange(selectedRange.location + emojiAttributedString.length, 0);

    [self textViewDidChange:self.textView];
}

- (void)stickerKeyboardDidClickDeleteButton:(TMAStickerKeyboard *)stickerKeyboard {
    NSRange selectedRange = self.textView.selectedRange;
    if (selectedRange.location == 0 && selectedRange.length == 0) {
        return;
    }

    NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithAttributedString:self.textView.attributedText];
    if (selectedRange.length > 0) {
        [attributedText deleteCharactersInRange:selectedRange];
        self.textView.attributedText = attributedText;
        self.textView.selectedRange = NSMakeRange(selectedRange.location, 0);
    } else {
        // 处理删除@联系人的情况
        BOOL shouldChange = [self textView:self.textView shouldChangeTextInRange:NSMakeRange(selectedRange.location - 1, 1) replacementText:@""];
        if (shouldChange) {
            [attributedText deleteCharactersInRange:NSMakeRange(selectedRange.location - 1, 1)];
            self.textView.attributedText = attributedText;
            self.textView.selectedRange = NSMakeRange(selectedRange.location - 1, 0);
        }
    }

    [self textViewDidChange:self.textView];
}

- (void)stickerKeyboardDidClickSendButton:(TMAStickerKeyboard *)stickerKeyboard {
    if (self.delegate && [self.delegate respondsToSelector:@selector(stickerInputViewDidClickSendButton:)]) {
        [self.delegate stickerInputViewDidClickSendButton:self];
    }
    [self publishData];
}

#pragma mark - picture selector

- (void)showThumnailView:(BOOL)shows {
    self.thumnailView.hidden = !shows;
    CGFloat widthDelta = (shows ? -1 : 1) * self.thumnailView.bdp_width;
    self.textView.bdp_width += widthDelta;
}

#pragma mark TMAImagePickerKeyboardDelegate

///// 将要显示从相册选择视图控制器
//- (void)imagePickerKeyboardWillShowPhotoLibraryOrPhotoPreviewerController:(TMAImagePickerKeyboard *)imagePickerKeyboard {
//    [self resignFirstResponder];
//    self.imagePickerKeyboard = nil;
//}
//
///// 隐藏从相册选择视图控制器后
//- (void)imagePickerKeyboardDidHidePhotoLibraryOrPhotoPreviewerController:(TMAImagePickerKeyboard *)imagePickerKeyboard {
//    [self pictureButtonClicked:self.pictureButton];
//}
//
///// 没有访问权限
//- (void)imagePickerKeyboardPermissionDenied:(TMAImagePickerKeyboard *)imagePickerKeyboard {
//    [self resignFirstResponder];
//    self.imagePickerKeyboard = nil;
//}
//
///// 照片选择完成之后的回调
//- (void)imagePickerKeyboard:(TMAImagePickerKeyboard *)imagePickerKeyboard didFinishPickingPhotos:(NSArray<UIImage *> *)photos imageFilePaths:(NSArray<NSString *> *)imageFilePaths {
//    if (photos.count > 0 && imageFilePaths.count > 0) {
//        UIImage *image = photos.firstObject;
//        NSString *path = imageFilePaths.firstObject;
//        [self selectPicture:image path:path];
//    }
//}
//
///// 用户拍照完成之后的回调，如果拍照的同时有选择照片，则assets不为空
//- (void)imagePickerKeyboard:(TMAImagePickerKeyboard *)imagePickerKeyboard didFinishTakePhoto:(UIImage *)photo imageFilePath:(NSString *)imageFilePath {
//    if (photo) {
//        [self selectPicture:photo path:imageFilePath];
//    }
//}

- (void)selectPicture:(UIImage *)picture path:(NSString *)path {
    if (!(picture && path)) {
        return;
    }
    
    [self.thumnailView showImage:picture];
    [self showThumnailView:YES];
    self.textView.hasPicture = YES;
    self.model.picture = @[path];
    if (self.modelChangedBlock) {
        self.modelChangedBlock(TMAStickerInputEventTypePicSelect);
    }
}

#pragma mark - @联系人

- (NSDictionary<NSAttributedStringKey, id> *)attributesForAtText {
    return @{
             NSFontAttributeName: [UIFont systemFontOfSize:TMAStickerTextViewFontSize],
             NSForegroundColorAttributeName: UDOCColor.primaryPri500
             };
}

/// 初始化会走这段逻辑
- (void)updateText:(NSString *)text ats:(NSArray<TMAStickerInputAtModel> *)ats {
    NSMutableAttributedString *attributedText = nil;
    if (text.length > 0) {
        attributedText = [[NSMutableAttributedString alloc] initWithString:text attributes:nil];
        for (TMAStickerInputAtModel *model in ats) {
            if (!(model.name && model.id)) {
                continue;
            }
            NSRange fullRange = attributedText.tma_rangeOfAll;
            if (model.offset < 0 || model.length < 0 || (model.offset + model.length > fullRange.length)) {
                continue;
            }
            
            NSString *name = model.name;
            NSString *ID = model.id;
            NSUInteger loc = model.offset;
            NSUInteger len = model.length;
            NSRange selectedRange = NSMakeRange(loc, len);
            
            /// 初始化的时候，@xxx不要自动在后面补充空格
            NSString *atString = [NSString stringWithFormat:@"@%@", name];
            NSMutableAttributedString *atAttributedString = [[NSMutableAttributedString alloc] initWithString:atString];
            [atAttributedString addAttributes:[self attributesForAtText] range:NSMakeRange(0, atString.length)];
            TMAAtDataBackedString *atDataBackedString = [TMAAtDataBackedString stringWithString:atString larkID:nil openID:ID userName:name];
            [atAttributedString tma_setAtDataBackedString:atDataBackedString range:atAttributedString.tma_rangeOfAll];
            
            [attributedText replaceCharactersInRange:selectedRange withAttributedString:atAttributedString];
        }
    }
    self.textView.attributedText = attributedText;
    
    [self textViewDidChange:self.textView];
}

- (void)removeAtCharacterIfNeeded {
    NSRange selectedRange = self.textView.selectedRange;
    // 移除之前的@字符
    // NSRange.location 类型是NSUInteger 为0 的话 0 - 1 = 2^64 - 1，会造成越界，这里判断下location的合法性
       // https://slardar.bytedance.net/node/app_detail/?aid=1664&os=iOS#/abnormal/detail/crash/1664_4cb3e51723ac79dcbbb006aafe01c557
       if (selectedRange.location == 0) { return; }
       NSInteger startLoction = selectedRange.location - 1;
       if (startLoction >= 0 &&
           self.textView.attributedText.length >= selectedRange.location &&
           [[self.textView.attributedText attributedSubstringFromRange:NSMakeRange(startLoction, 1)].string isEqualToString:@"@"] ) {
           NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithAttributedString:self.textView.attributedText];
           [attributedString replaceCharactersInRange:NSMakeRange(startLoction, 1) withString:@""];
           self.textView.attributedText = attributedString;
           selectedRange = NSMakeRange(startLoction, selectedRange.length);
           self.textView.selectedRange = selectedRange;
       }
}

/// 点击at按钮或者输入at
- (void)addAtName:(NSString *)name ID:(NSString *)ID {
    if (name.length > 0 && ID.length > 0) {
        BDPLogDebug(@"%@", BDPParamStr(name, ID));
    }
    
    NSRange selectedRange = self.textView.selectedRange;
    /// 手工输入@选择联系人或者点击@按钮，还是需要自动补充一个空格
    NSString *atString = [NSString stringWithFormat:@"@%@ ", name];
    NSMutableAttributedString *atAttributedString = [[NSMutableAttributedString alloc] initWithString:atString];
    [atAttributedString addAttributes:[self attributesForAtText] range:NSMakeRange(0, atString.length)];
    TMAAtDataBackedString *atDataBackedString = [TMAAtDataBackedString stringWithString:atString larkID:ID openID:nil userName:name];
    [atAttributedString tma_setAtDataBackedString:atDataBackedString range:atAttributedString.tma_rangeOfAll];
    
    NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithAttributedString:self.textView.attributedText];
    [attributedText replaceCharactersInRange:selectedRange withAttributedString:atAttributedString];
    self.textView.attributedText = attributedText;
    self.textView.selectedRange = NSMakeRange(selectedRange.location + atAttributedString.length, 0);
    
    [self textViewDidChange:self.textView];
}

/// 匹配所有@
- (NSArray<TMAAttributedStringMatchingResult *> *)findAllAts {
    NSAttributedString *str = self.textView.attributedText;
    NSArray<TMAAttributedStringMatchingResult *> *atMatchs = [str tma_findAllStringForAttributeName:TMAAtDataBackedStringAttributeName backedStringClass:[TMAAtDataBackedString class] inRange:[self.textView.attributedText tma_rangeOfAll]];
    return atMatchs;
}

/// 匹配所有emoji
- (NSArray<TMAAttributedStringMatchingResult *> *)findAllEmojis {
    NSAttributedString *str = self.textView.attributedText;
    NSArray<TMAAttributedStringMatchingResult *> *emojiMatchs = [str tma_findAllStringForAttributeName:TMATextBackedStringAttributeName backedStringClass:[TMATextBackedString class] inRange:[self.textView.attributedText tma_rangeOfAll]];
    return emojiMatchs;
}

@end
