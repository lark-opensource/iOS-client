//
//  SSTTVideoEngineDebugVideoInfoView.m
//  Article
//
//  Created by guoyuhang on 2020/3/2.
//

#import "TTVideoEngineDebugVideoInfoView.h"
#import "NSString+TTVideoEngine.h"
#import "TTVideoEngine.h"
#import "TTVideoEngineLogView.h"
#import "TTVideoEngineUtil.h"
#import "TTVideoEngineUtilPrivate.h"
#import <pthread.h>

///需要添加屏幕适配！！
#define kTTDebugInfoLeftPadding_Xiphone 39
#define kTTDebugInfoLeftPadding 19
#define kTopPadding 10
#define kButtoLeftPadding 10

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-function"
static inline BOOL TT_SIZE_IS_IPHONEX_SERIES(void) {
    static BOOL iPhoneXSeries = NO;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (@available(iOS 11.0, *)) {
            if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
                UIWindow *mainWindow = [[TTVideoEngineGetApplication() delegate] window];
                if (mainWindow.safeAreaInsets.bottom > 0.0) {
                    iPhoneXSeries = YES;
                }
            }
        }
    });
    return iPhoneXSeries;
}
#pragma clang diagnostic pop

typedef enum : NSUInteger {
    TTVideoEngineMediaInfo,
    Format,
    VideoDuration,
    TTVideoEngineOptionCheckInfo,
    Get,
    CatchLog
} ButtonType;

NSInteger const labelSpace = 6;

static CGFloat s_logViewWidth = 320.0;

#define LeftViewWidth  (80)
#define RightViewWidth ((s_logViewWidth - 40) - LeftViewWidth)
#define LeftViewFont ([UIFont systemFontOfSize:12.0])
#define RightVieFont ([UIFont systemFontOfSize:12.0])

static inline void dispatch_async_on_main_queue(void (^block)(void)) {
    if (pthread_main_np()) {
        block();
    } else {
        dispatch_async(dispatch_get_main_queue(), block);
    }
}

/// MARK: - header

@interface _TTVideoEngineDebugModel : NSObject

@property (nonatomic, assign) CGFloat viewWidth;
@property (nonatomic, copy) NSString *keyString;
@property (nonatomic, copy) NSString *valueString;

+ (instancetype)item:(NSString *)key value:(NSString *)value;

- (CGFloat)cellHeight;


@end

@interface _TTVideoEngineDebugInfoCell : UITableViewCell

- (void)refreshView:(id)model;

@end

/// MARK: - view
@interface TTVideoEngineDebugView : UIScrollView
@end

@interface TTVideoEngineDebugView ()
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *datas;

@end

@implementation TTVideoEngineDebugView

- (void)dealloc {
    _tableView.delegate = nil;
    _tableView.dataSource = nil;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        _datas = [NSMutableArray array];
        [self setUpUI];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];

    _tableView.frame = self.bounds;
    [_tableView reloadData];
}

- (void)addDebugInfo:(NSString *)key value:(NSString *)value{
    _TTVideoEngineDebugModel *logModel = [_TTVideoEngineDebugModel item:key value:value];
    for (int i = 0; i < self.datas.count; i++)
    {
        _TTVideoEngineDebugModel * str = self.datas[i];
        if([str.keyString isEqualToString:key]){
            str.valueString = value;
            //if(![str.valueString isEqualToString:value])
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:i] withRowAnimation:UITableViewRowAnimationNone];
            return;
        }
    }
    dispatch_async_on_main_queue(^{
        [self.datas addObject:logModel];
        if (!self.hidden && self.superview) {
            [self.tableView reloadData];
        }
    });
}

- (void)clearLogs {
    dispatch_async_on_main_queue(^{
        [self.datas removeAllObjects];
        [self.tableView reloadData];
    });
}

