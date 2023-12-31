//
//  ACCGrootStickerViewModel.h
//  CameraClient-Pods-Aweme
//
//  Created by 饶骏华 on 2021/5/18.
//

#import <Foundation/Foundation.h>
#import <CreationKitInfra/ACCRACWrapper.h>
#import "ACCGrootStickerServiceProtocol.h"
#import "ACCGrootStickerModel.h"

@class AWEVideoPublishViewModel, ACCGrootCheckModel, ACCGrootListModel;
@protocol IESServiceProvider;

NS_ASSUME_NONNULL_BEGIN

@interface ACCGrootStickerViewModel : NSObject <ACCGrootStickerServiceProtocol>

@property (nonatomic, strong, readonly) RACSignal *showGrootStickerTipsSignal;
@property (nonatomic, strong, readonly) RACSignal<NSString *> *sendAutoAddGrootHashtagSignal;
@property (nonatomic, assign, readonly) BOOL isAutoRecognition;
@property (nonatomic, strong) AWEVideoPublishViewModel *repository;
@property (nonatomic, weak) id<IESServiceProvider> serviceProvider;
@property (nonatomic,   copy) NSString *extraInfo;


- (void)bindViewModel;
- (void)sendShowGrootStickerTips;
- (void)sendAutoAddHashtagWith:(NSString * _Nonnull)hashtagName;
-  (void)startCheckGrootRecognitionResult:(void (^)(ACCGrootCheckModel * _Nullable, NSError * _Nullable))checkFinishedBlock;
-  (void)startFetchGrootRecognitionResult:(void (^)(ACCGrootListModel * _Nullable, NSError * _Nullable))finishedBlock;
- (BOOL)shouldUploadFramesForRecommendation;
- (BOOL)canUseGrootSticker;

// draft
- (void)saveCheckGrootRecognitionResult:(BOOL)hasGroot extra:(NSDictionary *)extra;
- (void)saveGrooSelectedResult:(ACCGrootStickerModel *)grootStickerModel;
- (void)removeSelectedGrootResult;
- (ACCGrootStickerModel *)recoverGrootStickerModel;

- (BOOL)hasStickerFromRecord;

@end

NS_ASSUME_NONNULL_END
