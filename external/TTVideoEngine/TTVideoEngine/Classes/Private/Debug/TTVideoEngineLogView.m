//
//  TTVideoEngineLogView.m
//  TTVideoEngine
//
//  Created by 黄清 on 2019/1/28.
//

#import "TTVideoEngineLogView.h"
#import "NSString+TTVideoEngine.h"
#import <pthread.h>

static CGFloat s_logViewWidth = 320.0;

#define LeftViewWidth  (80)
#define RightViewWidth ((s_logViewWidth - 40) - LeftViewWidth)
#define LeftViewFont ([UIFont systemFontOfSize:12.0])
#define RightVieFont ([UIFont systemFontOfSize:13.0])

static inline void dispatch_async_on_main_queue(void (^block)(void)) {
    if (pthread_main_np()) {
        block();
    } else {
        dispatch_async(dispatch_get_main_queue(), block);
    }
}

/// MARK: - header

@interface _TTVideoEngineLogModel : NSObject

/// Default 0
@property (nonatomic, assign) NSInteger logType;
@property (nonatomic, assign) CGFloat viewWidth;

+ (instancetype)item:(NSString *)logInfo;

- (CGFloat)cellHeight;

@end

@interface _TTVideoEngineLogInfoCell : UITableViewCell

- (void)refreshView:(id)model;

@end

/// MARK: - view

@interface TTVideoEngineLogView ()
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *datas;
@end

@implementation TTVideoEngineLogView

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
    if (self.ttvideoengine_width < 200) {
        self.hidden = YES;
    } else {
        self.hidden = NO;
        _tableView.frame = self.bounds;
        [_tableView reloadData];
    }
}
/// MARK: - Public interface
- (void)addLogInfo:(NSString *)log type:(TTVideoEngineViewLogType)logType{
    _TTVideoEngineLogModel *logModel = [_TTVideoEngineLogModel item:log];
    logModel.logType = logType;
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
    [_tableView registerClass:NSClassFromString(@"_TTVideoEngineLogInfoCell") forCellReuseIdentifier:@"_TTVideoEngineLogModel"];
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
        cell = [[_TTVideoEngineLogInfoCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    _TTVideoEngineLogModel *contentModel = _datas[indexPath.section];
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
    static NSString *const k_identifier = @"ttvideoengine.log.view.footer";
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
    _TTVideoEngineLogModel *temModel = _datas[indexPath.section];
    [(_TTVideoEngineLogInfoCell *)cell refreshView:temModel];
}

- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath*)indexPath {
}
@end


/// MARK: - model

@interface _TTVideoEngineLogModel ()
@property (nonatomic, copy) NSString *dateString;
@property (nonatomic, copy) NSString *logInfo;

@property (nonatomic, assign) CGFloat leftHeight;
@property (nonatomic, assign) CGFloat rightHeight;

@property (nonatomic, assign) CGFloat lastViewWidth;

+ (instancetype)item:(NSString *)logInfo;

- (CGFloat)cellHeight;

@end

@implementation _TTVideoEngineLogModel

+ (instancetype)item:(NSString *)logInfo {
    _TTVideoEngineLogModel *item = [_TTVideoEngineLogModel new];
    item.logInfo = logInfo;
    item.dateString = [self _dateString];
    return item;
}

- (void)setViewWidth:(CGFloat)viewWidth {
    _lastViewWidth = _viewWidth;
    _viewWidth = viewWidth;
    s_logViewWidth = viewWidth;
}

- (CGFloat)cellHeight {
    if (self.lastViewWidth != self.viewWidth) {
        self.leftHeight = [self.dateString ttvideoengine_sizeForFont:LeftViewFont size:CGSizeMake(LeftViewWidth, NSIntegerMax) mode:NSLineBreakByWordWrapping].height;
        self.rightHeight = [self.logInfo ttvideoengine_sizeForFont:RightVieFont size:CGSizeMake(RightViewWidth, NSIntegerMax) mode:NSLineBreakByWordWrapping].height;
    }
    return MAX(self.leftHeight, self.rightHeight) + 4;
}

+ (NSString *)_dateString {
    static NSDateFormatter *dateFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dateFormatter = [NSDateFormatter new];
        dateFormatter.dateFormat = @"HH:mm:ss.SSS";
    });
    return [dateFormatter stringFromDate:[NSDate date]];
}

@end

/// MARK: - cell

@interface _TTVideoEngineLogInfoCell ()
@property (nonatomic, strong) UILabel* textLab;
@property (nonatomic, strong) UILabel* dateLab;
@end

@implementation _TTVideoEngineLogInfoCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    self.userInteractionEnabled = NO;
    self.backgroundColor = [UIColor clearColor];
    self.contentView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.3];
    [self.contentView addSubview:self.textLab];
    [self.contentView addSubview:self.dateLab];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    _dateLab.ttvideoengine_left = 15.0;
    _dateLab.ttvideoengine_centerY = self.contentView.ttvideoengine_height * 0.5;
    _textLab.ttvideoengine_left = _dateLab.ttvideoengine_right + 10.0;
    _textLab.ttvideoengine_centerY = _dateLab.ttvideoengine_centerY;
}

