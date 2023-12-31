//
//  CJPayBindCardChooseIDTypeViewController.m
//  CJPay
//
//  Created by 尚怀军 on 2019/10/14.
//

#import "CJPayBindCardChooseIDTypeViewController.h"
#import "CJPayUIMacro.h"
#import "CJPayLineUtil.h"

@interface CJPayBindCardChooseIDTypeViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic,strong) UITableView *tableView;
@property (nonatomic,strong) NSMutableArray<CJPayBindCardChooseIDTypeModel *> *models;

@end

@implementation CJPayBindCardChooseIDTypeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.isSupportClickMaskBack = YES;
    [self buildModels];
    [self setupUI];
    
    @CJWeakify(self)
    self.closeActionCompletionBlock = ^(BOOL finish) {
        @CJStrongify(self)
        if (finish) {
            [self.delegate didSelectIDType:self.selectedType];
        }
    };
    
    [self.tableView reloadData];
}

-(void)buildModels {
    self.models = [NSMutableArray array];
    
    NSArray<NSNumber *> *types = @[[NSNumber numberWithUnsignedInteger:CJPayBindCardChooseIDTypeNormal],
                                   [NSNumber numberWithUnsignedInteger:CJPayBindCardChooseIDTypeHK],
                                   [NSNumber numberWithUnsignedInteger:CJPayBindCardChooseIDTypeTW],
                                   [NSNumber numberWithUnsignedInteger:CJPayBindCardChooseIDTypePD],
                                   [NSNumber numberWithUnsignedInteger:CJPayBindCardChooseIDTYpeHKRP],
                                   [NSNumber numberWithUnsignedInteger:CJPayBindCardChooseIDTYpeTWRP]];
    
    [types enumerateObjectsUsingBlock:^(NSNumber * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        CJPayBindCardChooseIDTypeModel *model = [CJPayBindCardChooseIDTypeModel new];
        if (obj.integerValue == self.selectedType) {
            model.isSelected = YES;
        } else {
            model.isSelected = NO;
        }
        
        model.idType = obj.integerValue;
        [self.models addObject:model];
    }];
}

- (void)setupUI {
    [self.contentView addSubview:self.tableView];
    CJPayMasMaker(self.tableView, {
        make.left.top.equalTo(self.contentView);
        make.width.equalTo(self.contentView);
        make.height.equalTo(self.contentView);
    });
    
    [self.tableView registerClass:CJPayBindCardChooseIDTypeCell.class forCellReuseIdentifier:CJPayBindCardChooseIDTypeCell.description];
    [self.navigationBar setTitle:CJPayLocalizedStr(@"选择证件类型")];
    [CJPayLineUtil addBottomLineToView:self.navigationBar marginLeft:0 marginRight:0 marginBottom:0];
}

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [UITableView new];
        _tableView.bounces = YES;
        _tableView.dataSource = self;
        _tableView.delegate = self;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.showsVerticalScrollIndicator = NO;
    }
    return _tableView;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.models enumerateObjectsUsingBlock:^(CJPayBindCardChooseIDTypeModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (idx == indexPath.row) {
            obj.isSelected = YES;
        } else {
            obj.isSelected = NO;
        }
    }];
    self.selectedType = indexPath.row;
    [self.tableView reloadData];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self back];
    });
}

#pragma mark - UITableViewDataSource

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    CJPayBindCardChooseIDTypeCell *cell = [tableView dequeueReusableCellWithIdentifier:CJPayBindCardChooseIDTypeCell.description];
    CJPayBindCardChooseIDTypeModel *model = self.models[indexPath.row];
    [cell updateWithModel:model];
    return cell;
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.models.count;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 56;
}

@end
