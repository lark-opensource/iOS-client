//
//  ACCImageAlbumDotPageControl.h
//  CameraClient-Pods-Aweme
//
//  Created by Daniel on 2021/10/13.
//

#import "ACCImageAlbumPageControlProtocol.h"

@interface ACCImageAlbumDotPageControl : UIControl <ACCImageAlbumPageControlProtocol>

- (instancetype)initWithDotDiameter:(CGFloat)diameter visiableCellCount:(NSInteger)visiableCellCount dotSpacing:(CGFloat)dotSpacing;
- (instancetype)initWithCoder:(nonnull NSCoder *)coder NS_UNAVAILABLE;
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
- (instancetype)initWithFrame:(CGRect)frame collectionViewLayout:(nonnull UICollectionViewLayout *)layout NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

@end
