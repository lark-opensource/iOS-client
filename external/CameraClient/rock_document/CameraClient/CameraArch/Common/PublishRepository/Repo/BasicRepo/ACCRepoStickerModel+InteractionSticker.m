//
//  AWERepoStickerModel+InteractionSticker.m
//  CameraClient-Pods-Aweme
//
//  Created by liyingpeng on 2020/11/30.
//

#import "AWERepoStickerModel.h"
#import "ACCRepoStickerModel+InteractionSticker.h"
#import <EffectPlatformSDK/EffectPlatform.h>
#import <objc/runtime.h>
#import <CreationKitInfra/ACCLogProtocol.h>
#import <CreativeKit/ACCCacheProtocol.h>
#import <CreativeKit/NSTimer+ACCAdditions.h>
#import <CreationKitArch/ACCPublishInteractionModel.h>
#import "AWERepoVideoInfoModel.h"
#import <CreationKitArch/ACCRepoDuetModel.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/NSArray+ACCAdditions.h>

static NSString *const kACCCameraClientEffectIconDomainKey = @"kACCCameraClientEffectIconDomainKey";

@interface AWERepoStickerModel ()

@property (nonatomic, strong) AWEInteractionStickerModel *currentInteractionModel;
@property (nonatomic, strong) NSTimer *recordLocationTimer;
@property (nonatomic, strong) NSDictionary *currentLocationDic;
@property (nonatomic, assign) BOOL shouldRecordLocations;
@property (nonatomic, assign) BOOL stopRecording;//录制时长达到15s自动结束，随后才会执行action: IESCameraDidPauseVideoRecord
@end


@implementation AWERepoStickerModel (InteractionSticker)

#pragma mark - getter/setter

