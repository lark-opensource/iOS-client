//
//  AWERepoPublishConfigModel.m
//  CameraClient-Pods-Aweme
//
//  Created by yangying on 2020/10/21.
//

#import "AWERepoPublishConfigModel.h"
#import "ACCConfigKeyDefines.h"

#import <CreationKitArch/ACCPublishRepositoryElementProtocols.h>
#import <CreationKitArch/AWEVideoPublishViewModel+Repository.h>
#import <CreationKitInfra/ACCLogProtocol.h>
#import <CreationKitArch/AWEVideoCoverConfig.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/UIImage+ACC.h>
#import <CreationKitArch/ACCModelFactoryServiceProtocol.h>
#import <CreationKitArch/AWECoverTextModel.h>
#import <CameraClient/AWERepoContextModel.h>
#import <CameraClient/ACCRepoImageAlbumInfoModel.h>

@interface AWEVideoPublishViewModel (AWERepoPublishConfig) <ACCRepositoryElementRegisterCategoryProtocol>

@end

@implementation AWEVideoPublishViewModel (AWERepoPublishConfig)

- (ACCRepositoryRegisterInfo *)repoRegisterInfo {
	ACCRepositoryRegisterInfo *info = [[ACCRepositoryRegisterInfo alloc] initWithClassInfo:AWERepoPublishConfigModel.class];
	return info;
}

- (AWERepoPublishConfigModel *)repoPublishConfig
{
    AWERepoPublishConfigModel *publishConfigModel = [self extensionModelOfClass:AWERepoPublishConfigModel.class];
    NSAssert(publishConfigModel, @"extension model should not be nil");
    return publishConfigModel;
}

@end

@interface AWERepoPublishConfigModel()<ACCRepositoryRequestParamsProtocol, ACCRepositoryTrackContextProtocol, ACCRepositoryContextProtocol>

@end

@implementation AWERepoPublishConfigModel

@synthesize repository, titleExtraInfo = _titleExtraInfo, publishTitle = _publishTitle;

- (id)copyWithZone:(NSZone *)zone
{
    AWERepoPublishConfigModel *model = [super copyWithZone:zone];

    model.recommendedAICoverIndex = self.recommendedAICoverIndex;
    model.recommendedAICoverTime = self.recommendedAICoverTime;
    model.coverTitleSelectedFrom = self.coverTitleSelectedFrom;
    model.coverTitleSelectedId = self.coverTitleSelectedId;
    model.activityHashtagID = self.activityHashtagID;
    model.isFirstPost = self.isFirstPost;
    model.titleExtraInfoData = self.titleExtraInfoData;
    model.coverImagePath = self.coverImagePath;
    model.coverTextPath = self.coverTextPath;
    model.firstFramePath = self.firstFramePath;
    model.coverImagePathRelative = self.coverImagePathRelative;
    model.coverTextPathRelative = self.coverTextPathRelative;
    model.firstFramePathRelative = self.firstFramePathRelative;
    model.cropedCoverImagePathRelative = self.cropedCoverImagePathRelative;
    model.coverCropOffset = self.coverCropOffset;
    model.tosCropCoverURI = self.tosCropCoverURI;
    model.cropedCoverImage = self.cropedCoverImage;
    model.meteorModeCover = self.meteorModeCover;
    model.isUserSelectedCover = self.isUserSelectedCover;
    model.shouldHideInMyPosts = self.shouldHideInMyPosts;
    model.isParameterizedCreation = self.isParameterizedCreation;
    model.isSilentPublish = self.isSilentPublish;
    model.publishPhaseIsAfterSynthesis = self.publishPhaseIsAfterSynthesis;
    
    model.unmodifiablePublishParams = self.unmodifiablePublishParams;
    model.categoryDA = self.categoryDA;
    model.isPublishCanvasAsImageAlbum = self.isPublishCanvasAsImageAlbum;
    model.isSaveToAlbumSourceImage = self.isSaveToAlbumSourceImage;
    model.dynamicyPrepareCanvasPublishAsImageFlagValue = self.dynamicyPrepareCanvasPublishAsImageFlagValue;
    model.shouldForceSDR = self.shouldForceSDR;
    model.lensName = self.lensName;

        return model;
}

- (NSDictionary *)recommendedAICoverTrackInfo
{
    return [self recommendedAICoverTrackInfoWithCoverStartTime:self.dynamicCoverStartTime];
}