- (void)setUpUI {
    _tableView = [[UITableView alloc] initWithFrame:self.bounds style:UITableViewStyleGrouped];
    _tableView.delegate = (id<UITableViewDelegate>)self;
    _tableView.dataSource = (id<UITableViewDataSource>)self;
    _tableView.backgroundView = nil;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _tableView.separatorColor = [UIColor clearColor];
    _tableView.showsVerticalScrollIndicator = NO;
    _tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    _tableView.estimatedRowHeight = 0.0f;
    _tableView.estimatedSectionFooterHeight = 0.0f;
    _tableView.estimatedSectionHeaderHeight = 0.0f;
    _tableView.backgroundColor = [UIColor clearColor];
    if (@available(iOS 11.0, *)) {
        _tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
    [_tableView registerClass:NSClassFromString(@"_TTVideoEngineDebugInfoCell") forCellReuseIdentifier:@"_TTVideoEngineDebugModel"];
    [self addSubview:_tableView];
    //
    s_logViewWidth = _tableView.ttvideoengine_width;
}

/// MARK: - UITableViewDelegate & UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return _datas.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSObject *obj = _datas[indexPath.section];
    NSString *cellIdentifier = NSStringFromClass([obj class]);
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell){
        cell = [[_TTVideoEngineDebugInfoCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    _TTVideoEngineDebugModel *contentModel = _datas[indexPath.section];
    contentModel.viewWidth = self.ttvideoengine_width;
    return [contentModel cellHeight];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    return [UIView new];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 0.01f;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {

    if (section == _datas.count - 1) {
        return [UIView new];
    }
    static NSString *const k_identifier = @"ttvideoengine.debug.view.footer";
    UITableViewHeaderFooterView *footer = [tableView dequeueReusableHeaderFooterViewWithIdentifier:k_identifier];
    if (!footer) {
        footer = [[UITableViewHeaderFooterView alloc] initWithReuseIdentifier:k_identifier];
        footer.backgroundView = nil;
        footer.contentView.backgroundColor = [UIColor clearColor];
    }
    return footer;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (section == _datas.count - 1) {
        return 0.01f;
    }
    return (5.0);
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}


- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    _TTVideoEngineDebugModel *temModel = _datas[indexPath.section];
    [(_TTVideoEngineDebugInfoCell *)cell refreshView:temModel];
}

- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath*)indexPath {
}
@end


/// MARK: - model

@interface _TTVideoEngineDebugModel ()

@property (nonatomic, assign) CGFloat leftHeight;
@property (nonatomic, assign) CGFloat rightHeight;

@property (nonatomic, assign) CGFloat lastViewWidth;

+ (instancetype)item:(NSString *)keyString value:(NSString *)valueString;

- (CGFloat)cellHeight;

@end

@implementation _TTVideoEngineDebugModel

+ (instancetype)item:(NSString *)key  value:(NSString *)value{
    _TTVideoEngineDebugModel *item = [_TTVideoEngineDebugModel new];
    item.keyString = key;
    item.valueString = value;
    return item;
}

- (void)setViewWidth:(CGFloat)viewWidth {
    _lastViewWidth = _viewWidth;
    _viewWidth = viewWidth;
    s_logViewWidth = viewWidth;
}

- (CGFloat)cellHeight {
    if (self.lastViewWidth != self.viewWidth) {
        self.leftHeight = [self.keyString ttvideoengine_sizeForFont:LeftViewFont size:CGSizeMake(LeftViewWidth, NSIntegerMax) mode:NSLineBreakByWordWrapping].height;
        self.rightHeight = [self.valueString ttvideoengine_sizeForFont:RightVieFont size:CGSizeMake(RightViewWidth, NSIntegerMax) mode:NSLineBreakByWordWrapping].height;
    }
    return self.leftHeight + 4;
}

@end

/// MARK: - cell

@interface _TTVideoEngineDebugInfoCell ()
@property (nonatomic, strong) UILabel* valueLabel;
@property (nonatomic, strong) UILabel* keyLabel;
@end

@implementation _TTVideoEngineDebugInfoCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    self.userInteractionEnabled = NO;
    self.backgroundColor = [UIColor clearColor];
    self.contentView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.0];
    [self.contentView addSubview:self.valueLabel];
    [self.contentView addSubview:self.keyLabel];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    _keyLabel.ttvideoengine_left = 15.0;
    _keyLabel.ttvideoengine_centerY = self.contentView.ttvideoengine_height * 0.5;
    _valueLabel.ttvideoengine_left = _keyLabel.ttvideoengine_right + 10.0;
    _valueLabel.ttvideoengine_centerY = _keyLabel.ttvideoengine_centerY;
    [_valueLabel layoutIfNeeded];
    [_valueLabel setNeedsLayout];
    [_valueLabel setNeedsDisplay];

}

- (void)refreshView:(id)model {
    if (model == nil) {
        return;
    }

    if (![model isKindOfClass:[_TTVideoEngineDebugModel class]]) {
        return;
    }

    _TTVideoEngineDebugModel* data = (_TTVideoEngineDebugModel *)model;
    _keyLabel.text = data.keyString;
    _valueLabel.text = data.valueString;

    _keyLabel.ttvideoengine_size = CGSizeMake(LeftViewWidth, self.ttvideoengine_height);
    _valueLabel.ttvideoengine_size = CGSizeMake(RightViewWidth, self.ttvideoengine_height);
    [self setNeedsLayout];
    [self setNeedsDisplay];
}

- (UILabel *)valueLabel {
    if (!_valueLabel) {
        _valueLabel = [[UILabel alloc] init];
        _valueLabel.font = [UIFont systemFontOfSize:13.0];
        _valueLabel.textColor = [UIColor redColor];
        _valueLabel.textAlignment = NSTextAlignmentLeft;
        _valueLabel.backgroundColor = [UIColor clearColor];
        _valueLabel.numberOfLines = 0;
    }
    return _valueLabel;
}

- (UILabel *)keyLabel {
    if (!_keyLabel) {
        _keyLabel = [[UILabel alloc] init];
        _keyLabel.font = [UIFont systemFontOfSize:12.0];
        _keyLabel.textColor = [UIColor redColor];
        _keyLabel.textAlignment = NSTextAlignmentLeft;
        _keyLabel.backgroundColor = [UIColor clearColor];
        _keyLabel.numberOfLines = 0;
    }
    return _keyLabel;
}

@end

@interface TTVideoEngineDebugVideoInfoView () <UIGestureRecognizerDelegate>

@property (nonatomic) BOOL isIphoneX;
@property (nonatomic, weak) UIView *parentView;

//view
@property (nonatomic, strong) TTVideoEngineDebugView *videoInfoView;
@property (nonatomic, strong) TTVideoEngineDebugView *formatInfoView;
@property (nonatomic, strong) TTVideoEngineDebugView *durationInfoView;
@property (nonatomic, strong) TTVideoEngineDebugView *checkInfoView;

//TTVideoEngineMediaInfo
@property (nonatomic, copy) NSString *resolutionTypeStr;
@property (nonatomic, copy) NSString *playbackStateStr;
@property (nonatomic, copy) NSString *loadStateStr;
@property (nonatomic, copy) NSString *playedDurationStr;
@property (nonatomic, copy) NSString *dnsStr;

//Button
@property (nonatomic, strong) UIButton *infoBtn;
@property (nonatomic, strong) UIButton *formatBtn;
@property (nonatomic, strong) UIButton *durationBtn;
@property (nonatomic, strong) UIButton *checkInfoBtn;
@property (nonatomic, strong) UIButton *getInfoBtn;
@property (nonatomic, strong) UIButton *catchlogBtn;