- (BOOL)shouldRecordLocations
{
    NSNumber *shouldRecord = objc_getAssociatedObject(self, @selector(shouldRecordLocations));
    if (shouldRecord == nil) {
        shouldRecord = @(NO);
        objc_setAssociatedObject(self, @selector(shouldRecordLocations), shouldRecord, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return shouldRecord.boolValue;
}

- (void)setShouldRecordLocations:(BOOL)shouldRecordLocations
{
    objc_setAssociatedObject(self, @selector(shouldRecordLocations), @(shouldRecordLocations), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark -

- (NSDictionary *)currentLocationDic
{
    NSDictionary *dic = objc_getAssociatedObject(self, @selector(currentLocationDic));
    if (!dic) {
        dic = [NSDictionary dictionary];
        objc_setAssociatedObject(self, @selector(currentLocationDic), dic, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return dic;
}

- (void)setCurrentLocationDic:(NSDictionary *)currentLocationDic
{
    objc_setAssociatedObject(self, @selector(currentLocationDic), currentLocationDic, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark -

- (NSTimer *)recordLocationTimer
{
    return objc_getAssociatedObject(self, @selector(recordLocationTimer));
}

- (void)setRecordLocationTimer:(NSTimer *)recordLocationTimer
{
    objc_setAssociatedObject(self, @selector(recordLocationTimer), recordLocationTimer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark -

- (AWEInteractionStickerModel *)currentInteractionModel
{
    AWEInteractionStickerModel *model = objc_getAssociatedObject(self, @selector(currentInteractionModel));
    if (!model) {
        model = [[AWEInteractionStickerModel alloc] init];
        model.index = 0;
        model.type = AWEInteractionStickerTypeProps;
        objc_setAssociatedObject(self, @selector(currentInteractionModel), model, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return model;
}

- (void)setCurrentInteractionModel:(AWEInteractionStickerModel *)currentInteractionModel
{
    objc_setAssociatedObject(self, @selector(currentInteractionModel), currentInteractionModel, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark -

- (BOOL)stopRecording
{
    NSNumber *finished = objc_getAssociatedObject(self, @selector(stopRecording));
    if (finished == nil) {
        finished = @(NO);
        objc_setAssociatedObject(self, @selector(stopRecording), finished, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return finished.boolValue;
}

- (void)setStopRecording:(BOOL)stopRecording
{
    objc_setAssociatedObject(self, @selector(stopRecording), @(stopRecording), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark - public methods

- (void)startRecordStickerLocationsWithSticker:(IESEffectModel *)sticker
{
    if (![self p_serviceSupport]) {
        return;
    }
    
    //reset for each segment
    [self p_stopTimer];
    [self p_clearCurrentLocations];
    self.stopRecording = NO;
    
    NSDictionary *json = @{};
    if ([sticker.extra length]) {
        NSData *data = [sticker.extra dataUsingEncoding:NSUTF8StringEncoding];
        if (data) {
            NSError *error = nil;
            json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
            if (error) {
                AWELogToolError(AWELogToolTagRecord, @"JSONObjectWithData fail. %@", error);
            }
        }
    }
    
    if (json && [json isKindOfClass:[NSDictionary class]]) {
        NSError *error = nil;
        AWEInteractionExtraModel *extra = [MTLJSONAdapter modelOfClass:AWEInteractionExtraModel.class fromJSONDictionary:json error:&error];
        if (error) {
            AWELogToolError(AWELogToolTagRecord, @"modelOfClass fail. %@", error);
        }
        extra.stickerID = sticker.effectIdentifier;

        //full address of popIcon,use EffectPlatform domain
        if ([extra.popIcon length] && !([extra.popIcon hasPrefix:@"https://"] || [extra.popIcon hasPrefix:@"http://"])
            && [[EffectPlatform sharedInstance].platformURLPrefix count]) {
            NSString *host = [[EffectPlatform sharedInstance].platformURLPrefix firstObject];
            if ([host length] && ([host hasPrefix:@"https://"] || [host hasPrefix:@"http://"])) {
                [self p_cacheDomain:host];
                extra.popIcon = [host stringByAppendingString:extra.popIcon];
            }
        }
        //in case EffectPlatform.platformURLPrefix is empty
        if ([extra.popIcon length] && !([extra.popIcon hasPrefix:@"https://"] || [extra.popIcon hasPrefix:@"http://"])) {
            NSString * domain = [self p_domianFromFullPathArray:sticker.iconDownloadURLs];
            if (![domain length]) {
                domain = [self p_domianFromFullPathArray:sticker.fileDownloadURLs];
            }
            if (![domain length]) {
                domain = [ACCCache() objectForKey:kACCCameraClientEffectIconDomainKey];
            }
            NSAssert([domain length], @"domian is enpty");
            if ([domain length]) {
                extra.popIcon = [domain stringByAppendingString:extra.popIcon];
            }
        }
        
        //transfer to json string
        self.currentInteractionModel.type = AWEInteractionStickerTypeProps;
        NSError *jsonError = nil;
        NSDictionary *interaction_extra = [MTLJSONAdapter JSONDictionaryFromModel:extra error:&jsonError];
        NSMutableDictionary *extra_dic = [NSMutableDictionary dictionary];
        extra_dic[@"interaction_extra"] = interaction_extra;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:extra_dic options:kNilOptions error:&jsonError];
        if (jsonError) {
            AWELogToolError(AWELogToolTagRecord, @"dataWithJSONObject fail. %@", jsonError);
        }
        if (jsonData) {
            NSString * str = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
            if (str) {
                self.currentInteractionModel.attr = str;
            }
        }
        
        if (([extra.schemeURL length] || [extra.clickableWebURL length] || [extra.clickableOpenURL length]) &&
            ([extra.popIcon length] || [extra.popText length])) {//collect new segment locations each 0.3f
            self.shouldRecordLocations = YES;
            @weakify(self);
            self.recordLocationTimer = [NSTimer acc_scheduledTimerWithTimeInterval:0.3f block:^(NSTimer * _Nonnull timer) {
                @strongify(self);
                if (self.currentLocationDic) {
                    NSDictionary *dic = [self.currentLocationDic mutableCopy];
                    NSString *locationsStr = ACCDynamicCast(dic[@"locations"], NSString);
                    if ([locationsStr length]) {
                        NSError *error = nil;
                        NSData *data = [locationsStr dataUsingEncoding:NSUTF8StringEncoding];
                        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
                        if (json && [json isKindOfClass:[NSDictionary class]]) {
                            NSArray *locArr = ACCDynamicCast(json[@"locations"], NSArray);
                            if ([locArr isKindOfClass:[NSArray class]]) {
                                if ([locArr count]) {
                                    NSArray <AWEInteractionStickerLocationModel *>*locationModelArr = [MTLJSONAdapter modelsOfClass:AWEInteractionStickerLocationModel.class fromJSONArray:locArr error:&error];
                                    if (error) {
                                        AWELogToolError(AWELogToolTagRecord, @"modelsOfClass fail. %@", error);
                                    }
                                    [locationModelArr enumerateObjectsUsingBlock:^(AWEInteractionStickerLocationModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                                        NSNumber *pts = ACCDynamicCast(dic[@"pts"], NSNumber);
                                        obj.pts = [NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%ld",(long)pts.integerValue]];
                                        obj.scale = [NSDecimalNumber decimalNumberWithString:@"1.0"];
                                    }];
                                    [self.interactionModel.currentSectionLocations addObjectsFromArray:locationModelArr];
                                }
                            }
                        }
                    }
                }
            } repeats:YES];
        }
    }
}

- (void)appendStickerLocation:(NSString *)locationStr //json array string
                          pts:(CGFloat)pts
{
    if (self.shouldRecordLocations) {
        self.currentLocationDic = @{@"pts":@(pts*1000), @"locations":locationStr?:@""};
    }
}

- (void)endRecordStickerLocations
{
    if (![self p_serviceSupport]) {
        return;
    }
    
    //reach max 15s or no change in record vc for draft recover
    if (self.stopRecording || ![self.currentInteractionModel.attr length]) {
        return;
    }
    self.stopRecording = YES;
    self.shouldRecordLocations = NO;
    [self p_stopTimer];

    if ([self.interactionModel.currentSectionLocations count]) {
        //locations transfer to json array string
        NSMutableArray *locations = [self.interactionModel.currentSectionLocations mutableCopy];
        NSError *error = nil;
        NSArray *arr = [MTLJSONAdapter JSONArrayFromModels:locations error:&error];
        NSData *arrJsonData = [NSJSONSerialization dataWithJSONObject:arr options:kNilOptions error:&error];
        if (error) {
            AWELogToolError(AWELogToolTagRecord, @"JSONArrayFromModels fail. %@", error);
        }
        if (arrJsonData) {
            NSString * locationStr = [[NSString alloc] initWithData:arrJsonData encoding:NSUTF8StringEncoding];
            if (locationStr) {
                self.currentInteractionModel.trackInfo = locationStr;
            }
        }
    } else {
        self.currentInteractionModel.trackInfo = nil;
    }

    AWEInteractionStickerModel * interactionModel = [self.currentInteractionModel copy];
    if (interactionModel) {
        [self.interactionModel.interactionModelArray acc_addObject:interactionModel];
    }
}

- (void)removeLastSegmentStickerLocations
{
    if ([self.interactionModel.interactionModelArray count]) {
        [self.interactionModel.interactionModelArray removeLastObject];
    }
    [self p_clearCurrentLocations];
}

- (void)removeAllSegmentStickerLocations
{
    if ([self.interactionModel.interactionModelArray count]) {
        [self.interactionModel.interactionModelArray removeAllObjects];
    }
    [self p_clearCurrentLocations];
}


#pragma mark - metadata

- (NSString *)prepareExtraMetaInfoForComposer
{
    AWERepoVideoInfoModel *videoInfo = [self.repository extensionModelOfClass:AWERepoVideoInfoModel.class];
    if (![self p_serviceSupport]) {
        videoInfo.video.extraMetaInfo = @"";
        return videoInfo.video.extraMetaInfo;
    }
    
    if (![self.interactionModel.interactionModelArray count]) {
        videoInfo.video.extraMetaInfo = @"";
    } else {
        NSMutableArray *interactionModelArray = [self p_filterNoLocationSticker];
        if (![interactionModelArray count]) {
            videoInfo.video.extraMetaInfo = @"";
        } else {
            //NSTimeInterval start = CFAbsoluteTimeGetCurrent();
            NSMutableArray *result = [NSMutableArray array];
            [self p_getSameArrayList:interactionModelArray result:result];
            NSArray *mergedArray = [self p_mergeSameStickerLocationsWithSameArrayList:result];
            NSError *error = nil;
            NSArray *arr = [MTLJSONAdapter JSONArrayFromModels:mergedArray error:&error];
            if (error) {
                AWELogToolError(AWELogToolTagRecord, @"JSONArrayFromModels fail. %@", error);
            }
            //remove useless key-value
            NSMutableArray *tmpArr = [NSMutableArray arrayWithArray:arr];
            [tmpArr enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([obj isKindOfClass:[NSDictionary class]]) {
                    NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:obj];
                    dic[@"poi_info"] = nil;
                    [tmpArr replaceObjectAtIndex:idx withObject:dic];
                }
            }];
            NSError *arrError = nil;
            NSData *arrJsonData = [NSJSONSerialization dataWithJSONObject:tmpArr options:kNilOptions error:&arrError];
            if (arrError) {
                AWELogToolError(AWELogToolTagRecord, @"dataWithJSONObject fail. %@", arrError);
            }
            if (arrJsonData) {
                NSString * arrJsonStr = [[NSString alloc] initWithData:arrJsonData encoding:NSUTF8StringEncoding];
                if ([arrJsonStr length]) {
                    NSMutableDictionary *finalDic = [NSMutableDictionary dictionary];
                    if ([videoInfo.video.extraMetaInfo length]) {//别的业务往com.bytedance.info这个dic写了数据
                        NSData *extraData = [videoInfo.video.extraMetaInfo dataUsingEncoding:NSUTF8StringEncoding];
                        NSError *extraError = nil;
                        NSDictionary *extraDic = [NSJSONSerialization JSONObjectWithData:extraData options:0 error:&extraError];
                        if (extraError) {
                            AWELogToolError(AWELogToolTagRecord, @"JSONObjectWithData fail. %@", extraError);
                        }
                        if (extraDic && [extraDic isKindOfClass:[NSDictionary class]]) {
                            finalDic = [NSMutableDictionary dictionaryWithDictionary:extraDic];
                            NSDictionary *infoDic = ACCDynamicCast(finalDic[@"com.bytedance.info"], NSDictionary);
                            if (infoDic && [infoDic isKindOfClass:[NSDictionary class]]) {
                                NSMutableDictionary *infoMutDic = [NSMutableDictionary dictionaryWithDictionary:infoDic];
                                [infoMutDic addEntriesFromDictionary:@{@"interaction_stickers":arrJsonStr}];
                                finalDic[@"com.bytedance.info"] = [NSDictionary dictionaryWithDictionary:infoMutDic];
                            } else {
                                [finalDic addEntriesFromDictionary:@{@"com.bytedance.info":@{@"interaction_stickers":arrJsonStr}}];
                            }
                        }
                    } else {
                        finalDic = [NSMutableDictionary dictionaryWithDictionary:@{@"com.bytedance.info":@{@"interaction_stickers":arrJsonStr}}];
                    }
                    
                    //finally transfer to json string
                    NSError *jsonError = nil;
                    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:finalDic options:kNilOptions error:&jsonError];
                    if (jsonError) {
                        AWELogToolError(AWELogToolTagRecord, @"dataWithJSONObject fail. %@", jsonError);
                    }
                    if (jsonData) {
                        NSString * str = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                        if ([str length]) {
                            videoInfo.video.extraMetaInfo = str;
                        }
                    }
                    
                }
            }
        }
    }
    
    return videoInfo.video.extraMetaInfo;
}

#pragma mark - draft logic
//按片段保存草稿，因为恢复回来可能用户会一段段的删；
- (NSString * _Nullable)getInteractionProps
{
    if (![self.interactionModel.interactionModelArray count]) {
        return nil;
    }
    
    NSError *error = nil;
    NSArray *stickers = [MTLJSONAdapter JSONArrayFromModels:self.interactionModel.interactionModelArray error:&error];
    if (error) {
        AWELogToolError(AWELogToolTagRecord, @"JSONArrayFromModels fail. %@", error);
    }
    if ([stickers count]) {
        NSError *error = nil;
        NSData *arrJsonData = [NSJSONSerialization dataWithJSONObject:stickers options:NSJSONWritingPrettyPrinted error:&error];
        if (error) {
            AWELogToolError(AWELogToolTagRecord, @"dataWithJSONObject fail. %@", error);
        }
        if (arrJsonData) {
            NSString *arrJsonStr = [[NSString alloc] initWithData:arrJsonData encoding:NSUTF8StringEncoding];
            return arrJsonStr;
        }
    }
    return nil;
}

- (void)recoverWithDraftInteractionProps:(NSString *)interactionProps
{
    if (![interactionProps length]) {
        self.interactionModel.interactionModelArray = [NSMutableArray array];
    } else {
        NSData* data = [interactionProps dataUsingEncoding:NSUTF8StringEncoding];
        if (data) {
            NSError *error = nil;
            NSArray *values = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
            if ([values isKindOfClass:[NSArray class]]) {
                if ([values count]) {
                    NSArray *stickerArr = [MTLJSONAdapter modelsOfClass:[AWEInteractionStickerModel class] fromJSONArray:values error:&error];
                    if (error) {
                        AWELogToolError(AWELogToolTagRecord, @"modelsOfClass fail. %@", error);
                    }
                    if ([stickerArr count]) {
                        self.interactionModel.interactionModelArray = (NSMutableArray<AWEInteractionStickerModel *> *)[NSMutableArray arrayWithArray:stickerArr];
                        AWELogToolInfo2(@"Props",AWELogToolTagDraft, @"recover draft interaction props array: %@", self.interactionModel.interactionModelArray);
                    }
                }
            }
        }
    }
}

#pragma mark - private methods

- (void)p_clearCurrentLocations
{
    if ([self.interactionModel.currentSectionLocations count]) {
        [self.interactionModel.currentSectionLocations removeAllObjects];
    }
}

- (void)p_stopTimer
{
    if ([self.recordLocationTimer isValid]) {
        [self.recordLocationTimer invalidate];
    }
}

-(NSMutableArray *)p_filterNoLocationSticker
{
    NSMutableArray *arr = [NSMutableArray arrayWithArray:self.interactionModel.interactionModelArray];
    [arr enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(AWEInteractionStickerModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (![obj.trackInfo length]) {
            [arr removeObjectAtIndex:idx];
        }
    }];
    return arr;
}

- (NSMutableArray *)p_getSameArrayList:(NSArray <AWEInteractionStickerModel *> *)arrayList result:(NSMutableArray *)result
{
    if (![arrayList count]) {
        return [NSMutableArray array];
    }
    NSMutableArray *diffArray = [NSMutableArray array];
    NSMutableArray *sameArray = [NSMutableArray array];

    [sameArray acc_addObject:[arrayList firstObject]];

    if ([arrayList count] > 1) {
        AWEInteractionStickerModel *firstItem = (AWEInteractionStickerModel *)[sameArray firstObject];
        NSString *firstItemSticker = @"";
        if ([firstItem.attr length]) {
            NSData *data = [firstItem.attr dataUsingEncoding:NSUTF8StringEncoding];
            NSError *error = nil;
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
            if (error) {
                AWELogToolError(AWELogToolTagRecord, @"JSONObjectWithData fail. %@", error);
            }
            if (json && [json isKindOfClass:[NSDictionary class]]) {
                NSDictionary *json_extra = ACCDynamicCast(json[@"interaction_extra"], NSDictionary);
                if (json_extra && [json_extra isKindOfClass:[NSDictionary class]]) {
                    if (json_extra[@"sticker_id"] && [json_extra[@"sticker_id"] isKindOfClass:[NSString class]]) {
                        firstItemSticker = ACCDynamicCast(json_extra[@"sticker_id"], NSString);
                    }
                }
            }
        }
        
        for (int i = 1; i < arrayList.count; i ++) {
            AWEInteractionStickerModel *item = [arrayList objectAtIndex:i];
            NSString *itemSticker = @"";
            if ([item.attr length]) {
                NSData *item_data = [item.attr dataUsingEncoding:NSUTF8StringEncoding];
                NSError *error = nil;
                NSDictionary *item_json = [NSJSONSerialization JSONObjectWithData:item_data options:0 error:&error];
                if (error) {
                    AWELogToolError(AWELogToolTagRecord, @"JSONObjectWithData fail. %@", error);
                }
                if (item_json && [item_json isKindOfClass:[NSDictionary class]]) {
                    NSDictionary *item_json_extra = ACCDynamicCast(item_json[@"interaction_extra"], NSDictionary);
                    if (item_json_extra && [item_json_extra isKindOfClass:[NSDictionary class]]) {
                        if (item_json_extra[@"sticker_id"] && [item_json_extra[@"sticker_id"] isKindOfClass:[NSString class]]) {
                            itemSticker = ACCDynamicCast(item_json_extra[@"sticker_id"], NSString);
                        }
                    }
                }
            }
            
            if ([itemSticker isEqualToString:firstItemSticker]) {
                [sameArray acc_addObject:arrayList[i]];
            } else {
                [diffArray acc_addObject:arrayList[i]];
            }
        }
    }

    [result acc_addObject:sameArray];
    if ([diffArray count]) {
        [self p_getSameArrayList:diffArray result:result];
    }
    return result;
}

- (NSArray <AWEInteractionStickerModel *> *)p_mergeSameStickerLocationsWithSameArrayList:(NSArray <NSArray <AWEInteractionStickerModel *> *>*)result
{
    
    NSMutableArray *arr = [NSMutableArray array];
    
    [result enumerateObjectsUsingBlock:^(NSArray<AWEInteractionStickerModel *> * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj count] == 1) {
            [arr acc_addObject:[obj firstObject]];
        } else if ([obj count] > 1) {
            NSMutableArray *locations = [NSMutableArray array];
            AWEInteractionStickerModel *item = [(AWEInteractionStickerModel *)[obj firstObject] copy];
            __block NSError *error = nil;
            [obj enumerateObjectsUsingBlock:^(AWEInteractionStickerModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                NSData *data = [obj.trackInfo dataUsingEncoding:NSUTF8StringEncoding];
                NSArray *jsonArr = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
                [locations addObjectsFromArray:jsonArr];
            }];
            
            NSData *arrJsonData = [NSJSONSerialization dataWithJSONObject:locations options:kNilOptions error:&error];
            if (error) {
                AWELogToolError(AWELogToolTagRecord, @"dataWithJSONObject fail. %@", error);
            }
            if (arrJsonData) {
                NSString * arrJsonStr = [[NSString alloc] initWithData:arrJsonData encoding:NSUTF8StringEncoding];
                if ([arrJsonStr length]) {
                    item.trackInfo = arrJsonStr;
                }
            }
            [arr acc_addObject:item];
        }
    }];
    
    return arr;
}

//合拍、抢镜不支持
- (BOOL)p_serviceSupport
{
    ACCRepoDuetModel *duet = [self.repository extensionModelOfClass:ACCRepoDuetModel.class];
    if (duet.isDuet) {
        return NO;
    }
    return YES;
}

- (NSString *)p_domianFromFullPathArray:(NSArray<NSString *> *)array
{
    NSString *prefix = @"";
    if ([array count]) {
        NSString *firstItem = [array firstObject];
        if ([firstItem length] && ([firstItem hasPrefix:@"https://"] || [firstItem hasPrefix:@"http://"])) {
            prefix = [firstItem stringByDeletingLastPathComponent];
            prefix = [prefix stringByAppendingString:@"/"];
        }
    }
    if ([prefix length]) {
        [self p_cacheDomain:prefix];
    }
    return prefix;;
}

- (void)p_cacheDomain:(NSString *)domian
{
    if (![domian length]) {
        return;
    }
    [ACCCache() setObject:domian forKey:kACCCameraClientEffectIconDomainKey];
}

@end
