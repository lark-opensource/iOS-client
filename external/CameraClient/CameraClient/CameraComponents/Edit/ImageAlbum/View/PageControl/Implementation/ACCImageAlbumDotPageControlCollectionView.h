//
//  ACCImageAlbumDotPageControlCollectionView.h
//  CameraClient-Pods-Aweme
//
//  Created by Daniel on 2021/10/13.
//

#import <UIKit/UIKit.h>

@interface ACCImageAlbumDotPageControlCollectionView : UICollectionView

@property (nonatomic, assign, readonly) CGFloat dotDiameter;
@property (nonatomic, assign, readonly) NSInteger visiableCellCount;
@property (nonatomic, assign, readonly) CGFloat dotSpacing;
@property (nonatomic, assign, readonly) NSInteger cellQty;

- (nullable instancetype)initWithDotDiameter:(CGFloat)diameter visiableCellCount:(NSInteger)visiableCellCount dotSpacing:(CGFloat)dotSpacing;
- (nullable instancetype)initWithCoder:(nullable NSCoder *)coder NS_UNAVAILABLE;
- (nonnull instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
- (nonnull instancetype)initWithFrame:(CGRect)frame collectionViewLayout:(nonnull UICollectionViewLayout *)layout NS_UNAVAILABLE;
- (nullable instancetype)init NS_UNAVAILABLE;

- (void)updateCellQty:(NSInteger)cellQty;

@end
