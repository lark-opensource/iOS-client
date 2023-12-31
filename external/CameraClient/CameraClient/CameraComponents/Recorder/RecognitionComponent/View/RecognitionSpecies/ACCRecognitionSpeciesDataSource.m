//
//  ACCRecognitionSpeciesDataSource.m
//  CameraClient-Pods-Aweme
//
//  Created by Bytedance on 2021/6/18.
//

#import "ACCRecognitionSpeciesDataSource.h"
#import "ACCRecognitionSpeciesCell.h"
#import <SmartScan/SSImageTags.h>

@implementation ACCRecognitionSpeciesDataSource

#pragma mark - UICollectionViewDataSource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.tags.imageTags.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    ACCRecognitionSpeciesCell *cell = (ACCRecognitionSpeciesCell *)[collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([ACCRecognitionSpeciesCell class]) forIndexPath:indexPath];
    SSRecognizeResult *model = self.tags.imageTags[indexPath.row];
    [cell configWithData:model at:indexPath.row];
    return cell;
}
@end
