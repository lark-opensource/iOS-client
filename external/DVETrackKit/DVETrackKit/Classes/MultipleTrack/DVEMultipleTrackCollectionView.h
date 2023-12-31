//
//  DVEMultipleTrackCollectionView.h
//  DVETrackKit
//
//  Created by bytedance on 2021/4/23.
//

#import <Foundation/Foundation.h>


@protocol DVEMultipleTrackCollectionViewDelegate <NSObject>

- (BOOL)multipleTrackCollectionViewCanRespond:(CGPoint)point;

@end

NS_ASSUME_NONNULL_BEGIN

@interface DVEMultipleTrackCollectionView : UICollectionView

@property (nonatomic, weak) id<DVEMultipleTrackCollectionViewDelegate> trackDelegate;

@end

NS_ASSUME_NONNULL_END