- (void)refreshView:(id)model {
    if (model == nil) {
        return;
    }
    
    if (![model isKindOfClass:[_TTVideoEngineLogModel class]]) {
        return;
    }
    
    _TTVideoEngineLogModel* data = (_TTVideoEngineLogModel *)model;
    _dateLab.text = data.dateString;
    _textLab.text = data.logInfo;
    
    _dateLab.ttvideoengine_size = CGSizeMake(LeftViewWidth, self.ttvideoengine_height);
    _textLab.ttvideoengine_size = CGSizeMake(RightViewWidth, self.ttvideoengine_height);
    
    switch (data.logType) {
        case TTVideoEngineViewLogTypeInfo:
            _dateLab.textColor = _textLab.textColor = [UIColor whiteColor];
            break;
        case TTVideoEngineViewLogTypeError:
            _dateLab.textColor = _textLab.textColor = [UIColor redColor];
            break;
        case TTVideoEngineViewLogTypeSucceed:
            _dateLab.textColor = _textLab.textColor = [UIColor greenColor];
            break;
        default:
            _dateLab.textColor = _textLab.textColor = [UIColor whiteColor];
            break;
    }
    
    [self setNeedsLayout];
}

- (UILabel *)textLab {
    if (!_textLab) {
        _textLab = [[UILabel alloc] init];
        _textLab.font = [UIFont systemFontOfSize:13.0];
        _textLab.textColor = [UIColor whiteColor];
        _textLab.textAlignment = NSTextAlignmentLeft;
        _textLab.backgroundColor = [UIColor clearColor];
        _textLab.numberOfLines = 0;
    }
    return _textLab;
}

- (UILabel *)dateLab {
    if (!_dateLab) {
        _dateLab = [[UILabel alloc] init];
        _dateLab.font = [UIFont systemFontOfSize:12.0];
        _dateLab.textColor = [UIColor whiteColor];
        _dateLab.textAlignment = NSTextAlignmentLeft;
        _dateLab.backgroundColor = [UIColor clearColor];
        _dateLab.numberOfLines = 0;
    }
    return _dateLab;
}

@end

@implementation UIView (_TTVideoEngine)

- (CGFloat)ttvideoengine_left {
    return self.frame.origin.x;
}

- (void)setTtvideoengine_left:(CGFloat)x {
    CGRect frame = self.frame;
    frame.origin.x = x;
    self.frame = frame;
}

- (CGFloat)ttvideoengine_top {
    return self.frame.origin.y;
}

- (void)setTtvideoengine_top:(CGFloat)y {
    CGRect frame = self.frame;
    frame.origin.y = y;
    self.frame = frame;
}

- (CGFloat)ttvideoengine_right {
    return self.frame.origin.x + self.frame.size.width;
}

- (void)setTtvideoengine_right:(CGFloat)right {
    CGRect frame = self.frame;
    frame.origin.x = right - frame.size.width;
    self.frame = frame;
}

- (CGFloat)ttvideoengine_bottom {
    return self.frame.origin.y + self.frame.size.height;
}

- (void)setTtvideoengine_bottom:(CGFloat)bottom {
    CGRect frame = self.frame;
    frame.origin.y = bottom - frame.size.height;
    self.frame = frame;
}

- (CGFloat)ttvideoengine_width {
    return self.frame.size.width;
}

- (void)setTtvideoengine_width:(CGFloat)width {
    CGRect frame = self.frame;
    frame.size.width = width;
    self.frame = frame;
}

- (CGFloat)ttvideoengine_height {
    return self.frame.size.height;
}

- (void)setTtvideoengine_height:(CGFloat)height {
    CGRect frame = self.frame;
    frame.size.height = height;
    self.frame = frame;
}

- (CGFloat)ttvideoengine_centerX {
    return self.center.x;
}

- (void)setTtvideoengine_centerX:(CGFloat)centerX {
    self.center = CGPointMake(centerX, self.center.y);
}

- (CGFloat)ttvideoengine_centerY {
    return self.center.y;
}

- (void)setTtvideoengine_centerY:(CGFloat)centerY {
    self.center = CGPointMake(self.center.x, centerY);
}

- (CGPoint)ttvideoengine_origin {
    return self.frame.origin;
}

- (void)setTtvideoengine_origin:(CGPoint)origin {
    CGRect frame = self.frame;
    frame.origin = origin;
    self.frame = frame;
}

- (CGSize)ttvideoengine_size {
    return self.frame.size;
}

- (void)setTtvideoengine_size:(CGSize)size {
    CGRect frame = self.frame;
    frame.size = size;
    self.frame = frame;
}

@end
