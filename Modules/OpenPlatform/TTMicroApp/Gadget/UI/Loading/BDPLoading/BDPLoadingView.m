//
//  BDPLoadingView.m
//  Timor
//
//  Created by liubo on 2018/12/10.
//

#import "BDPLoadingView.h"
#import <OPFoundation/BDPUtils.h>
#import <OPFoundation/BDPBundle.h>
#import <OPFoundation/BDPImageView.h>
#import <OPFoundation/BDPNetworking.h>
#import <OPFoundation/BDPTimorClient.h>
#import <OPFoundation/BDPDeviceHelper.h>
#import <OPFoundation/BDPStyleCategoryDefine.h>
#import "BDPLoadingAnimationView.h"

#import <OPFoundation/UIColor+BDPExtension.h>
#import <OPFoundation/UIView+BDPExtension.h>
#import <OPFoundation/UIView+BDPAppearance.h>
#import <OPFoundation/BDPSettingsManager+BDPExtension.h>
#import <OPFoundation/BDPI18n.h>
#import <OPFoundation/BDPUniqueID.h>
#import <OPFoundation/OPFoundation-Swift.h>
#import <UniverseDesignColor/UniverseDesignColor-Swift.h>

@interface BDPLoadingView ()

@property (nonatomic, strong) BDPUniqueID *uniqueID;
@property (nonatomic, assign) BDPType type;
@property (nonatomic, assign) BDPLoadingViewState state;
@property (nonatomic, copy) NSString *tipInfoString;
@property (nonatomic, strong) BDPModel *appModel;

// Common
@property (nonatomic, strong) BDPImageView *icon;
@property (nonatomic, strong) UILabel *name;
@property (nonatomic, strong) UILabel *percent;
@property (nonatomic, strong) BDPLoadingAnimationView *loadingView;
@property (nonatomic, strong) UILabel *tipInfo;
@property (nonatomic, strong) UILabel *actionInfo;
@property (nonatomic, strong) UIButton *actionButton;
@property (nonatomic, assign) CGFloat tipInfoMargin; // 2019-12-24 bugfix：UI稿是文字到文字的距离，EE的国际化需求将tipInfo改为多行后，首行有行间距问题需要额外考虑。

@property (nonatomic, assign) BOOL animating;
@property (nonatomic, assign) BOOL viewSetuped;
@property (nonatomic, assign) BOOL needUpdateTipInfo;

// App
@property (nonatomic, strong) UIView *customLoadingView;
@property (nonatomic, strong) UIImageView *customLoadFailIcon;

@end

@implementation BDPLoadingView

#pragma mark - Init

- (instancetype)initWithFrame:(CGRect)frame type:(BDPType)type delegate:(id<BDPLoadingViewDelegate>)delegate uniqueID:(BDPUniqueID *)uniqueID {
    if (self = [super initWithFrame:frame]) {
        self.type = type;
        self.delegate = delegate;
        self.state = BDPLoadingViewStateLoading;
        _uniqueID = uniqueID;
        // 在有缓存的快速冷启动下，主线程首次调用就会初始化并开启子进程加载WebView, 放到runloop后再开始setupViews可以起到提前WebView开始加载时间的效果
        WeakSelf;
        BDPExecuteOnMainQueue(^{
            StrongSelfIfNilReturn;
            [self setupCustomLoadingView];
            [self buildAppLoadingView];
        });
    }
    return self;
}

#pragma mark - Build Loading View

- (void)setupCustomLoadingView {
    if (self.customLoadingView == nil &&
        (self.type == BDPTypeNativeApp)) {
        // 新的loadingView传入方式
        BDPPlugin(loadingViewPlugin, BDPLoadingViewPluginDelegate);
        if (loadingViewPlugin != nil && [loadingViewPlugin respondsToSelector:@selector(bdp_getLoadingViewWithConfig:)]) {
            NSMutableDictionary *config = NSMutableDictionary.dictionary;
            config[kBDPLoadingViewConfigUniqueID] = self.uniqueID;
            self.customLoadingView = [loadingViewPlugin bdp_getLoadingViewWithConfig:config.copy];
        }
    }
}