@end

@implementation TTVideoEngineDebugVideoInfoView

+ (instancetype)videoDebugInfoViewWithParentView:(UIView *)parentView {
    BOOL isIphoneX = TT_SIZE_IS_IPHONEX_SERIES();
    TTVideoEngineDebugVideoInfoView *infoView = [[TTVideoEngineDebugVideoInfoView alloc] initWithFrame:CGRectMake(0, 0, 292, parentView.ttvideoengine_size.height) isIphoneX:isIphoneX parentView:parentView];
    infoView.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.3];
    return infoView;
}

- (instancetype)initWithFrame:(CGRect)frame isIphoneX:(BOOL)isIphoneX parentView:(UIView *)parentView {
    if (self = [super initWithFrame:frame]) {
        self.isIphoneX = isIphoneX;
        self.parentView = parentView;
        [self buildSubViews];
    }
    return self;
}

- (void)refreshUI {
    NSInteger infoLeftPadding = kTTDebugInfoLeftPadding;
    if (self.isFullScreen) {
        CGSize size;
        if (self.isIphoneX) {
            size = CGSizeMake(self.superview.frame.size.width >= 292 ? 292 : self.superview.ttvideoengine_size.width, self.superview.ttvideoengine_size.height);
            infoLeftPadding = kTTDebugInfoLeftPadding_Xiphone;
        } else {
            size = CGSizeMake(280, self.superview.frame.size.height);
        }
        self.ttvideoengine_size = size;
        self.infoBtn.frame = CGRectMake(self.isIphoneX && self.isFullScreen? kButtoLeftPadding : 0,self.isIphoneX && self.isFullScreen ? kTopPadding : 0, 280.0 / 3, 20);
    } else {
        CGSize size = CGSizeMake(self.superview.frame.size.width >= 280 ? 280:self.superview.ttvideoengine_size.width, self.superview.ttvideoengine_size.height);
        self.ttvideoengine_size = size;
        self.infoBtn.frame = CGRectMake(0, 0, self.ttvideoengine_width / 3, 20);
    }
    self.formatBtn.frame = CGRectMake(_infoBtn.ttvideoengine_right + 1, _infoBtn.ttvideoengine_top, _infoBtn.ttvideoengine_width, _infoBtn.ttvideoengine_height);
    self.durationBtn.frame = CGRectMake(_formatBtn.ttvideoengine_right + 1, _formatBtn.ttvideoengine_top, _formatBtn.ttvideoengine_width, _formatBtn.ttvideoengine_height);
    self.checkInfoBtn.frame = CGRectMake(_infoBtn.ttvideoengine_left, _infoBtn.ttvideoengine_bottom + 6, _infoBtn.ttvideoengine_width, _infoBtn.ttvideoengine_height);
    self.getInfoBtn.frame = CGRectMake(_checkInfoBtn.ttvideoengine_right + 1, _checkInfoBtn.ttvideoengine_top, _checkInfoBtn.ttvideoengine_width, _checkInfoBtn.ttvideoengine_height);
    self.catchlogBtn.frame = CGRectMake(_getInfoBtn.ttvideoengine_right + 1, _getInfoBtn.ttvideoengine_top, _getInfoBtn.ttvideoengine_width, _getInfoBtn.ttvideoengine_height);
    [self setInfoLeftPadding:infoLeftPadding];
}

- (void)setInfoLeftPadding:(NSInteger)padding {
    self.videoInfoView.ttvideoengine_left = padding;
    self.formatInfoView.ttvideoengine_left = padding;
    self.durationInfoView.ttvideoengine_left = padding;
    self.checkInfoView.ttvideoengine_left = padding;
}

