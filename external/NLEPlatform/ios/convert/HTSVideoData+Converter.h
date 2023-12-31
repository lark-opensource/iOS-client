//
// Created by bytedance on 2020/11/11.
// Copyright (c) 2020 bytedance. All rights reserved.
//

#import <TTVideoEditor/HTSVideoData.h>
#import "NLEModel+iOS.h"
#import "NLESegment+iOS.h"
#import "NLESegmentSticker+iOS.h"
#import "NLESegmentSticker+iOS.h"

#define HTSVIDEODATA_IS_RECORD_APPLOG_INFO      0   //是否转换并记录打点信息
#define HTSVIDEODATA_FORCE_RECORD_ALL_IN_EXTRA  0   //是否把所有的信息（不含打点信息）尽可能保存。额外信息放入extra

typedef NS_ENUM(NSUInteger, VEInfoStickerType) {
    
    VEInfoSticker_MASK_COMPONENT     = 0xFFFF0000,
    VEInfoSticker_MASK_TYPE          = 0x0000FFFF,
    
    VEInfoSticker_COMPONENT_BASIC           = 1 << 16,  // 基本信息：位置尺寸时长layer、userInfo、pin信息
    VEInfoSticker_COMPONENT_RESOURCE_FILE   = 1 << 17,  // 需VE处理的resourcePath
    VEInfoSticker_COMPONENT_EFFECT_INFO     = 1 << 18,  // 带有effectInfo
    VEInfoSticker_COMPONENT_TEXT_PARAM      = 1 << 19,  // 带有text param
    VEInfoSticker_COMPONENT_SRT_INFO        = 1 << 20,  // 带有歌词信息
    
    VEInfoStickerType_Unknown       = 0,
    VEInfoStickerType_InfoSticker   = VEInfoSticker_COMPONENT_BASIC | VEInfoSticker_COMPONENT_EFFECT_INFO | 1,
    VEInfoStickerType_Lyric         = VEInfoSticker_COMPONENT_BASIC | VEInfoSticker_COMPONENT_SRT_INFO | 2,
    VEInfoStickerType_Subtitle      = 3,
    VEInfoStickerType_Text          = VEInfoSticker_COMPONENT_BASIC | 4,
    VEInfoStickerType_POI           = VEInfoSticker_COMPONENT_BASIC | 5,
    VEInfoStickerType_EffectPOI     = VEInfoSticker_COMPONENT_BASIC | VEInfoSticker_COMPONENT_EFFECT_INFO | VEInfoSticker_COMPONENT_TEXT_PARAM | 6,
    VEInfoStickerType_Mention       = VEInfoSticker_COMPONENT_BASIC | 7,
    VEInfoStickerType_HashTag       = VEInfoSticker_COMPONENT_BASIC | 8,
    VEInfoStickerType_Vote          = 9,
    VEInfoStickerType_Custom        = VEInfoSticker_COMPONENT_BASIC | VEInfoSticker_COMPONENT_RESOURCE_FILE | 10,
    VEInfoStickerType_Daily         = VEInfoSticker_COMPONENT_BASIC | 11,
    VEInfoStickerType_Magnifer      = VEInfoSticker_COMPONENT_BASIC | 12,

};

typedef VEInfoStickerType (^VEStickerSegmentFactoryBlock)(NSDictionary *userInfo, NSDictionary *extraInfo, NLESegmentSticker_OC * __autoreleasing *segment);
typedef VEInfoStickerType (^VEStickerSegmentRecoverFactoryBlock)(NSDictionary * __autoreleasing *userInfo, NLETrackSlot_OC *slot);
typedef void (^VEReverseCompleteBlock)(BOOL success, AVAsset *_Nullable reverseAsset, NSError *_Nullable error);

/// 业务方根据已有信息生成Segment的工厂类，主要负责处理VideoData内部保存的业务信息
@interface NLESegmentFactory : NSObject

@property(nonatomic, copy) VEStickerSegmentFactoryBlock stickerFactory;  // 业务根据userInfo、extraInfo生成Segment
@property(nonatomic, copy) VEStickerSegmentRecoverFactoryBlock stickerRecoverFactory; // 业务根据Slot恢复userInfo

@end


typedef NS_ENUM(NSInteger, HTSVideoDataConverterErrorCode) {
    Error_ModelNotExist = -1,   // model不可用
    Error_RootPathNotExist = -2,
    
    Error_FileNotExist = -3,    // 文件不存在
    Error_AssetNotPlayable = -4, // asset不可播放
    Error_NoVideoAssets = -5, // video asset不存在
};

@interface HTSVideoData (Converter)

/// convert VideoData Dictionary to NLEModel
+ (NLEModel_OC *)videoDataDictToNLEModel:(NSDictionary *_Nonnull)videoDataDict rootPath:(NSString *_Nonnull)rootPath segmentFactory:(NLESegmentFactory *)segmentFactory errors:(NSMutableArray<NSError *> *)errors;
/// convert NLEModel to VideoData Dictionary
+ (NSDictionary *_Nullable)NLEModelToVideoDataDict:(NLEModel_OC *_Nonnull)model extraDict:(NSDictionary *_Nullable)extraDict rootPath:(NSString *_Nonnull)rootPath segmentFactory:(NLESegmentFactory *)segmentFactory errors:(NSMutableArray<NSError *> *)errors;

+ (BOOL)NLEModelToVideoData:(NLEModel_OC *)model videodata:(HTSVideoData *_Nonnull)voideData;

+ (void)loadVideoDataFromDictionary:(NSDictionary *)dataDict fileFolder:(NSString *)fileFolder completion:(nullable void (^)(HTSVideoData *_Nullable videoData, NSError *_Nullable error))completion;

/// 如有需要，生成倒放视频
+ (void)createReverseAssetIfNeeded:(HTSVideoData *)videoData completion:(VEReverseCompleteBlock)completion;


+ (NSErrorDomain) ErrorDomain_VideoDataDictToNLEModel;
+ (NSErrorDomain) ErrorDomain_NLEModelToVideoDataDict;


@end


// 将path改写为相对于rootPath的相对路径，格式为"./xxx"
// 兼容冷启动后沙盒变化
extern NSString * trimRootPath(NSString *path, NSString *rootPath);

// trimRootPath反操作
extern NSString * undoTrimRootPath(NSString *path, NSString *rootPath);

// 冷启动沙盒后更新path
extern NSString * updateRootPath(NSString *path, NSString *rootPath);

// 判断AVURLAsset是对应的blank video
extern BOOL isBlankAssetPath(NSString *videoPath);
