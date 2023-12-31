//
//  ACCSingleMusicRecommenVideosTableViewCellProtocol.h
//  CameraClient
//
//  Created by Chen Long on 2020/11/20.
//

#import <CreationKitArch/ACCMusicModelProtocol.h>
#import <CreationKitArch/ACCAwemeModelProtocol.h>
#import "ACCSearchMusicRecommendedVideosModelProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@protocol ACCSingleMusicRecommenVideosTableViewCellDelegate <NSObject>

@optional
- (void)videoHasBeingPlayed:(UIViewController *)playerContainer withRow:(NSInteger)row column:(NSInteger)column;
- (void)videoHasBeingPaused:(UIViewController *)playerContainer withRow:(NSInteger)row column:(NSInteger)column;
- (void)videoWillShow:(id<ACCAwemeModelProtocol>)awemeModel withRow:(NSInteger)row column:(NSInteger)column;
- (void)useMusic:(id<ACCMusicModelProtocol>)musicModel row:(NSInteger)row column:(NSInteger)column;
- (void)gotoDetailPageWithAwemeModel:(id<ACCAwemeModelProtocol>)awemeModel row:(NSInteger)row column:(NSInteger)column;

@end

@protocol ACCSingleMusicRecommenVideosTableViewCellProtocol <NSObject>

@property (nonatomic,weak) id<ACCSingleMusicRecommenVideosTableViewCellDelegate> delegate;
@property (nonatomic, assign) NSInteger rank;
@property (nonatomic, assign) BOOL showTopSeparatorLine;
@property (nonatomic, strong) NSMutableDictionary *logExtraDict;
@property (nonatomic, strong) NSString *referString;
@property (nonatomic, copy) void(^solveCloseGesture)(UIPanGestureRecognizer *panGesture);//浮层关闭手势冲突解决

- (void)updateWithModel:(id<ACCSearchMusicRecommendedVideosModelProtocol>)model offsetX:(CGFloat)offsetX;
- (void)updateWithModel:(id<ACCSearchMusicRecommendedVideosModelProtocol>)model playerContainer:(UIViewController *)playerContainer index:(NSInteger)index offsetX:(CGFloat)offsetX;
- (void)updateWithModel:(id<ACCSearchMusicRecommendedVideosModelProtocol>)model offsetX:(CGFloat)offsetX lastPlayedIndex:(NSInteger)index;


- (CGPoint)getListContentOffset;

- (void)stopVideoPlay;
- (void)removePlayerContainer;
- (void)clearVideoUseMusicButton;

@end

NS_ASSUME_NONNULL_END
