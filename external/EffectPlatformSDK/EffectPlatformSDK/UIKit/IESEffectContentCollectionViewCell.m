//
//  IESEffectContentCollectionViewCell.m
//  EffectPlatformSDK
//
//  Created by Kun Wang on 2018/3/6.
//

#import "IESEffectContentCollectionViewCell.h"
#import "IESEffectListView.h"
#import "Masonry.h"

@interface IESEffectContentCollectionViewCell()<IESEffectListViewDelegate>
@property (nonatomic, strong) IESEffectListView *listView;
@property (nonatomic, strong) IESEffectUIConfig *uiConfig;
@end

@implementation IESEffectContentCollectionViewCell

- (IESEffectListView *)listView
{
    if (!_listView) {
        _listView = [[IESEffectListView alloc] initWithFrame:self.bounds uiConfig:self.uiConfig];
        [self.contentView addSubview:_listView];
        _listView.delegate = self;
    }
    return _listView;
}

- (void)updateWithEffects:(NSArray<IESEffectModel *> *)effects
            selectedIndex:(NSInteger)selectedIndex
                 uiConfig:(IESEffectUIConfig *)uiConfig
{
    _uiConfig = uiConfig;
    [self.listView updateWithModels:effects selectedIndex:selectedIndex];
}

#pragma mark - IESEffectListViewDelegate
- (void)effectListView:(IESEffectListView *)listView didSelectedEffectAtIndex:(NSInteger)index
{
    !_selectBlock ?: _selectBlock(index);
}

- (void)effectListView:(IESEffectListView *)listView didDownloadEffectWithId:(NSString *)effectId withError:(NSError *)error duration:(CFTimeInterval)duration
{
    !_downloadBlock ?: _downloadBlock(effectId, error, duration);
}

@end
