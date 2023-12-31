//
//  CAKAlbumListViewController.h
//  CameraClient
//
//  Created by lixingdong on 2020/6/16.
//

#import <UIKit/UIKit.h>
#import "CAKAlbumViewModel.h"
#import "CAKAlbumListViewControllerProtocol.h"
#import "CAKAlbumListTabConfig.h"

@interface CAKAlbumListViewController : UIViewController <CAKAlbumListViewControllerProtocol>

@property (nonatomic, weak, nullable) CAKAlbumViewModel *viewModel;
@property (nonatomic, assign) AWEGetResourceType resourceType;
@property (nonatomic, strong, nullable) CAKAlbumListTabConfig *tabConfig;

- (instancetype _Nonnull)initWithResourceType:(AWEGetResourceType)resourceType;

- (UICollectionViewCell * _Nullable)transitionCollectionCellForItemOffset:(NSInteger)itemOffset;

- (void)reloadVisibleCell;

- (void)didSelectedToPreview:(CAKAlbumAssetModel * _Nullable)model coverImage:(UIImage * _Nullable)coverImage fromBottomView:(BOOL)fromBottomView;

@end