- (NSDictionary *)recommendedAICoverTrackInfoWithCoverStartTime:(CGFloat)coverStartTime
{
    NSString *cover_selected_from = nil; // default（未获取到推荐封面，默认视频首帧）、recommend（推荐封面）、select（用户主动选择的某帧）
    NSString *cover_frame = nil; // 封面是第几帧（首帧取值为0）
    if (ACC_FLOAT_EQUAL_ZERO(coverStartTime)) {
        cover_selected_from = @"default";
        cover_frame = @"0";
    } else if (ACC_FLOAT_EQUAL_TO(coverStartTime, self.recommendedAICoverTime.doubleValue)) {
        cover_selected_from = @"recommend";
        cover_frame = self.recommendedAICoverIndex.stringValue;
    } else {
        cover_selected_from = @"select";
        cover_frame = @"0";
    }
    AWERepoContextModel *repoContext = [self.repository extensionModelOfClass:AWERepoContextModel.class];

    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    dictionary[@"cover_selected_from"] = cover_selected_from;
    if (repoContext.isReedit) {
        dictionary[@"cover_frame"] = @(cover_frame.intValue);
    } else {
        dictionary[@"cover_frame"] = cover_frame;
    }

    dictionary[@"cover_title_id"] = self.coverTitleSelectedId;
    dictionary[@"cover_title_selected_from"] = self.coverTitleSelectedFrom;

    return [dictionary copy];
}

- (void)notifyTitleObserver
{
    if (self.titleObserver) {
        [self.titleObserver publishTitleHasChanged:self.publishTitle extraInfo:self.titleExtraInfo];
    }
}

- (UIImage *)composedCoverImage
{
    if (self.cropedCoverImage) {
        return [UIImage acc_composeImage:self.cropedCoverImage withImage:[AWEVideoCoverConfig cropImage:self.coverTextImage]];
    }
    return [UIImage acc_composeImage:self.coverImage withImage:self.coverTextImage];
}

#pragma mark - setter & getter

- (void)setTitleExtraInfo:(NSArray<id<ACCTextExtraProtocol>> *)titleExtraInfo
{
    if (titleExtraInfo) {
        [titleExtraInfo enumerateObjectsUsingBlock:^(id<ACCTextExtraProtocol> _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSAssert([obj conformsToProtocol:@protocol(ACCTextExtraProtocol)], @"model type wrong");
        }];
    }
    _titleExtraInfo = titleExtraInfo;
    [self notifyTitleObserver];
}

- (void)setPublishTitle:(NSString *)publishTitle
{
    _publishTitle = publishTitle;
    [self notifyTitleObserver];
}

- (UIImage *)cropedCoverImage
{
    if (ACCConfigBool(kConfigBool_enable_cover_clip)) {
        return _cropedCoverImage;
    }
    return nil;
}

#pragma mark - ACCRepositoryRequestParamsProtocol

- (NSDictionary *)acc_publishRequestParams:(AWEVideoPublishViewModel *)publishViewModel
{
    if (publishViewModel.repoContext.isReedit) {
        NSMutableDictionary *params = [NSMutableDictionary dictionary];
        NSMutableDictionary *textInfo = [NSMutableDictionary dictionary];
        textInfo[@"is_edit_text"] = @([self isTitleModified]);
        if ([self respondsToSelector:@selector(appendTitleToParamDict:publishModel:)]) {
            [self appendTitleToParamDict:textInfo publishModel:publishViewModel];
        }
        params[@"text_info"] = textInfo;
        NSMutableDictionary *coverInfo = [[self p_coverTextServerTrackParams] mutableCopy];
        if (!publishViewModel.repoImageAlbumInfo.isImageAlbumEdit) {
            coverInfo[@"cover_tsp"] = @([self isSelectCoverModified] ? self.dynamicCoverStartTime : -1);
        }
        params[@"cover_uri"] = coverInfo;
        return params.copy;
    }
    
    NSMutableDictionary *params = @{
        @"is_hash_tag" : @(self.isHashTag),
        @"cover_tsp" : @(self.dynamicCoverStartTime),
        @"from_first_post" : @(self.isFirstPost),
    }.mutableCopy;
    
    if ([self respondsToSelector:@selector(appendTitleToParamDict:publishModel:)]) {
        [self appendTitleToParamDict:params publishModel:publishViewModel];
    }
    
    // caption 字数
    params[@"caption_word_cnt"] = [@(self.publishTitle.length) stringValue];
    
    if (self.activityHashtagID) {
        params[@"activity_hashtag_id"] = self.activityHashtagID;
    }
    
    if (self.tosCoverURI) {
        params[@"video_cover_uri"] = self.tosCoverURI;
    }
    
    [params addEntriesFromDictionary:[self p_coverTextServerTrackParams]];
    
    if (self.unmodifiablePublishParams) {
        [params addEntriesFromDictionary:self.unmodifiablePublishParams];
    }
    
    params[@"publish_list_invisible"] = self.shouldHideInMyPosts ? @(1) : @(0); // 是否在展示在「我的作品」中
    
    return params;
}


