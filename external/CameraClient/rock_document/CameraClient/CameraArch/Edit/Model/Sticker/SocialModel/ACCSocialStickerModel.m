//
//  ACCSocialStickerModel.m
//  CameraClient-Pods-Aweme
//
//  Created by qiuhang on 2020/8/6.
//

#import "ACCSocialStickerModel.h"
#import <CreativeKit/ACCMacros.h>
#import <Mantle/EXTKeyPathCoding.h>

// internal wrap model, using for store draft, keep stable
@interface ACCSocialStickerDraftModel : MTLModel <MTLJSONSerializing>

@property (nonatomic,   copy) NSString *contentString;
@property (nonatomic, strong) ACCSocialStickeMentionBindingModel *_Nullable mentionBindingModel;
@property (nonatomic, assign) BOOL isAutoAdded;
@property (nonatomic,   copy) NSString *extraInfo;

@end

@implementation ACCSocialStickerModel

#pragma mark - life cycle
- (instancetype)initWithStickerType:(ACCSocialStickerType)stickerType
                   effectIdentifier:(NSString *)effectIdentifier {
    
    if (self = [super init]) {
        _stickerType = stickerType;
        _effectIdentifier = [effectIdentifier copy];
    }
    return self;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    
    ACCSocialStickerModel *model = [[ACCSocialStickerModel allocWithZone:zone] init];
    [model mergeValuesFromStickerModel:self];
    return model;
}

- (void)mergeValuesFromStickerModel:(ACCSocialStickerModel *)targetStickerModel {
    
    _effectIdentifier = [targetStickerModel.effectIdentifier copy];
    _stickerType      = targetStickerModel.stickerType;
    _contentString    = [targetStickerModel.contentString copy];
    _mentionBindingModel = [targetStickerModel.mentionBindingModel copy];
    _isAutoAdded = targetStickerModel.isAutoAdded;
    _extraInfo   = [targetStickerModel.extraInfo copy];
}

#pragma mark - public getter
- (BOOL)hasVaildMentionBindingData {
    
    if (self.stickerType == ACCSocialStickerTypeHashTag) {
        return NO;
    }
    return self.mentionBindingModel.isValid;
}

- (BOOL)hasVaildHashtagBindingData
{
    /// hashtag 只要有内容就算绑定
    if (self.stickerType == ACCSocialStickerTypeHashTag && !ACC_isEmptyString(self.contentString)) {
        return YES;
    }
    
    return NO;
}

- (BOOL)isNotEmpty {
    return !ACC_isEmptyString(self.contentString);
}

- (NSDictionary *)trackInfo
{
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"selected_from"] = self.isAutoAdded? @"auto":@"prop_entrance";
    params[@"at_cnt"] = @0;
    params[@"tag_cnt"] = @0;
    
    if (self.stickerType == ACCSocialStickerTypeMention && self.mentionBindingModel.isValid) {
        params[@"at_cnt"] = @1;
    } else if (self.stickerType == ACCSocialStickerTypeHashTag && !ACC_isEmptyString(self.contentString)) {
        params[@"tag_cnt"] = @1;
    }
    
    return [params copy];
}

#pragma mark - draft handler
- (void)recoverDataFromDraftJsonString:(NSString *)jsonString {
    
    if (ACC_isEmptyString(jsonString)) {
        return;
    }
    
    ACCSocialStickerDraftModel *draftMode = nil;
    
    @try {
        
        NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding]
                                                            options:kNilOptions
                                                              error:nil];
        if ([dic isKindOfClass:NSDictionary.class]) {
            draftMode = [MTLJSONAdapter modelOfClass:[ACCSocialStickerDraftModel class]
                                  fromJSONDictionary:dic
                                               error:nil];
        }
        
    } @catch (NSException *exception) {}
    
    if (!draftMode) {
        return;
    }
    
    self.contentString = draftMode.contentString;
    self.isAutoAdded = draftMode.isAutoAdded;
    self.extraInfo = draftMode.extraInfo;
    
    if([draftMode.mentionBindingModel isValid]) {
        self.mentionBindingModel = draftMode.mentionBindingModel;
    }
}

- (NSString *)draftDataJsonString {
    
    if (ACC_isEmptyString(self.contentString)) {
        return nil; // invaild, 
    }
    
    ACCSocialStickerDraftModel *draftModel = [ACCSocialStickerDraftModel new];
    
    draftModel.contentString = self.contentString;
    draftModel.extraInfo = self.extraInfo;
    if ([self hasVaildMentionBindingData]) {
        draftModel.mentionBindingModel = self.mentionBindingModel;
    }
    
    NSString *result = nil;

    @try {
        NSDictionary *draftDic = [MTLJSONAdapter JSONDictionaryFromModel:draftModel error:nil];
        if (draftDic) {
            NSData *draftData = [NSJSONSerialization dataWithJSONObject:draftDic options:kNilOptions error:nil];
            if(draftData) {
                result = [[NSString alloc] initWithData:draftData encoding:NSUTF8StringEncoding];
            }
        }
    } @catch (NSException *exception) {}
    
    return result;
}

@end


@implementation ACCSocialStickeMentionBindingModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    
    ACCSocialStickeMentionBindingModel *model = nil;
    
    return @{@keypath(model, secUserId) : @"secUserId",
             @keypath(model, userId)    : @"userId",
             @keypath(model, userName)  : @"userName",
             @keypath(model, followStatus) : @"followStatus"
    };
}

+ (instancetype)modelWithSecUserId:(NSString *)secUserId
                            userId:(NSString *)userId
                          userName:(NSString *)userName
                      followStatus:(NSInteger)followStatus
{
    
    ACCSocialStickeMentionBindingModel *model = [ACCSocialStickeMentionBindingModel new];
    model.secUserId = secUserId;
    model.userId    = userId;
    model.userName  = userName;
    model.followStatus = followStatus;
    return model;
}

- (BOOL)isValid {
    return (!ACC_isEmptyString(self.secUserId) &&
            !ACC_isEmptyString(self.userId) &&
            !ACC_isEmptyString(self.userName));
}

@end

@implementation ACCSocialStickeHashTagBindingModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    
    ACCSocialStickeHashTagBindingModel *model = nil;
    
    return @{@keypath(model, hashTagName) : @"hashTagName"};
}

+ (instancetype)modelWithHashTagName:(NSString *)hashTagName {
    ACCSocialStickeHashTagBindingModel *model = [ACCSocialStickeHashTagBindingModel new];
    model.hashTagName = hashTagName;
    return model;
}

@end


@implementation ACCSocialStickerDraftModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    
    ACCSocialStickerDraftModel *model = nil;
    
    return @{@keypath(model, contentString)       : @"contentString",
             @keypath(model, mentionBindingModel) : @"mentionBindingModel",
             @keypath(model, extraInfo)           : @"extraInfo",
    };
}

+ (NSValueTransformer *)bindingModelJSONTransformer {
    return [MTLJSONAdapter dictionaryTransformerWithModelClass:[ACCSocialStickeMentionBindingModel class]];
}

@end
