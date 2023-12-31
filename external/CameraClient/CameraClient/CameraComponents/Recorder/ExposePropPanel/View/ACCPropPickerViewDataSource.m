//
//  ACCPropPickerViewDataSource.m
//  Pods
//
//  Created by Shen Chen on 2020/4/11.
//

#import "ACCPropPickerViewDataSource.h"
#import "ACCCircleItemCell.h"
#import <CreativeKit/ACCWebImageProtocol.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import "ACCConfigKeyDefines.h"

@interface ACCPropPickerViewDataSource()

@end

@implementation ACCPropPickerViewDataSource

#pragma mark - UICollectionViewDataSource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.items.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    ACCPropPickerItem *item = self.items[indexPath.item];
    ACCCircleItemCell *retCell;
    if (item.type == ACCPropPickerItemTypeHome) {
        ACCCircleHomeItemCell *cell = (ACCCircleHomeItemCell *)[collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([ACCCircleHomeItemCell class]) forIndexPath:indexPath];
        [self configCommonStyleForCell:cell];
        cell.placeholderColor = [UIColor whiteColor];
        cell.effectView.hidden = YES;
        cell.imageView.image = ACCResourceImage(@"icon_back_to_home");
        cell.imageView.bounds = CGRectMake(0, 0, 28, 28);
        if (!ACCConfigBool(kConfigBool_white_lightning_shoot_button)) {
            cell.overlayImageView.image = ACCResourceImage(@"icon_lightning");
        }
        cell.isHome = YES;
        cell.useRatioImage = NO;
        retCell = cell;
    } else if (item.type == ACCPropPickerItemTypeMoreHot || item.type == ACCPropPickerItemTypeMoreFavor) {
        ACCCircleImageItemCell *cell = (ACCCircleImageItemCell *)[collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([ACCCircleImageItemCell class]) forIndexPath:indexPath];
        cell.placeholderColor = [UIColor whiteColor];
        cell.effectView.hidden = YES;
        cell.imageView.image = ACCResourceImage(@"ic_prop_more");
        cell.imageView.bounds = CGRectMake(0, 0, 24, 24);
        cell.useRatioImage = YES;
        cell.imageRatio = 24.f / 64.f;
        [self configCommonStyleForCell:cell];
        retCell = cell;
    } else if (item.type == ACCPropPickerItemTypePlaceholder) {
        ACCCircleResourceItemCell *cell = (ACCCircleResourceItemCell *)[collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([ACCCircleResourceItemCell class]) forIndexPath:indexPath];
        cell.overlay.backgroundColor = [UIColor.blackColor colorWithAlphaComponent:0.6];
        [self configCommonStyleForCell:cell];
        retCell = cell;
    } else {
        ACCCircleResourceItemCell *cell = (ACCCircleResourceItemCell *)[collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass(ACCCircleResourceItemCell.class) forIndexPath:indexPath];
        [self configCommonStyleForCell:cell];
        cell.overlay.backgroundColor = [UIColor.blackColor colorWithAlphaComponent:0.6];
        cell.imageScale = 54 / 48.f;
        if (item.effect != nil) {
            [ACCWebImage() imageView:cell.imageView
                     setImageWithURLArray:item.effect.iconDownloadURLs
                              placeholder:nil
                               completion:nil];
        }
        retCell = cell;
    }
    retCell.indexPath = indexPath;
    return retCell;
}

- (void)configCommonStyleForCell:(ACCCircleItemCell *)cell
{
    cell.shadowRadius = 3;
    cell.borderWidth = 0.5;
    cell.borderColor = [UIColor.whiteColor colorWithAlphaComponent:0.12];
}

@end
