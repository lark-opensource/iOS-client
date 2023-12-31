//
//  AWEModernStickerContentCollectionViewCell.h
//  AWEStudio
//
//  Created by 郝一鹏 on 2018/4/15.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import "AWEStudioBaseCollectionViewCell.h"
#import <EffectPlatformSDK/EffectPlatform.h>

@interface AWEModernStickerContentInnerCollectionView: UICollectionView

@property (nonatomic, copy) NSString *identifier;

/*
 道具搜索也需要提供相同样式的道具展示样式，为了提高代码可复用性，将通用代码放到这里，两处可以直接使用
 */
+ (AWEModernStickerContentInnerCollectionView *)defaultCollectionView;

- (void)clearSelectedCellsForSelectedModel:(IESEffectModel *)selectedModel;

@end

@interface AWEModernStickerContentCollectionViewCell : AWEStudioBaseCollectionViewCell
@property (nonatomic, strong) AWEModernStickerContentInnerCollectionView *collectionView;

- (void)setCollectionViewDataSource:(id<UICollectionViewDataSource>)dataSource delegate:(id<UICollectionViewDelegate>)delegate section:(NSInteger)section;

- (void)configWithEmptyString:(NSString *)emptyString;

@end