- (void)buildAppLoadingView {
    if (self.style == BDPLoadingViewStyleCustom) { // 使用脱敏方案的加载页面
        [self buildLoadingViewForCustom];
    } else { // 使用默认的加载页面
        [self buildLoadingViewForInternal];
    }
    
    self.viewSetuped = YES;
    
    if (self.appModel) {
        [self updateAppModel:self.appModel];
    }
    
    if (self.animating) {
        [self.loadingView startLoading];
    }
    
    if (self.needUpdateTipInfo) {
        [self changeToFailState:self.state withTipInfo:self.tipInfoString];
        self.needUpdateTipInfo = NO;
    }
}

- (void)buildLoadingViewForCustom {
    self.backgroundColor = UDOCColor.bgBody;
    
    // Load Fail Icon
    self.customLoadFailIcon = [[UIImageView alloc] initWithFrame:CGRectMake((self.bdp_width - 150.f) / 2.f, self.bdp_centerY - 80.f, 150.f, 80.f)];
    self.customLoadFailIcon.image = [UIImage imageNamed:@"custom_loading_error" inBundle:[BDPBundle mainBundle] compatibleWithTraitCollection:nil];
    [self addSubview:self.customLoadFailIcon];
    
    // TipInfo
    UIFont *tipInfoFont = [UIFont systemFontOfSize:16];
    self.tipInfoMargin = (tipInfoFont.lineHeight - 16.f) / 2.f;
    self.tipInfo = [[UILabel alloc] initWithFrame:CGRectMake(0, self.customLoadFailIcon.bdp_bottom + 12.f, 136.f, tipInfoFont.lineHeight)];
    self.tipInfo.font = tipInfoFont;
    self.tipInfo.textColor = [UIColor colorWithHexString:@"999999"];
    self.tipInfo.numberOfLines = 0;
    self.tipInfo.hidden = YES;
    [self addSubview:self.tipInfo];
    
    // ActionInfo
    self.actionInfo = [[UILabel alloc] initWithFrame:CGRectMake(0, self.customLoadFailIcon.bdp_bottom + 12.f, 64.f, 16.f)];
    self.actionInfo.font = [UIFont systemFontOfSize:16];
    self.actionInfo.textColor = [UIColor colorWithHexString:@"2A90D7"];
    self.actionInfo.hidden = YES;
    [self addSubview:self.actionInfo];
    
    // ActionButton
    self.actionButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.actionButton.frame = self.actionInfo.frame;
    self.actionButton.backgroundColor = [UIColor clearColor];
    self.actionButton.hidden = YES;
    [self.actionButton addTarget:self action:@selector(actionButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.actionButton];
    
    // Custom Loading View
    self.customLoadingView.frame = self.bounds;
    self.customLoadingView.hidden = NO;
    [self addSubview:self.customLoadingView];
}
    
- (void)buildLoadingViewForInternal {
    self.backgroundColor = [UIColor colorWithHexString:@"FFFFFF"];
    
    //App Icon
    BOOL isLandscape = (self.bdp_width > self.bdp_height) ? YES : NO;
    self.icon = [[BDPImageView alloc] initWithFrame:CGRectMake((self.bdp_width - 66) / 2.0, isLandscape ? 120 : 224, 66, 66)];
    self.icon.bdp_styleCategories = @[BDPStyleCategoryLogo];
    self.icon.backgroundColor = [UIColor colorWithHexString:@"F4F5F6"];
    [self addSubview:self.icon];
    
    // App Name
    self.name = [[UILabel alloc] initWithFrame:CGRectMake(0, self.icon.bdp_bottom + 10, 136, 17)];
    self.name.font = [UIFont systemFontOfSize:17];
    self.name.textColor = [UIColor colorWithHexString:@"222222"];
    self.name.hidden = YES;
    [self addSubview:self.name];
    
    // LoadingAnimationView
    self.loadingView = [[BDPLoadingAnimationView alloc] initWithFrame:CGRectMake(0, self.name.bdp_bottom + 36.f, self.bdp_width, 6.0f)];
    [self addSubview:self.loadingView];
    
    // Percent
    self.percent = [[UILabel alloc] initWithFrame:CGRectMake((self.bdp_width - 50)/2.0, self.loadingView.bdp_bottom + 10, 50, 16)];
    self.percent.textAlignment = NSTextAlignmentCenter;
    self.percent.text = @"0%";
    self.percent.hidden = YES;
    self.percent.font = [UIFont systemFontOfSize:16];
    [self addSubview:self.percent];
    
    // TipInfo
    UIFont *tipInfoFont = [UIFont systemFontOfSize:16];
    self.tipInfoMargin = (tipInfoFont.lineHeight - 16.f) / 2.f;
    self.tipInfo = [[UILabel alloc] initWithFrame:CGRectMake(0, self.name.bdp_bottom + 23.f, 136.f, tipInfoFont.lineHeight)];
    self.tipInfo.font = tipInfoFont;
    self.tipInfo.textColor = [UIColor colorWithHexString:@"999999"];
    self.tipInfo.numberOfLines = 0;
    self.tipInfo.hidden = YES;
    [self addSubview:self.tipInfo];
    
    // ActionInfo
    self.actionInfo = [[UILabel alloc] initWithFrame:CGRectMake(0, self.name.bdp_bottom + 23.f, 64.f, 16.f)];
    self.actionInfo.font = [UIFont systemFontOfSize:16];
    self.actionInfo.textColor = [UIColor colorWithHexString:@"2A90D7"];
    self.actionInfo.hidden = YES;
    [self addSubview:self.actionInfo];
    
    // ActionButton
    self.actionButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.actionButton.frame = self.actionInfo.frame;
    self.actionButton.backgroundColor = [UIColor clearColor];
    self.actionButton.hidden = YES;
    [self.actionButton addTarget:self action:@selector(actionButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.actionButton];
}

#pragma mark - Override

- (BDPLoadingViewStyle)style {

    if (self.customLoadingView != nil &&
        (self.type == BDPTypeNativeApp)) {
        // 对于小程序，有自定义loadingView，采用自定义Loading
        // 对于小游戏，有自定义loadingView，并且打开了脱敏开关，才采用自定义Loading
        return BDPLoadingViewStyleCustom;
            
    } else {
        return BDPLoadingViewStyleInternal;
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    if (self.style == BDPLoadingViewStyleCustom) { // 使用脱敏方案的加载页面
        [self layoutSubviewsForCustom];
    } else { // 使用默认的加载页面
        [self layoutSubviewsForInternal];
    }
}

- (void)layoutSubviewsForCustom {
    // Load Fail Icon
    self.customLoadFailIcon.frame = CGRectMake((self.bdp_width - 150.f) / 2.f, self.bdp_centerY - 80.f, 150.f, 80.f);
    
    if (self.state == BDPLoadingViewStateFail || self.state == BDPLoadingViewStateSlow) {
        // TipInfo
        self.tipInfo.frame = CGRectMake((self.bdp_width - self.tipInfo.bdp_width) / 2.f, self.customLoadFailIcon.bdp_bottom + 12.f - self.tipInfoMargin, self.tipInfo.bdp_width, self.tipInfo.bdp_height);
    } else if (self.state == BDPLoadingViewStateFailReload || self.state == BDPLoadingViewStateSlowDebug || self.state == BDPLoadingViewStateFailReloadImmediately) {
        CGFloat totalWidth = self.tipInfo.bdp_width + 8.f + self.actionInfo.bdp_width;
        if (totalWidth > self.bdp_width - 75.f * 2.f) {
            // actionInfo单独一行
            // TipInfo
            self.tipInfo.frame = CGRectMake((self.bdp_width - self.tipInfo.bdp_width) / 2.f, self.customLoadFailIcon.bdp_bottom + 12.f - self.tipInfoMargin, self.tipInfo.bdp_width, self.tipInfo.bdp_height);
            
            // ActionInfo & ActionButton
            self.actionInfo.frame = CGRectMake((self.bdp_width - self.actionInfo.bdp_width) / 2.f, self.tipInfo.bdp_bottom - self.tipInfoMargin + 9.f, self.actionInfo.bdp_width, self.actionInfo.bdp_height);
            self.actionButton.frame = self.actionInfo.frame;
        } else {
            // actionInfo与tipInfo同一行
            // TipInfo
            self.tipInfo.frame = CGRectMake((self.bdp_width - totalWidth) / 2.f, self.customLoadFailIcon.bdp_bottom + 12.f - self.tipInfoMargin, self.tipInfo.bdp_width, self.tipInfo.bdp_height);
            
            // ActionInfo & ActionButton
            self.actionInfo.frame = CGRectMake(self.tipInfo.bdp_right + 8.f, self.customLoadFailIcon.bdp_bottom + 12.f, self.actionInfo.bdp_width, self.actionInfo.bdp_height);
            self.actionButton.frame = self.actionInfo.frame;
        }
    }
    
    // Custom Loading View
    self.customLoadingView.frame = self.bounds;
}

- (void)layoutSubviewsForInternal {
    // App Name
    BOOL isLandscape = (self.bdp_width > self.bdp_height) ? YES : NO;
    CGFloat nameY = self.bdp_centerY - (isLandscape ? 0.f : self.name.bdp_height);
    self.name.frame = CGRectMake((self.bdp_width - self.name.bdp_width) / 2.f, nameY, self.name.bdp_width, self.name.bdp_height);
    
    // App Icon
    self.icon.frame = CGRectMake((self.bdp_width - 66.f) / 2.f,  self.name.bdp_top - 10.f - 66.f, 66.f, 66.f);
    
    // App LoadingAnimationView
    self.loadingView.bdp_top = self.name.bdp_bottom + 36.f;
    self.loadingView.bdp_centerX = self.name.bdp_centerX;
    
    // Percent
    self.percent.bdp_top = self.loadingView.bdp_bottom + 10.f;
    self.percent.bdp_centerX = self.name.bdp_centerX;
    
    if (self.state == BDPLoadingViewStateFail || self.state == BDPLoadingViewStateSlow) {
        // TipInfo
        self.tipInfo.frame = CGRectMake((self.bdp_width - self.tipInfo.bdp_width) / 2.f, self.name.bdp_bottom + 23.f - self.tipInfoMargin, self.tipInfo.bdp_width, self.tipInfo.bdp_height);
    } else if (self.state == BDPLoadingViewStateFailReload || self.state == BDPLoadingViewStateSlowDebug || self.state == BDPLoadingViewStateFailReloadImmediately) {
        CGFloat totalWidth = self.tipInfo.bdp_width + 8.f + self.actionInfo.bdp_width;
        if (totalWidth > self.bdp_width - 75.f * 2.f) { // 两边分别留白75像素为判断准则
            // actionInfo单独一行
            // TipInfo
            self.tipInfo.frame = CGRectMake((self.bdp_width - self.tipInfo.bdp_width) / 2.f, self.name.bdp_bottom + 23.f - self.tipInfoMargin, self.tipInfo.bdp_width, self.tipInfo.bdp_height);
            
            // ActionInfo & ActionButton
            self.actionInfo.frame = CGRectMake((self.bdp_width - self.actionInfo.bdp_width) / 2.f, self.tipInfo.bdp_bottom - self.tipInfoMargin + 9.f, self.actionInfo.bdp_width, self.actionInfo.bdp_height);
            self.actionButton.frame = self.actionInfo.frame;
        } else {
            // actionInfo与tipInfo同一行
            // TipInfo
            self.tipInfo.frame = CGRectMake((self.bdp_width - totalWidth) / 2.f, self.name.bdp_bottom + 23.f - self.tipInfoMargin, self.tipInfo.bdp_width, self.tipInfo.bdp_height);
            
            // ActionInfo & ActionButton
            self.actionInfo.frame = CGRectMake(self.tipInfo.bdp_right + 8.f, self.name.bdp_bottom + 23.f, self.actionInfo.bdp_width, self.actionInfo.bdp_height);
            self.actionButton.frame = self.actionInfo.frame;
        }
    }
}

#pragma mark - Button Action

- (void)actionButtonClick:(UIButton *)button {
    if (self.state == BDPLoadingViewStateFailReload) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(bdpLoadingViewReloadActionImmediately:)]) {
            [self.delegate bdpLoadingViewReloadActionImmediately:NO];
        }
    } else if (self.state == BDPLoadingViewStateSlowDebug) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(bdpLoadingViewDebugAction)]) {
            [self.delegate bdpLoadingViewDebugAction];
        }
    } else if (self.state == BDPLoadingViewStateFailReloadImmediately) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(bdpLoadingViewReloadActionImmediately:)]) {
            [self.delegate bdpLoadingViewReloadActionImmediately:YES];
        }
    } else {
        // Do Nothing
    }
}

