//
//  ACCRecognitionSpeciesPannelView.m
//  CameraClient-Pods-Aweme
//
//  Created by Bytedance on 2021/6/18.
//

#import "ACCRecognitionSpeciesPannelView.h"
#import <CreativeKit/ACCMacros.h>
#import <CreationKitInfra/UIView+ACCMasonry.h>

#import <SmartScan/SSImageTags.h>
#import "ACCRecognitionGrootConfig.h"

#import "ACCRecognitionSpeciesCell.h"
#import "ACCSpeciesInfoCardsView.h"
#import "ACCRecognitionSpeciesDataSource.h"
#import "ACCRecognitionSpeciesPanelViewModel.h"

@interface ACCRecognitionSpeciesPannelView ()<UIGestureRecognizerDelegate>

@property (nonatomic, strong) ACCRecognitionSpeciesDataSource *pannelViewDataSource;
@property (nonatomic, strong) ACCSpeciesInfoCardsView *panelView;

@end

@implementation ACCRecognitionSpeciesPannelView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        
        ACCSpeciesInfoCardsViewConfig *config = [ACCRecognitionGrootConfig enabled]? [ACCSpeciesInfoCardsViewConfig configWithGrootParams] : [ACCSpeciesInfoCardsViewConfig configWithDefaultParams];
        self.panelView = [[ACCSpeciesInfoCardsView alloc] initWithFrame:CGRectZero config:config];
        [self.panelView registerCell:[ACCRecognitionSpeciesCell class]];
        self.panelView.dataSource = self.pannelViewDataSource;
        self.panelView.backgroundColor = [UIColor whiteColor];
        [self addSubview:self.panelView];
                
        CGSize size = [ACCSpeciesInfoCardsView designSizeWithConfig:config];
        CGFloat bottomOffset = ACC_IPHONE_X_BOTTOM_OFFSET > 0 ? ACC_IPHONE_X_BOTTOM_OFFSET : 10;
        CGFloat height = size.height + bottomOffset;
        ACCMasMaker(self.panelView, {
            make.left.right.equalTo(@0);
            make.height.mas_equalTo(@(height));
            make.bottom.mas_equalTo(@0);
        })
        
        UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleClosePanelView)];
        tapGestureRecognizer.delegate = self;
        [self addGestureRecognizer:tapGestureRecognizer];
    }
    return self;
}

#pragma mark - Public Methods
- (void)resetDefaultSelectionIndex:(NSUInteger)index
{
    self.panelView.defaultSelectionIndex = index;
    [self.panelView resetSelectedIndex:index];
}

- (void)resetSelectionAsDefault
{
    [self.panelView resetSelectionAsDefault];
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    return (touch.view == self);
}

#pragma mark - Actions

- (void)handleClosePanelView
{
    ACCBLOCK_INVOKE(self.closePanelCallback);
}

#pragma mark - Getter

- (ACCRecognitionSpeciesDataSource *)pannelViewDataSource
{
    if (!_pannelViewDataSource) {
        _pannelViewDataSource = [[ACCRecognitionSpeciesDataSource alloc] init];
    }
    return _pannelViewDataSource;
}

- (NSInteger)currentSelectedIndex
{
    return self.panelView.currentSelectedIndex;
}

#pragma mark - Setter

- (void)setPanelViewModel:(ACCRecognitionSpeciesPanelViewModel *)panelViewModel
{
    _panelViewModel = panelViewModel;
    self.panelView.delegate = panelViewModel;
    
    @weakify(self);
    [[[RACObserve(self.panelViewModel, recognizeResultData)  takeUntil:self.rac_willDeallocSignal] deliverOnMainThread] subscribeNext:^(SSImageTags * _Nullable tags) {
        @strongify(self);
        self.pannelViewDataSource.tags = tags;
        self.panelView.defaultSelectionIndex = 0;
        [self.panelView reloadData];
    }];
}

@end
