//
//  CAKReorderableForCollectionViewFlowLayout.h
//  CreativeAlbumKit
//
//  Created by yuanchang on 2020/12/4.
//

#import <UIKit/UIKit.h>

@interface CAKPassTouchView: UIView
@property (strong, nonatomic, nullable) UITouch *passTouch;
@end

@interface CAKReorderableForCollectionViewFlowLayout : UICollectionViewFlowLayout <UIGestureRecognizerDelegate>

@property (assign, nonatomic) CGFloat scrollingSpeed;
@property (assign, nonatomic) UIEdgeInsets scrollingTriggerEdgeInsets;
@property (strong, nonatomic, readonly, nullable) UILongPressGestureRecognizer *longPressGestureRecognizer;
@property (strong, nonatomic, readonly, nullable) UIPanGestureRecognizer *panGestureRecognizer;
@property (assign, nonatomic) BOOL oneDirectionOnly; // reorderable in only scroll direction or in both horizontal/vertical directions
@property (assign, nonatomic) UIEdgeInsets draggableInset;
@property (assign, nonatomic) CGFloat highlightedScale;
@property (assign, nonatomic) BOOL hapticFeedbackEnabled;

@end

@protocol CAKReorderableForCollectionViewDataSource <UICollectionViewDataSource>

@optional

- (void)cakReorderableCollectionView:(UICollectionView * _Nullable)collectionView itemAtIndexPath:(NSIndexPath * _Nullable)fromIndexPath willMoveToIndexPath:(NSIndexPath * _Nullable)toIndexPath;
- (void)cakReorderableCollectionView:(UICollectionView * _Nullable)collectionView itemAtIndexPath:(NSIndexPath * _Nullable)fromIndexPath didMoveToIndexPath:(NSIndexPath * _Nullable)toIndexPath;

- (BOOL)cakReorderableCollectionView:(UICollectionView * _Nullable)collectionView canMoveItemAtIndexPath:(NSIndexPath * _Nullable)indexPath;
- (BOOL)cakReorderableCollectionView:(UICollectionView * _Nullable)collectionView itemAtIndexPath:(NSIndexPath * _Nullable)fromIndexPath canMoveToIndexPath:(NSIndexPath * _Nullable)toIndexPath;

@end

@protocol CAKReorderableForCollectionViewDelegateFlowLayout <UICollectionViewDelegateFlowLayout>

@optional

- (void)cakReorderableCollectionView:(UICollectionView * _Nullable)collectionView layout:(UICollectionViewLayout * _Nullable)collectionViewLayout willBeginDraggingItemAtIndexPath:(NSIndexPath * _Nullable)indexPath;
- (void)cakReorderableCollectionView:(UICollectionView * _Nullable)collectionView layout:(UICollectionViewLayout * _Nullable)collectionViewLayout didBeginDraggingItemAtIndexPath:(NSIndexPath * _Nullable)indexPath;
- (void)cakReorderableCollectionView:(UICollectionView * _Nullable)collectionView layout:(UICollectionViewLayout * _Nullable)collectionViewLayout willEndDraggingItemAtIndexPath:(NSIndexPath * _Nullable)indexPath;
- (void)cakReorderableCollectionView:(UICollectionView * _Nullable)collectionView layout:(UICollectionViewLayout * _Nullable)collectionViewLayout didEndDraggingItemAtIndexPath:(NSIndexPath * _Nullable)indexPath;

@end