#pragma mark - Restore State

- (void)restoreToLoadingState {
    if (self.style == BDPLoadingViewStyleInternal) {
        self.percent.text = nil;
        self.percent.hidden = NO;
    } else {
        self.customLoadingView.hidden = NO;
    }
    
    self.tipInfo.text = nil;
    self.tipInfo.hidden = YES;
    self.actionInfo.text = nil;
    self.actionInfo.hidden = YES;
    self.actionButton.userInteractionEnabled = NO;
    self.actionButton.hidden = YES;
    
    self.state = BDPLoadingViewStateLoading;
}

#pragma mark - Loading Animation

- (void)startLoadingAnimation {
    if (self.loadingView == nil || self.style == BDPLoadingViewStyleCustom) {
        return;
    }
    
    self.loadingView.alpha = 1.f;
    [self.loadingView startLoading];
}

- (void)stopLoadingAnimationAnimated:(BOOL)animated {
    if (self.loadingView == nil || self.style == BDPLoadingViewStyleCustom) {
        return;
    }
    
    [self.loadingView stopLoading];
    [UIView animateWithDuration:(animated ? 0.f : 0.15f) animations:^{
        self.loadingView.alpha = 0.f;
    } completion:nil];
}

#pragma mark - Interface

- (void)updateAppModel:(BDPModel *)newAppModel {
    self.appModel = newAppModel;

    BDPPlugin(loadingViewPlugin, BDPLoadingViewPluginDelegate);
    if (loadingViewPlugin != nil && [loadingViewPlugin respondsToSelector:@selector(bdp_updateLoadingViewWithModel:)]) {
        [loadingViewPlugin bdp_updateLoadingViewWithModel:newAppModel];
    }

    // 在有缓存的快速冷启动下，主线程首次调用就会初始化并开启子进程加载WebView, 放到runloop后再开始sd_setImageWithURL可以起到提前WebView开始加载时间的效果
    if (!self.viewSetuped) {
        return;
    }
    
    //使用脱敏方案仅保存appModel
    if (self.style == BDPLoadingViewStyleCustom) {
        return;
    }
    
    //Name
    self.name.hidden = NO;
    self.name.text = self.appModel.name;
    self.name.bdp_width = [self.name.text boundingRectWithSize:CGSizeMake(HUGE, HUGE)
                                                   options:NSStringDrawingUsesFontLeading|NSStringDrawingTruncatesLastVisibleLine|NSStringDrawingUsesLineFragmentOrigin
                                                attributes:@{NSFontAttributeName:self.name.font}
                                                   context:nil].size.width;
    
    self.name.bdp_left = (self.bdp_width - self.name.bdp_width) / 2.0;
    
    //Icon
    [BDPNetworking setImageView:self.icon url:[NSURL URLWithString:self.appModel.icon] placeholder:nil];
    
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

- (void)checkIfNeedCustomLoadingStyleWithUniqueID:(BDPUniqueID *)uniqueID {
}

- (void)updateLoadPercent:(CGFloat)percent {
    if (self.percent == nil || self.style == BDPLoadingViewStyleCustom) {
        return;
    }
    
    if (self.state == BDPLoadingViewStateFail || self.state == BDPLoadingViewStateFailReload || self.state == BDPLoadingViewStateSlow || self.state == BDPLoadingViewStateSlowDebug) {
        return;
    }
    
    int progress = percent * 100;
    self.percent.hidden = NO;
    self.percent.text = [NSString stringWithFormat:@"%d%%", progress];
}

- (void)changeToFailState:(BDPLoadingViewState)state withTipInfo:(NSString *)tipInfo {
    if (state <= BDPLoadingViewStateLoading || state > BDPLoadingViewStateSlowDebug) {
        return;
    }
    
    // 在有缓存的快速冷启动下，主线程首次调用就会初始化并开启子进程加载WebView, 放到runloop后再开始sd_setImageWithURL可以起到提前WebView开始加载时间的效果
    if (!self.viewSetuped) {
        self.state = state;
        self.tipInfoString = tipInfo;
        self.needUpdateTipInfo = YES;
        return;
    }
    
    if (self.style == BDPLoadingViewStyleInternal) {
        self.percent.text = nil;
        self.percent.hidden = YES;
        [self stopLoadingAnimationAnimated:NO];
    } else {
        BDPPlugin(loadingViewPlugin, BDPLoadingViewPluginDelegate);
        if (loadingViewPlugin != nil && [loadingViewPlugin respondsToSelector:@selector(bdp_changeToFailState:withTipInfo:)]) {
            [loadingViewPlugin bdp_changeToFailState:state withTipInfo:tipInfo];
        } else {
            self.customLoadingView.hidden = YES;
        }
    }
    
    // TipInfo
    CGFloat maxTipsInfoWidth = floor(0.8 * self.bdp_width);
    self.tipInfo.hidden = NO;
    self.tipInfo.text = tipInfo;
    CGSize tipsInfoSize = [self.tipInfo.text boundingRectWithSize:CGSizeMake(maxTipsInfoWidth, HUGE)
                                                         options:NSStringDrawingUsesFontLeading|NSStringDrawingTruncatesLastVisibleLine|NSStringDrawingUsesLineFragmentOrigin
                                                      attributes:@{NSFontAttributeName:self.tipInfo.font}
                                                         context:nil].size;
    self.tipInfo.bdp_size = tipsInfoSize;

    NSString *actionInfoString = nil;
    if (state == BDPLoadingViewStateFailReload) {
        actionInfoString = BDPI18n.try_again_later;
    } else if (state == BDPLoadingViewStateSlowDebug) {
        actionInfoString = BDPI18n.debug_mode;
    } else if (state == BDPLoadingViewStateFailReloadImmediately) {
        actionInfoString = BDPI18n.tap_to_retry;
    }
    
    if ([actionInfoString length] > 0) {
        // ActionInfo
        self.actionInfo.hidden = NO;
        self.actionInfo.text = actionInfoString;
        self.actionInfo.bdp_width = [self.actionInfo.text boundingRectWithSize:CGSizeMake(HUGE, HUGE)
                                                                   options:NSStringDrawingUsesFontLeading|NSStringDrawingTruncatesLastVisibleLine|NSStringDrawingUsesLineFragmentOrigin
                                                                attributes:@{NSFontAttributeName:self.actionInfo.font}
                                                                   context:nil].size.width;
        
        // ActionButton
        self.actionButton.userInteractionEnabled = YES;
        self.actionButton.hidden = NO;
    } else {
        // ActionInfo
        self.actionInfo.text = nil;
        self.actionInfo.hidden = YES;
        
        // ActionButton
        self.actionButton.userInteractionEnabled = NO;
        self.actionButton.hidden = YES;
    }
    
    // State
    self.state = state;
    
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

- (void)startLoading {
    self.animating = YES;
    [self restoreToLoadingState];
    [self startLoadingAnimation];
}

- (void)stopLoading {
    self.animating = NO;
    self.percent.text = nil;
    self.percent.hidden = YES;
    [self stopLoadingAnimationAnimated:YES];
}

@end