- (NSDictionary *)p_coverTextServerTrackParams
{
    NSMutableDictionary *serverParams = [NSMutableDictionary dictionary];
    AWECoverTextModel *model = self.coverTextModel;
    __block BOOL textNotEmpty = NO;
    [model.texts enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.length > 0) {
            textNotEmpty = YES;
            *stop = YES;
        }
    }];
    
    NSString *text_id = @"0";
    NSString *is_pic_adjust = ACC_FLOAT_EQUAL_TO(self.dynamicCoverStartTime, 0) ? @"0" : @"1";
    BOOL hasCoverText = NO;
    
    if (model.isStoryText && textNotEmpty) {
        text_id = @"1";
        hasCoverText = YES;
    } else if (model.textEffectId.length > 0) {
        text_id = textNotEmpty ? @"1" : @"2";
        hasCoverText = YES;
    }
    
    AWERepoContextModel *repoContext = [self.repository extensionModelOfClass:AWERepoContextModel.class];
    if (repoContext.isReedit) {
        serverParams[@"is_cover_text"] = hasCoverText ? @(text_id.intValue) : @-1;
        serverParams[@"is_cover_positioned"] = @(is_pic_adjust.intValue);
    } else {
        [serverParams setObject:text_id forKey:@"is_cover_text"];
        [serverParams setObject:is_pic_adjust forKey:@"is_cover_positioned"];
    }
    if (hasCoverText) {
        NSString *text_id = model.isStoryText ? @"" : model.textEffectId;
        NSString *font_id = model.textModel.fontModel.effectId ? : @"";
        NSString *text_color = model.textModel.fontColor.colorString ? : @"";
        
        NSDictionary *coverTextAttr = @{
            @"cover_text_id" : text_id,
            @"cover_text_font" : font_id,
            @"cover_text_color" : text_color
        };
        serverParams[@"cover_text_attr"] = [self p_jsonStringEncoded:coverTextAttr];
    }
    
    return [serverParams copy];
}

- (NSString *)p_jsonStringEncoded:(id)obj {
    if ([NSJSONSerialization isValidJSONObject:obj]) {
        NSError *error = nil;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:obj options:kNilOptions error:&error];
        if (error) {
            AWELogToolError(AWELogToolTagNone, @"%s %@", __PRETTY_FUNCTION__, error);
        }
        NSString *json = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        return json;
    }
    return nil;
}

- (BOOL)isTitleModified {
    // 标题被修改
    if (ACC_isEmptyString(self.publishTitle)) {
        return !ACC_isEmptyString([self originalModel].repoPublishConfig.publishTitle);
    } else {
        return ![self.publishTitle isEqualToString:[self originalModel].repoPublishConfig.publishTitle];
    }
}

- (BOOL)isSelectCoverModified {
    // 选封面修改
    AWEVideoPublishViewModel *origin = [self originalModel];
    ACCRepoImageAlbumInfoModel *repoImageAlbum = [self.repository extensionModelOfClass:ACCRepoImageAlbumInfoModel.class];
    if (repoImageAlbum.isImageAlbumEdit) {
        return self.isUserSelectedCover ||     (origin.repoImageAlbumInfo.dynamicCoverIndex != repoImageAlbum.dynamicCoverIndex);
    }
    return self.isUserSelectedCover || !ACC_FLOAT_EQUAL_TO(self.dynamicCoverStartTime, origin.repoPublishConfig.dynamicCoverStartTime);
}

- (BOOL)isCoverTextModified {
    // 封面文字修改
    AWECoverTextModel *model = self.coverTextModel;
    __block BOOL textNotEmpty = NO;
    [model.texts enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.length > 0) {
            textNotEmpty = YES;
            *stop = YES;
        }
    }];
    BOOL hasCoverText = NO;
    if (model.isStoryText && textNotEmpty) {
        hasCoverText = YES;
    } else if (model.textEffectId.length > 0) {
        hasCoverText = YES;
    }
    AWECoverTextModel *originCoverText = [self originalModel].repoPublishConfig.coverTextModel;
    BOOL contentModified = ![model.texts isEqualToArray:originCoverText.texts] || ![model.textEffectId?:@"" isEqualToString:originCoverText.textEffectId?:@""];
    return hasCoverText && contentModified;
}

- (AWEVideoPublishViewModel *)originalModel {
    AWERepoContextModel *repoContext = [self.repository extensionModelOfClass:AWERepoContextModel.class];
    return repoContext.sourceModel;
}

#pragma mark - Track Info

- (NSDictionary *)acc_referExtraParams
{
    NSMutableDictionary *mutableDict = [NSMutableDictionary dictionary];
    
    mutableDict[@"show_in_my_works_switch_status"] = self.shouldHideInMyPosts ? @(0) : @(1);
    
    return [mutableDict copy];
}

@end
