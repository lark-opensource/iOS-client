//
//  NLETemplateModel+iOS.h
//  TemplateConsumer
//
//  Created by Charles on 2021/9/5.
//

#import <NLEPlatform/NLEModel+iOS.h>
#import "TemplateInfo+iOS.h"

NS_ASSUME_NONNULL_BEGIN

@interface NLETemplateModel_OC : NLEModel_OC

@property (nonatomic, strong) TemplateInfo_OC *info;

- (NSString *)store;

- (void)storeToZip:(NSString *)zipFolder
withResourceFolder:(NSString *)resourceFolder
   progressHandler:(void (^)(CGFloat))progressHandler
        completion:(void (^)(NSString * _Nullable))completion;

+ (NLETemplateModel_OC *)restore:(NSString *)str;
/// 从 zip 文件中恢复.
+ (NLETemplateModel_OC *)createFromDraft:(NLEModel_OC *)nleModel;

+ (NSSet<NSString *> *)getFeatureListFromTemplateModel:(NLETemplateModel_OC *)templateModel;

- (NSArray<NLETrackSlot_OC *> *)getMutableAssetItems;
- (NSArray<NLETrackSlot_OC *> *)getMutableSlotItems;
- (NSArray<NLETrackSlot_OC *> *)getMutableTextItems;
- (NSArray<NLENode_OC *> *)getAllMutableItems;
- (NSArray<NLETextTemplateClip_OC *> *)getAllMutableTextClipsFromSlot:(NLETrackSlot_OC *)slot;

- (NLEMappingNode_OC *)convertNLEMappingNode:(NLESegment_OC *)segment;

- (instancetype)getStage;

// 获取NLE能力列表(版本号)
+ (NSString *)currentFeatureBits;

@end

NS_ASSUME_NONNULL_END
