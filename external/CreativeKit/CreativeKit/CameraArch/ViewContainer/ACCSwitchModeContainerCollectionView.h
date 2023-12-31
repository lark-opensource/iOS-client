//
//  ACCSwitchModeContainerCollectionView.h
//  CameraClient
//
//  Created by liyingpeng on 2020/5/14.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ACCSwitchModeContainerCollectionView;

@protocol ACCSwitchModeContainerCollectionViewDelegate <NSObject>

@optional
- (void)shouldAdjustSelectedIndexToIndex:(NSIndexPath * _Nullable)selectedIndexPath
                                withView:(id<ACCSwitchModeContainerCollectionView> _Nullable)collectionView;
- (void)switchRecordModeCollectionViewTappedWithView:(id<ACCSwitchModeContainerCollectionView>  _Nullable)collectionView;
- (void)switchRecordModeCollectionViewPressStartWithView:(id<ACCSwitchModeContainerCollectionView>  _Nullable)collectionView;
- (void)switchRecordModeCollectionViewPressEndWithView:(id<ACCSwitchModeContainerCollectionView>  _Nullable)collectionView;
- (void)switchRecordModeCollectionViewCancelledWithView:(id<ACCSwitchModeContainerCollectionView> _Nullable)collectionView;
- (void)switchRecordModeCollectionViewPressMove:(CGPoint)touchPoint WithView:(id<ACCSwitchModeContainerCollectionView>  _Nullable)collectionView;

- (BOOL)shouldRecognizeLongPressGestureWithView:(id<ACCSwitchModeContainerCollectionView>  _Nullable)collectionView
                                     touchPoint:(CGPoint)touchPoint;
- (BOOL)shouldRecognizePanGestureWithView:(id<ACCSwitchModeContainerCollectionView>  _Nullable)collectionView;
- (BOOL)shouldRecognizeTapGestureWithView:(id<ACCSwitchModeContainerCollectionView>  _Nullable)collectionView
                               touchPoint:(CGPoint)touchPoint;

@end

@protocol ACCSwitchModeContainerCollectionView <NSObject>

@property (nonatomic, assign) BOOL isTouching;
@property (nonatomic, weak, nullable) id<ACCSwitchModeContainerCollectionViewDelegate> touchDelegate;
@property (nonatomic, assign) NSInteger selectedIndex;
@property (nonatomic, assign) CGPoint initialContentOffset;
@property (nonatomic, copy, nullable) BOOL (^needKeepInitialContentOffsetBlock)(void);

@end

NS_ASSUME_NONNULL_END
