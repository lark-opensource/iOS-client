//
//  NLEVEDataCache.h
//  NLEPlatform
//
//  Created by bytedance on 2021/1/20.
//

#import <Foundation/Foundation.h>
#import <TTVideoEditor/VEAmazingFeature.h>
#import <TTVideoEditor/IESMMAudioFilter.h>
#import <TTVideoEditor/IESMMMVModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface NLEVEAudioFilterCache : NSObject

@property (nonatomic, strong) IESMMAudioFilter *filter;

@property (nonatomic, assign, getter=isVideo) BOOL video;

@property (nonatomic, copy) NSString *nleFilterKey;

- (instancetype)initWithFilter:(IESMMAudioFilter *)filter forVideo:(BOOL)video;

@end

@interface NLEVEDataCache : NSObject

@property (nonatomic, assign) NSInteger lastSelectCanvas;

@property (nonatomic) NSMutableDictionary <AVURLAsset *,AVURLAsset *> *reverseAssetMap;

@property (nonatomic) NSMutableDictionary <NSNumber* ,AVURLAsset *> *keyAssetMap;

// stickerMap: key -> slotname, value -> stickerId from VE
@property (nonatomic) NSMutableDictionary<NSString *, NSNumber *> *stickerMap;

// effectRangIDMap: key -> slotId, value -> rangID from VE
@property (nonatomic) NSMutableDictionary<NSString *, NSString *> *rangIDMap;

/// {rangeID: slotName}
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSString *> *rangIDToSlotMap;

// for text sticker: key -> slotname, value -> userInfo
@property (nonatomic) NSMutableDictionary<NSString *, NSDictionary *> *userInfoMap;

// audio filter cache map: key -> slotId, value -> audioFilter
@property (nonatomic) NSMutableDictionary<NSString *, NSArray<NLEVEAudioFilterCache *> *> *audioFilterCacheMap;

// video mask cache map: key -> slotId, value -> videoMask
@property (nonatomic) NSMutableDictionary<NSString *, VEAmazingFeature *> *maskCacheMap;

/// slotName: {maskSlotName: amazing feature}
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableDictionary<NSString *, VEAmazingFeature *> *> *globalMaskCacheMap;

// filter cache map: key -> slotId(consider slotName as second choice if anything bad happens), value -> filter
/// 全局滤镜  {slotName: [ amazing feature set]}
@property (nonatomic) NSMutableDictionary<NSString *, NSMutableDictionary<NSString *, VEAmazingFeature *> *> *filterCacheMap;


// chroma cache map: key -> slotId, value -> chroma
@property (nonatomic) NSMutableDictionary<NSString *, VEAmazingFeature *> *chromaCacheMap;

@property (nonatomic, strong) NSMutableDictionary<NSString *, VEAmazingFeature *> *globalEffectCacheMap;

/// 局部视频特效   slotName: {videoEffectName: amazing feature}
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableDictionary<NSString *, VEAmazingFeature *> *> *partialEffectCacheMap;

// key -> slotId+path, value -> AVURLAsset
@property(nonatomic) NSMutableDictionary<NSString *, AVURLAsset *> *slotAssetMap;

// slot resouceFile -> VEAudioEffectPreprocessor infoMap
@property (nonatomic, strong) NSCache<NSString *, NSDictionary<AVAsset *, NSString *> *> *preprocessInfoMapCache;

- (void)setExportFPSSelectIndex:(NSInteger)index;
- (NSInteger)getExportFPSIndex;

- (void)setExportPresentSelectIndex:(NSInteger)index;
- (NSInteger)getExportPresentIndex;

- (void)setExportPresent:(NSInteger)index;
- (NSInteger)getExportPresent;

// MARK: userInfo map
- (void)setUserInfo:(NSDictionary *)userInfo ForStickerSlot:(NSInteger)slotId;

// MARK: Audio Filter Cache Map
- (void)addAudioFilter:(IESMMAudioFilter *)filter
                 video:(BOOL)isVideo
                forKey:(NSString *)slotId;

- (void)addAudioFilter:(IESMMAudioFilter *)filter
                 video:(BOOL)isVideo
                forKey:(nonnull NSString *)slotId
             filterKey:(nullable NSString *)filterKey;

- (void)removeAudioFilters:(NSArray<IESMMAudioFilter*>*)filters forKey:(NSString*) slotId;

- (void)removeAudioFilterForKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
