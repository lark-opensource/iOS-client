//
//  ACCRecognitionTrackModel.h
//  CameraClient-Pods-Aweme
//
//  Created by Bytedance on 2021/6/21.
//

#import <Foundation/Foundation.h>
#import <CreationKitArch/ACCPublishRepositoryElementProtocols.h>

NS_ASSUME_NONNULL_BEGIN

@class IESEffectModel;
@class SSRecommendResult;
@class ACCRecognitionGrootModel;
@class AWEInteractionStickerLocationModel;

extern NSString * const kACCGrootRecognitionPropIdKeyInhouse;
extern NSString * const kACCGrootRecognitionPropIdKeyOnline;

@interface ACCRecognitionTrackModel : NSObject<ACCRepositoryTrackContextProtocol,NSCopying>

/// current recognition identifier
@property (nonatomic,   copy) NSString *realityId;
/// general_reality or wiki_reality or qr_code
@property (nonatomic,   copy) NSString *realityType;
/// long_press or icon_click
@property (nonatomic,   copy) NSString *enterMethod;
/// recognition begin timestamp
@property (nonatomic, assign) NSInteger begin;
/// recognition time cost(ms)
@property (nonatomic, assign) NSInteger duration;
/// recognition result
@property (nonatomic, assign) BOOL isSuccess;
/// prop index
@property (nonatomic, assign) NSInteger propIndex;
/// species index, < 0 means invalid value
@property (nonatomic, assign) NSInteger speciesIndex;
/// for species panel track
@property (nonatomic, assign) BOOL isClickByGroot;

/// current effect
@property (nonatomic, strong) IESEffectModel *effect;

- (BOOL)isWikiType;

@property (nonatomic, strong, nullable) ACCRecognitionGrootModel *grootModel;

@end

@class ACCGrootStickerModel;

/// for groot sticker in edit page
@interface ACCRecognitionGrootModel : NSObject

//@property (nonatomic, strong) AWEInteractionStickerLocationModel *locationModel;

@property (nonatomic, strong) ACCGrootStickerModel *stickerModel;

@property (nonatomic, assign) CGFloat scale;

//@property (nonatomic, assign) BOOL allowResearch;

@property (nonatomic, assign) NSInteger index;

@property (nonatomic, assign) BOOL didRecover;

@end

NS_ASSUME_NONNULL_END