- (void)buildSubViews {
    self.layer.masksToBounds = YES;
    
    self.infoBtn = [[UIButton alloc] initWithFrame:CGRectMake(self.isIphoneX && self.isFullScreen? kButtoLeftPadding : 0,self.isIphoneX && self.isFullScreen ? kTopPadding : 0, 280.0 / 3, 20)];
    self.infoBtn.titleLabel.font = [UIFont systemFontOfSize:13];
    self.infoBtn.backgroundColor = [UIColor whiteColor];
    [self.infoBtn setTitle:@"视频信息" forState:UIControlStateNormal];
    [self.infoBtn setTitleColor:[[UIColor blackColor] colorWithAlphaComponent:0.4] forState:UIControlStateNormal];
    self.infoBtn.tag = TTVideoEngineMediaInfo;
    [self.infoBtn addTarget:self action:@selector(ButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.infoBtn];
    
    self.formatBtn = [[UIButton alloc] initWithFrame:CGRectMake(_infoBtn.ttvideoengine_right + 1, _infoBtn.ttvideoengine_top, _infoBtn.ttvideoengine_width, _infoBtn.ttvideoengine_height)];
    self.formatBtn.titleLabel.font = [UIFont systemFontOfSize:13];
    self.formatBtn.backgroundColor = [UIColor whiteColor];
    [self.formatBtn setTitleColor:[[UIColor blackColor] colorWithAlphaComponent:0.4] forState:UIControlStateNormal];
    [self.formatBtn setTitle:@"格式" forState:UIControlStateNormal];
    self.formatBtn.tag = Format;
    [self.formatBtn addTarget:self action:@selector(ButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.formatBtn];
    
    self.durationBtn = [[UIButton alloc] initWithFrame:CGRectMake(_formatBtn.ttvideoengine_right + 1, _formatBtn.ttvideoengine_top, _formatBtn.ttvideoengine_width, _formatBtn.ttvideoengine_height)];
    self.durationBtn.titleLabel.font = [UIFont systemFontOfSize:13];
    self.durationBtn.backgroundColor = [UIColor whiteColor];
    [self.durationBtn setTitleColor:[[UIColor blackColor] colorWithAlphaComponent:0.4] forState:UIControlStateNormal];
    [self.durationBtn setTitle:@"时长" forState:UIControlStateNormal];
    self.durationBtn.tag = VideoDuration;
    [self.durationBtn addTarget:self action:@selector(ButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.durationBtn];
    
    self.checkInfoBtn = [[UIButton alloc] initWithFrame:CGRectMake(_infoBtn.ttvideoengine_left, _infoBtn.ttvideoengine_bottom + 6, _infoBtn.ttvideoengine_width, _infoBtn.ttvideoengine_height)];
    self.checkInfoBtn.titleLabel.font = [UIFont systemFontOfSize:13];
    self.checkInfoBtn.backgroundColor = [UIColor whiteColor];
    [self.checkInfoBtn setTitleColor:[[UIColor blackColor] colorWithAlphaComponent:0.4] forState:UIControlStateNormal];
    [self.checkInfoBtn setTitle:@"开关检测" forState:UIControlStateNormal];
    self.checkInfoBtn.tag = TTVideoEngineOptionCheckInfo;
    [self.checkInfoBtn addTarget:self action:@selector(ButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.checkInfoBtn];
    
    self.getInfoBtn = [[UIButton alloc] initWithFrame:CGRectMake(_checkInfoBtn.ttvideoengine_right + 1, _checkInfoBtn.ttvideoengine_top, _checkInfoBtn.ttvideoengine_width, _checkInfoBtn.ttvideoengine_height)];
    self.getInfoBtn.titleLabel.font = [UIFont systemFontOfSize:13];
    self.getInfoBtn.backgroundColor = [UIColor whiteColor];
    [self.getInfoBtn setTitleColor:[[UIColor blackColor] colorWithAlphaComponent:0.4] forState:UIControlStateNormal];
    [self.getInfoBtn setTitle:@"复制" forState:UIControlStateNormal];
    self.getInfoBtn.tag = Get;
    [self.getInfoBtn addTarget:self action:@selector(ButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.getInfoBtn];
    
    self.catchlogBtn = [[UIButton alloc] initWithFrame:CGRectMake(_getInfoBtn.ttvideoengine_right + 1, _getInfoBtn.ttvideoengine_top, _getInfoBtn.ttvideoengine_width, _getInfoBtn.ttvideoengine_height)];
    self.catchlogBtn.titleLabel.font = [UIFont systemFontOfSize:13];
    self.catchlogBtn.backgroundColor = [UIColor whiteColor];
    [self.catchlogBtn setTitleColor:[[UIColor blackColor] colorWithAlphaComponent:0.4] forState:UIControlStateNormal];
    [self.catchlogBtn setTitle:@"抓logcat" forState:UIControlStateNormal];
    self.catchlogBtn.tag = CatchLog;
    [self.catchlogBtn addTarget:self action:@selector(ButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.catchlogBtn];
    
    [self buildVideoInfoView];
    [self buildFormatInfoView];
    [self buildDurationInfoView];
    [self buildCheckInfoView];
 
}

- (void)buildVideoInfoView {
    self.videoInfoView = [[TTVideoEngineDebugView alloc] initWithFrame:CGRectMake(kTTDebugInfoLeftPadding_Xiphone, self.getInfoBtn.ttvideoengine_bottom + 10, self.ttvideoengine_width, self.ttvideoengine_height - self.getInfoBtn.ttvideoengine_bottom - 10)];
    self.videoInfoView.contentSize = CGSizeMake(0, self.videoInfoView.ttvideoengine_height + 120);
    [self addSubview:self.videoInfoView];
}

- (void)buildFormatInfoView {
    self.formatInfoView = [[TTVideoEngineDebugView alloc] initWithFrame:CGRectMake(kTTDebugInfoLeftPadding_Xiphone, self.getInfoBtn.ttvideoengine_bottom + 10, self.ttvideoengine_width, self.ttvideoengine_height - self.getInfoBtn.ttvideoengine_bottom - 10)];
    self.formatInfoView.contentSize = CGSizeMake(0, self.formatInfoView.ttvideoengine_height + 150);
    [self addSubview:self.formatInfoView];
    self.formatInfoView.hidden = YES;
    
  
}

- (void)buildDurationInfoView {
    self.durationInfoView = [[TTVideoEngineDebugView alloc] initWithFrame:CGRectMake(kTTDebugInfoLeftPadding_Xiphone, self.getInfoBtn.ttvideoengine_bottom + 10, self.ttvideoengine_width, self.ttvideoengine_height - self.getInfoBtn.ttvideoengine_bottom - 10)];
    self.durationInfoView.contentSize = CGSizeMake(0, self.durationInfoView.ttvideoengine_height + 150);
    [self addSubview:self.durationInfoView];
    self.durationInfoView.hidden = YES;
}

- (void)buildCheckInfoView {
    self.checkInfoView = [[TTVideoEngineDebugView alloc] initWithFrame:CGRectMake(kTTDebugInfoLeftPadding_Xiphone, self.getInfoBtn.ttvideoengine_bottom + 10, self.ttvideoengine_width, self.ttvideoengine_height - self.getInfoBtn.ttvideoengine_bottom - 10)];
    self.checkInfoView.contentSize = CGSizeMake(0, self.checkInfoView.ttvideoengine_height + 120);
    [self addSubview:self.checkInfoView];
    self.checkInfoView.hidden = YES;
}

- (UILabel *)getLabel {
    UILabel *label = [[UILabel alloc] init];
    label.textColor = [UIColor redColor];
    label.font = [UIFont systemFontOfSize:12];
    label.lineBreakMode = NSLineBreakByWordWrapping;
    label.numberOfLines = 0;
    return label;
}

- (void)ButtonClicked:(id)sender {
    UIButton *btn = (UIButton *)sender;
    switch (btn.tag) {
        case TTVideoEngineMediaInfo:
            self.formatInfoView.hidden = YES;
            self.durationInfoView.hidden = YES;
            self.videoInfoView.hidden = NO;
            self.checkInfoView.hidden = YES;
            break;
        case Format:
            self.formatInfoView.hidden = NO;
            self.durationInfoView.hidden = YES;
            self.videoInfoView.hidden = YES;
            self.checkInfoView.hidden = YES;
            break;
        case VideoDuration:
            self.formatInfoView.hidden = YES;
            self.durationInfoView.hidden = NO;
            self.videoInfoView.hidden = YES;
            self.checkInfoView.hidden = YES;
            break;
        case TTVideoEngineOptionCheckInfo:
            self.formatInfoView.hidden = YES;
            self.durationInfoView.hidden = YES;
            self.videoInfoView.hidden = YES;
            self.checkInfoView.hidden = NO;
            break;
        case Get:
            [self copyCurrentViewContent];
            break;
        case CatchLog:
            [self catchLogButtonClicked:sender];
            break;
        default:
            break;
    }
}

- (void)catchLogButtonClicked:(id)btn {
    UIButton *button = (UIButton *)btn;
    self.catchingLog = !self.catchingLog;
    if (self.catchingLog) {
        [button setTitle:@"结束抓" forState:UIControlStateNormal];
    } else {
        [button setTitle:@"抓Logcat" forState:UIControlStateNormal];
    }
    if (_delegate && [_delegate respondsToSelector:@selector(catchLogButtonClicked:)]) {
        [_delegate catchLogButtonClicked:self.catchingLog];
    }
}

- (void)copyCurrentViewContent {
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    NSString *content = nil;
    if (!self.videoInfoView.hidden) {
        content = [NSString stringWithFormat:@"{\"Engine版本号\":\"%@\",\"内核版本号\":\"%@\",\"SourceType\":\"%@\",\"video_id\":\"%@\",\"内部IP\":\"%@\",\"初始IP\":\"%@\",\"apiString\":\"%@\",\"auth\":\"%@\",\"videoModel\":\"%@\",\"PlayUrl\":\"%@\",\"内核日志\":\"%@\",\"视频时长\":\"%@\",\"网络库\":\"%@\"}", _sdkVersion, _pcVersion,_sourceType, _videoId, _internalIp, _initialIp, _apiString, _auth, [self dictionaryToStr:_jsonVideoInfo], _playUrl ,_playerLog, [NSString stringWithFormat:@"%6.2f", _duration], _netClient];
    } else if (!self.formatInfoView.hidden) {
        content = [NSString stringWithFormat:@"{\"当前清晰度\":\"%@\",\"FormatType\":\"%@\",\"CodecType\":\"%@\",\"卡顿次数\":\"%@\",\"当前播放状态\":\"%@\",\"当前加载状态\":\"%@\",\"视频宽\":\"%@\",\"视频高\":\"%@\",\"当前加载进度\":\"%@\",\"视频缓存\":\"%@\",\"音频缓存\":\"%@\",\"下载网速\":\"%@\",\"已播放bytes\":\"%@\",\"已加载bytes\":\"%@\",\"视频帧率\":\"%@\",\"预加载大小\":\"%@\",\"输出帧率\":\"%@\",\"循环次数\":\"%@\",\"seek次数\":\"%@\",\"视频解码\":\"%@\",\"音频解码\":\"%@\",\"当前码率\":\"%@\"}", _resolutionTypeStr, _formatType,_codecType, [NSString stringWithFormat:@"%d次", _bufferCount], _playbackStateStr, _loadStateStr, [NSString stringWithFormat:@"%ld", _videoWidth], [NSString stringWithFormat:@"%ld", _videoHeight], _playedDurationStr, [NSString stringWithFormat:@"%lldB", _videoBufferLength],[NSString stringWithFormat:@"%lldB", _audioBufferLength], [NSString stringWithFormat:@"%lldB", _downloadSpeed], [NSString stringWithFormat:@"%lldB", _bytesPlayed], [NSString stringWithFormat:@"%lldB", _bytesTransferred],_containerFps, [NSString stringWithFormat:@"%lldB", _vpls], [NSString stringWithFormat:@"%6.2f", _outputFps], [NSString stringWithFormat:@"%d次", _loopCount], [NSString stringWithFormat:@"%d次", _seekCount], _videoName, _audioName, _bitrate];
    } else if (!self.durationInfoView.hidden) {
        content = [NSString stringWithFormat:@"{\"首帧耗时\":\"%@\",\"读头部耗时\":\"%@\",\"首包耗时\":\"%@\",\"解码首帧耗时\":\"%@\",\"渲染首帧耗时\":\"%@\",\"bufferEnd耗时\":\"%@\",\"累计观看时长\":\"%@\",\"启动播放时间\":\"%@\",\"DNS解析完成时间\":\"%@\",\"建连时间\":\"%@\",\"首包时间\":\"%@\",\"收到首包视频时间\":\"%@\",\"收到首包音频时间\":\"%@\",\"视频设备打开时间\":\"%@\",\"音频设备打开时间\":\"%@\",\"视频频设备打开成功\":\"%@\",\"音频设备打开成功\":\"%@\",\"解码首帧视频时间\":\"%@\",\"解码首帧音频时间\":\"%@\",\"prepared开始时间\":\"%@\",\"prepared完成时间\":\"%@\",\"vt\":\"%@\",\"加载结束时间\":\"%@\"}", [NSString stringWithFormat:@"%ldms", _firstFrameDuration], [NSString stringWithFormat:@"%ldms", _readHeaderDuration], [NSString stringWithFormat:@"%ldms", _readFirstVideoPktDuration], [NSString stringWithFormat:@"%ldms", _firstFrameDecodedDuration], [NSString stringWithFormat:@"%ldms", _firstFrameRenderDuration], [NSString stringWithFormat:@"%ldms", _playbackBufferEndDuration], [NSString stringWithFormat:@"%6.2f", _durationWatched], [self convertTimeToStr:_pt], [self convertTimeToStr:_dnsT], [self convertTimeToStr:_tranCT],  [self convertTimeToStr:_tranFT],  [self convertTimeToStr:_reVideoframeT], [self convertTimeToStr:_reAudioframeT],  [self convertTimeToStr:_videoOpenT],  [self convertTimeToStr:_audioOpenT],  [self convertTimeToStr:_videoOpenedT], [self convertTimeToStr:_audioOpenedT],[self convertTimeToStr:_deVideoframeT], [self convertTimeToStr:_deAudioframeT],  [self convertTimeToStr:_prepareST],  [self convertTimeToStr:_prepareET],  [self convertTimeToStr:_vt],  [self convertTimeToStr:_bft]];
    }else if (!self.checkInfoView.hidden) {
        content = [NSString stringWithFormat:@"{\"静音\":\"%@\",\"循环播放\":\"%@\",\"异步初始化\":\"%@\",\"dash开关\":\"%@\",\"bash开关\":\"%@\",\"劫持监测\":\"%@\",\"自动分辨率\":\"%@\",\"劫持重试DNS\":\"%@\",\"dash类型\":\"%@\",\"dns类型\":\"%@\",\"硬解\":\"%@\",\"bytevc1开关\":\"%@\",\"倍速\":\"%@\",\"平滑切换\":\"%@\",\"socket复用\":\"%@\",\"线下环境\":\"%@\",\"直接buffering\":\"%@\",\"RenderType\":\"%@\",\"音量\":\"%@\",\"videoInfo缓存\":\"%@\"}", _mute, _loop,_asyncInit, _dash,  _bash, _checkHijack, _dashAbr, [NSString stringWithFormat:@"%@, %@",_hijackMainDns, _hijackBackDns], _dynamicType, _dnsStr, _hardware, _bytevc1, _speed,  _smoothlySwitch, _reuseSocket, _boe, _bufferingDirectly, [self renderTypeChanged:_renderType], self.volume, self.videomodelCache];
    }
    pasteboard.string = content;
    if (_delegate && [_delegate respondsToSelector:@selector(copyInfoButtonClicked)]) {
        [_delegate copyInfoButtonClicked];
    }
}

#pragma mark - initinal
- (void)playbackStatusChanged:(TTVideoEnginePlaybackState)state {
    NSString *status = nil;
    switch (state) {
        case TTVideoEnginePlaybackStateError:
            status = @"error";
            break;
        case TTVideoEnginePlaybackStatePlaying:
            status = @"playing";
            break;
        case TTVideoEnginePlaybackStateStopped:
            status = @"stopped";
            break;
        case TTVideoEnginePlaybackStatePaused:
            status = @"pause";
            break;
        default:
            break;
    }
    self.playbackStateStr = status;
}

- (void)loadStatusChanged:(TTVideoEngineLoadState)state {
    NSString *status = nil;
    switch (state) {
        case TTVideoEngineLoadStateError:
            status = @"error";
            break;
        case TTVideoEngineLoadStateStalled:
            status = @"stalled";
            break;
        case TTVideoEngineLoadStateUnknown:
            status = @"unknown";
            break;
        case TTVideoEngineLoadStatePlayable:
            status = @"playable";
            break;
        default:
            break;
    }
    self.loadStateStr = status;
}

- (void)resolutionChanged:(TTVideoEngineResolutionType)state {
    NSString *resolution = nil;
    switch (state) {
        case TTVideoEngineResolutionTypeSD:
            resolution = @"标清";
            break;
        case TTVideoEngineResolutionTypeHD:
            resolution = @"高清";
            break;
        case TTVideoEngineResolutionTypeFullHD:
            resolution = @"超清";
            break;
        case TTVideoEngineResolutionType1080P:
            resolution = @"1080P";
            break;
        case TTVideoEngineResolutionType4K:
            resolution = @"4K";
            break;
        case TTVideoEngineResolutionTypeABRAuto:
            resolution = @"ABR自动";
            break;
        case TTVideoEngineResolutionTypeAuto:
            resolution = @"自动";
            break;
        case TTVideoEngineResolutionTypeUnknown:
            resolution = @"未知";
            break;
        case TTVideoEngineResolutionTypeHDR:
            resolution = @"HDR";
            break;
        case TTVideoEngineResolutionType2K:
            resolution = @"2k";
            break;
        case TTVideoEngineResolutionType1080P_120F:
            resolution = @"1080P_120F";
            break;
        case TTVideoEngineResolutionType2K_120F:
            resolution = @"2K_120F";
            break;
        case TTVideoEngineResolutionType4K_120F:
            resolution = @"4K_120F";
            break;
        default:
            resolution = @"default";
            break;
    }
    self.resolutionTypeStr = resolution;
}

- (NSString *)renderTypeChanged:(TTVideoEngineRenderEngine)type {
    NSString *renderType = @"";
    switch (type) {
        case TTVideoEngineRenderEngineOpenGLES:
            renderType = @"opengl";
            break;
        case TTVideoEngineRenderEngineMetal:
            renderType = @"metal";
            break;
        case TTVideoEngineRenderEngineOutput:
            renderType = @"output";
            break;
        case TTVideoEngineRenderEngineSBDLayer:
            renderType = @"SampleBufferDisplayLayer";
            break;
        default:
            break;
    }
    return renderType;
}

#pragma mark - setter

- (void)setIsFullScreen:(BOOL)isFullScreen {
    _isFullScreen = isFullScreen;
    [self refreshUI];
}

- (void)setResolutionType:(TTVideoEngineResolutionType)resolutionType {
    _resolutionType = resolutionType;
    [self resolutionChanged:resolutionType];
}

- (void)setCatchingLog:(BOOL)catchingLog {
    _catchingLog = catchingLog;
    [self.catchlogBtn setTitle:catchingLog ? @"结束抓" : @"抓Logcat" forState:UIControlStateNormal];
}

- (void)setPlaybackState:(TTVideoEnginePlaybackState)playbackState {
    _playbackState = playbackState;
    [self playbackStatusChanged:playbackState];
}

- (void)setLoadState:(TTVideoEngineLoadState)loadState {
    _loadState = loadState;
    [self loadStatusChanged:loadState];
}

- (void)setCurrentPlaybackTime:(NSTimeInterval )currentPlaybackTime {
    _currentPlaybackTime = currentPlaybackTime;
    if (self.duration) {
        self.playedDurationStr = [NSString stringWithFormat:@"%ld", (NSInteger)((_playableDuration/_duration * 1.0)*100)];
    }
}

- (NSString *)dictionaryToStr:(NSDictionary *)dictionary {
    if(dictionary == nil)
        return @"";
    NSData *data = [NSJSONSerialization dataWithJSONObject:dictionary options:NSJSONWritingPrettyPrinted error:nil];
    NSString *str = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
    return str;
}

- (NSString *)convertTimeToStr:(long long)time {
    NSTimeInterval tempMilli = time;
    NSTimeInterval seconds = tempMilli/1000.0;
    NSDate *date =  [NSDate dateWithTimeIntervalSince1970:seconds];
    NSDateFormatter * formatter = [[NSDateFormatter alloc ] init];
    [formatter setDateFormat:@"HH:mm:ss.SSS"];
    NSString *dateStr =  [formatter stringFromDate:date];
    return dateStr;
}


- (void)updateInfoValue {
    //TTVideoEngineMediaInfo
    [self.videoInfoView addDebugInfo:@"Engine版本号" value:_sdkVersion];
    [self.videoInfoView addDebugInfo:@"内核版本号" value:_pcVersion];
    [self.videoInfoView addDebugInfo:@"SourceType" value:_sourceType];
    [self.videoInfoView addDebugInfo:@"video_id" value:_videoId];
    [self.videoInfoView addDebugInfo:@"内部IP" value:_internalIp];
    [self.videoInfoView addDebugInfo:@"初始IP" value:_initialIp];
    [self.videoInfoView addDebugInfo:@"apiString" value:_apiString];
    [self.videoInfoView addDebugInfo:@"Auth" value:_auth];
    [self.videoInfoView addDebugInfo:@"videoModel" value:[self dictionaryToStr:_jsonVideoInfo]];
    [self.videoInfoView addDebugInfo:@"播放url" value:_playUrl];
    [self.videoInfoView addDebugInfo:@"playerLog" value:_playerLog];
    [self.videoInfoView addDebugInfo:@"视频时长" value:[NSString stringWithFormat:@"%6.2f", _duration]];
    [self.videoInfoView addDebugInfo:@"网络库" value:_netClient];

    //codecInfo
    [self.formatInfoView addDebugInfo:@"当前清晰度" value:_resolutionTypeStr];
    [self.formatInfoView addDebugInfo:@"FormatType" value:_formatType];
    [self.formatInfoView addDebugInfo:@"CodecType" value:_codecType];
    [self.formatInfoView addDebugInfo:@"卡顿次数" value:[NSString stringWithFormat:@"%d次", _bufferCount]];
    [self.formatInfoView addDebugInfo:@"当前播放状态" value:_playbackStateStr];
    [self.formatInfoView addDebugInfo:@"当前加载状态" value:_loadStateStr];
    [self.formatInfoView addDebugInfo:@"视频宽" value:[NSString stringWithFormat:@"%ld", _videoWidth]];
    [self.formatInfoView addDebugInfo:@"视频高" value:[NSString stringWithFormat:@"%ld", _videoHeight]];
    [self.formatInfoView addDebugInfo:@"当前加载进度" value:_playedDurationStr];
    [self.formatInfoView addDebugInfo:@"视频缓存" value:[NSString stringWithFormat:@"%lldB", _videoBufferLength]];
    [self.formatInfoView addDebugInfo:@"音频缓存" value:[NSString stringWithFormat:@"%lldB", _audioBufferLength]];
    [self.formatInfoView addDebugInfo:@"下载网速" value:[NSString stringWithFormat:@"%lldB", _downloadSpeed]];
    [self.formatInfoView addDebugInfo:@"已播放bytes" value:[NSString stringWithFormat:@"%lldB", _bytesPlayed]];
    [self.formatInfoView addDebugInfo:@"已加载bytes" value:[NSString stringWithFormat:@"%lldB", _bytesTransferred]];
    [self.formatInfoView addDebugInfo:@"视频帧率" value:_containerFps];
    [self.formatInfoView addDebugInfo:@"预加载大小" value:[NSString stringWithFormat:@"%lldB", _vpls]];
    [self.formatInfoView addDebugInfo:@"输出帧率" value:[NSString stringWithFormat:@"%6.2f", _outputFps]];
    [self.formatInfoView addDebugInfo:@"循环次数" value:[NSString stringWithFormat:@"%d次", _loopCount]];
    [self.formatInfoView addDebugInfo:@"seek次数" value:[NSString stringWithFormat:@"%d次", _seekCount]];
    [self.formatInfoView addDebugInfo:@"视频解码" value:_videoName];
    [self.formatInfoView addDebugInfo:@"音频解码" value:_audioName];
    [self.formatInfoView addDebugInfo:@"当前码率" value:_bitrate];
    
    //duration
    [self.durationInfoView addDebugInfo:@"首帧耗时" value:[NSString stringWithFormat:@"%ldms", _firstFrameDuration]];
    [self.durationInfoView addDebugInfo:@"读头部耗时" value:[NSString stringWithFormat:@"%ldms", _readHeaderDuration]];
    [self.durationInfoView addDebugInfo:@"首包耗时" value:[NSString stringWithFormat:@"%ldms", _readFirstVideoPktDuration]];
    [self.durationInfoView addDebugInfo:@"解码首帧耗时" value:[NSString stringWithFormat:@"%ldms", _firstFrameDecodedDuration]];
    [self.durationInfoView addDebugInfo:@"渲染首帧耗时" value:[NSString stringWithFormat:@"%ldms", _firstFrameRenderDuration]];
    [self.durationInfoView addDebugInfo:@"bufferEnd耗时" value:[NSString stringWithFormat:@"%ldms", _playbackBufferEndDuration]];
    [self.durationInfoView addDebugInfo:@"累计观看时长" value:[NSString stringWithFormat:@"%6.2f", _durationWatched]];
    [self.durationInfoView addDebugInfo:@"启动播放时间" value:[self convertTimeToStr:_pt]];
    [self.durationInfoView addDebugInfo:@"DNS解析完成时间" value:[self convertTimeToStr:_dnsT]];
    [self.durationInfoView addDebugInfo:@"建连时间" value:[self convertTimeToStr:_tranCT]];
    [self.durationInfoView addDebugInfo:@"首包时间" value:[self convertTimeToStr:_tranFT]];
    [self.durationInfoView addDebugInfo:@"收到首包视频时间" value: [self convertTimeToStr:_reVideoframeT]];
    [self.durationInfoView addDebugInfo:@"收到首包音频时间" value: [self convertTimeToStr:_reAudioframeT]];
    [self.durationInfoView addDebugInfo:@"视频设备开始打开" value: [self convertTimeToStr:_videoOpenT]];
    [self.durationInfoView addDebugInfo:@"音频设备开始打开" value: [self convertTimeToStr:_audioOpenT]];
    [self.durationInfoView addDebugInfo:@"视频设备打开成功" value: [self convertTimeToStr:_videoOpenedT]];
    [self.durationInfoView addDebugInfo:@"音频设备打开成功" value: [self convertTimeToStr:_audioOpenedT]];
    [self.durationInfoView addDebugInfo:@"解码首帧视频时间" value: [self convertTimeToStr:_deVideoframeT]];
    [self.durationInfoView addDebugInfo:@"解码首帧音频时间" value: [self convertTimeToStr:_deAudioframeT]];
    [self.durationInfoView addDebugInfo:@"prepare开始" value: [self convertTimeToStr:_prepareST]];
    [self.durationInfoView addDebugInfo:@"prepare完成" value: [self convertTimeToStr:_prepareET]];
    [self.durationInfoView addDebugInfo:@"vt" value: [self convertTimeToStr:_vt]];
    [self.durationInfoView addDebugInfo:@"加载结束时间" value: [self convertTimeToStr:_bft]];
    
    //checkinfo
    [self.checkInfoView addDebugInfo:@"静音" value:_mute];
    [self.checkInfoView addDebugInfo:@"循环播放" value:_loop];
    [self.checkInfoView addDebugInfo:@"异步初始化" value:_asyncInit];
    [self.checkInfoView addDebugInfo:@"dash开关" value:_dash];
    [self.checkInfoView addDebugInfo:@"bash开关" value:_bash];
    [self.checkInfoView addDebugInfo:@"劫持监测" value:_checkHijack];
    [self.checkInfoView addDebugInfo:@"自动分辨率" value:_dashAbr];
    [self.checkInfoView addDebugInfo:@"劫持重试DNS" value:[NSString stringWithFormat:@"%@, %@",_hijackMainDns, _hijackBackDns]];
    [self.checkInfoView addDebugInfo:@"dash类型" value:_dynamicType];
    _dnsStr = [[TTVideoEngine getDNSType] componentsJoinedByString:@", "];
    [self.checkInfoView addDebugInfo:@"dns类型" value:_dnsStr];
    [self.checkInfoView addDebugInfo:@"硬解" value:_hardware];
    [self.checkInfoView addDebugInfo:@"bytevc1开关" value:_bytevc1];
    [self.checkInfoView addDebugInfo:@"倍速" value:_speed];
    [self.checkInfoView addDebugInfo:@"平滑切换" value:_smoothlySwitch];
    [self.checkInfoView addDebugInfo:@"socket复用" value:_reuseSocket];
    [self.checkInfoView addDebugInfo:@"线下环境" value:_boe];
    [self.checkInfoView addDebugInfo:@"直接buffering" value:_bufferingDirectly];
    [self.checkInfoView addDebugInfo:@"RenderTyp" value:[self renderTypeChanged:_renderType]];
    [self.checkInfoView addDebugInfo:@"音量" value:_volume];
    [self.checkInfoView addDebugInfo:@"videoInfo缓存" value:_videomodelCache];
}

-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch{
    return YES;
}

@end

