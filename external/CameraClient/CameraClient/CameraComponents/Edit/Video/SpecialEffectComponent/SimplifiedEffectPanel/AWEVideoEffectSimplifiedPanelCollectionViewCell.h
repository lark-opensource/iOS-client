//
//  AWEVideoEffectSimplifiedPanelCollectionViewCell.h
//  Indexer
//
//  Created by Daniel on 2021/11/8.
//

#import <UIKit/UIKit.h>
#import <CreationKitInfra/AWEModernStickerDefine.h>

@class IESEffectModel;

@protocol AWEVideoEffectSimplifiedPanelCollectionViewCellDelegation

- (void)didTapCell:(UICollectionViewCell *)cell;

@end

@interface AWEVideoEffectSimplifiedPanelCollectionViewCell : UICollectionViewCell

@property (nonatomic, weak, nullable) id<AWEVideoEffectSimplifiedPanelCollectionViewCellDelegation> delegate;

+ (CGSize)calculateCellSize;
- (void)updateWithEffectModel:(IESEffectModel *)effectModel;
- (void)updateDownloadStatus:(AWEEffectDownloadStatus)downloadStatus;
- (void)hideDownloadIndicator;

@end
