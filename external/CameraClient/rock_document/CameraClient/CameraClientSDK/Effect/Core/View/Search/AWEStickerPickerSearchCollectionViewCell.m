//
//  AWEModernStickerSearchCollectionViewCell.m
//  CameraClient-Pods-Aweme
//
//  Created by Syenny on 2021/5/18.
//

#import "AWEStickerPickerSearchCollectionViewCell.h"
#import "AWEStickerPickerModel+Search.h"

#import <CreationKitInfra/UIView+ACCMasonry.h>

@interface AWEStickerPickerSearchCollectionViewCell ()

@property (nonatomic, strong, readwrite) AWEStickerPickerSearchView *searchView;

@end

@implementation AWEStickerPickerSearchCollectionViewCell

+ (NSString *)identifier {
    return NSStringFromClass(self);
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        [self setupUI];
    }
    return self;
}

- (void)setupUI
{
    [self.contentView addSubview:self.searchView];
    ACCMasMaker(self.searchView, {
        make.edges.equalTo(self);
    });
}

- (void)setModel:(AWEStickerPickerModel *)model
{
    _model = model;
    self.searchView.model = model;
}

- (void)updateUIConfig:(id<AWEStickerPickerUIConfigurationProtocol>)config
{
    [self.searchView updateUIConfig:config];
}

- (AWEStickerPickerSearchView *)searchView
{
    if (!_searchView) {
        _searchView = [[AWEStickerPickerSearchView alloc] initWithIsTab:YES];
        _searchView.backgroundColor = [UIColor clearColor];
    }
    return _searchView;
}

@end
