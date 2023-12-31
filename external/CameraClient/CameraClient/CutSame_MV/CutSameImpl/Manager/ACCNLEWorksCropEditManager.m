//
//  ACCNLEWorksCropEditManager.m
//  CameraClient-Pods-Aweme
//
//  Created by wanghongyu on 2021/2/28.
//

#import "AWERepoCutSameModel.h"
#import "ACCNLEWorksCropEditManager.h"
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreativeKit/ACCTrackProtocol.h>
#import <VideoTemplate/NSArray+LV.h>
#import <VideoTemplate/AVAsset+LV.h>

#import <CreationKitInfra/ACCAlertProtocol.h>
#import <CreationKitArch/ACCRepoMVModel.h>
#import <CreationKitArch/ACCRepoTrackModel.h>
#import <CreationKitArch/ACCRepoContextModel.h>
#import <CreationKitArch/ACCRepoMusicModel.h>

@interface ACCNLEWorksCropEditManager ()

@property (nonatomic, strong, readwrite) LVCutSameVideoMaterial *fragment;

@property (nonatomic, strong, readwrite) LVTemplateDataManager *dataManager;

@property (nonatomic, strong, readwrite) id<ACCCutSameFragmentModelProtocol> fragmentModel;

@property (nonatomic, copy) dispatch_block_t internalChangeMaterialBlock;

@property (nonatomic, assign) BOOL didModifiedRange;

@property (nonatomic, assign) NSInteger curIdx;

@property (nonatomic, copy) NSString *nleFolder;

@property (nonatomic, weak) NLEModel_OC *nleModel;

@end

@implementation ACCNLEWorksCropEditManager

- (instancetype)initWithDataManager:(LVTemplateDataManager *)dataManager
                           fragment:(LVCutSameVideoMaterial *)fragment
                      fragmentModel:(nonnull id<ACCCutSameFragmentModelProtocol>)fragmentModel
                             curIdx:(NSInteger)curIdx
                           aligMode:(NSString *)alignMode
                          nleFolder:(nullable NSString *)nleFolder
                              toNLE:(nullable NLEModel_OC *)nleModel
{
    self = [super init];
    
    if (self) {
        self.dataManager = dataManager;
        self.fragment = fragment;
        self.fragmentModel = fragmentModel;
        self.curIdx = curIdx;
        self.nleModel = nleModel;
        self.nleFolder = nleFolder;
        
        if (![fragmentModel.materialId isEqualToString:fragment.materialId]) {
            NSAssert(NO, @"Big Error! material id not match");
        }
        
        @weakify(self);
        self.internalChangeMaterialBlock = ^{
            @strongify(self);
            
            if (self.changeMaterialAction) {
                self.changeMaterialAction(nil, self.curIdx, fragment.isReversed, self.fragment.sourceTimeRange.duration, ^(AWECutSameMaterialAssetModel * _Nonnull replaceMaterialAsset) {
                    @strongify(self);
                    CMTimeRange newTimeRange = CMTimeRangeMake(kCMTimeZero, self.fragment.sourceTimeRange.duration);
                    LVMutableConfigAlignMode mode = [alignMode isEqualToString:@"align_video"]? LVMutableConfigAlignModeVideo: LVMutableConfigAlignModeCanvas;
                    
                    if (replaceMaterialAsset.processAsset) {
                        NSString *originPath = replaceMaterialAsset.currentImageFileURL.path ?: replaceMaterialAsset.processAsset.URL.path;
                        [self.dataManager nlemodel_replaceVideoAssetWithInfo:self.fragment
                                                                  originPath:originPath
                                                                        path:replaceMaterialAsset.processAsset.URL.path
                                                             sourceTimeRange:newTimeRange
                                                                   nleFolder:self.nleFolder
                                                                       toNLE:self.nleModel];
                        
                                                
                        [self.dataManager nlemodel_replaceCropsWithInfo:self.fragment
                                                                  Crops:[NSArray defaultCropWithSize:[replaceMaterialAsset.processAsset lv_videoSize]
                                                                                                                  originalSize:CGSizeMake(fragmentModel.videoWidth.doubleValue,
                                                                                                                                          fragmentModel.videoHeight.doubleValue)
                                                                                                                     alignMode:mode]
                                                                  toNLE:self.nleModel];
                        
                    } else {
                        [self.dataManager nlemodel_replaceImagePathWithInfo:self.fragment
                                                                  imagePath:replaceMaterialAsset.currentImageFileURL.path
                                                            processFilePath:replaceMaterialAsset.processedImageFileURL.path
                                                                  imageSize:replaceMaterialAsset.processedImageSize
                                                            sourceTimeRange:newTimeRange
                                                                  nleFolder:self.nleFolder
                                                                      toNLE:self.nleModel];
                        
                        [self.dataManager nlemodel_replaceCropsWithInfo:self.fragment
                                                                  Crops:[NSArray defaultCropWithSize:replaceMaterialAsset.processedImageSize
                                                                                                            originalSize:CGSizeMake(fragmentModel.videoWidth.doubleValue,
                                                                                                                                    fragmentModel.videoHeight.doubleValue)
                                                                                                               alignMode:mode]
                                                                  toNLE:self.nleModel];
                    }
                    ACCBLOCK_INVOKE(self.saveAction, replaceMaterialAsset, YES);
                });
            }
        };
        
        self.editView = [[ACCWorksCropEditView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)
                                                           fragment:self.bridgeFragment
                                                           canScale:[alignMode isEqualToString:@"align_video"]];
        self.editView.curIdx = self.curIdx;
        if (!self.fragment.isVideo) {
            NSString *path = [self.nleFolder stringByAppendingPathComponent:self.fragment.relativePath];
            self.editView.imageFileURL = [NSURL fileURLWithPath:path];
        } else {
            NSString *path = [self.nleFolder stringByAppendingPathComponent:fragment.relativePath];
            AVURLAsset *processAsset = [[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:path] options:nil];
            self.editView.videoAsset = processAsset;
        }
        self.editView.playTimeCallback = ^(CMTime time) {
            @strongify(self);
            [self.bottomView updatePlayTime:time];
        };
        self.editView.preferredSize = CGSizeMake(fragmentModel.videoWidth.doubleValue, fragmentModel.videoHeight.doubleValue);
        self.editView.changeMaterialCallback = self.internalChangeMaterialBlock;
        CMTime timeOffset = self.fragment.sourceTimeRange.start;
        [self.editView changeTimeOffest:timeOffset];
        
        [self createBottomView];
    }
    
    return self;
}


- (ACCFragmentBridgeFragment *)bridgeFragment{
    _bridgeFragment = [[ACCFragmentBridgeFragment alloc] init];
    _bridgeFragment.duration = self.fragment.sourceTimeRange.duration;
    _bridgeFragment.start = self.fragment.sourceTimeRange.start;
    _bridgeFragment.lowerLeftX = self.fragment.cropXLeft;
    _bridgeFragment.lowerRightX = self.fragment.cropXRight;
    _bridgeFragment.upperLeftX = self.fragment.cropXLeft;
    _bridgeFragment.upperRightX = self.fragment.cropXRight;
    _bridgeFragment.lowerLeftY = self.fragment.cropYLower;
    _bridgeFragment.lowerRightY = self.fragment.cropYLower;
    _bridgeFragment.upperLeftY = self.fragment.cropYUpper;
    _bridgeFragment.upperRightY = self.fragment.cropYUpper;
    return _bridgeFragment;
}

- (void)setPublishModel:(AWEVideoPublishViewModel *)publishModel
{
    _publishModel = publishModel;
    
    self.editView.publishModel = self.publishModel;
}

- (void)createBottomView
{
    @weakify(self);
    if (self.fragment.isVideo) {
        NSString *path = [self.nleFolder stringByAppendingPathComponent:self.fragment.relativePath];
        AVURLAsset *processAsset = [[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:path] options:nil];
        self.bottomView = [[ACCWorksPreviewVideoEditView alloc] initWithFrame:CGRectMake(0, 0, ACC_SCREEN_WIDTH, 100)
                                                                         type:ACCWorksPreviewVideoEditViewType_Video];
        self.bottomView.videoAsset = processAsset;
    } else {
        self.bottomView = [[ACCWorksPreviewVideoEditView alloc] initWithFrame:CGRectMake(0, 0, ACC_SCREEN_WIDTH, 100)
                                                                         type:ACCWorksPreviewVideoEditViewType_Photo];
        NSString *path = [self.nleFolder stringByAppendingPathComponent:self.fragment.relativePath];
        self.bottomView.imageFileURL = [NSURL URLWithString:path];
    }
    self.bottomView.timeRange = self.fragment.sourceTimeRange;
    self.bottomView.prepareWidth = ACC_SCREEN_WIDTH;
    self.bottomView.editManager = self;
    self.bottomView.pauseCallback = ^{
        @strongify(self);
        [self.editView pauseBySlide];
    };
    self.bottomView.resumeCallback = ^{
        @strongify(self);
        [self.editView playIfPauseBySlide];
        [self trackForChangeVideoAssetTimeRange:self.publishModel];
    };
    self.bottomView.changeRangeCallback = ^(CMTime newTimeRange) {
        ;
    };
    self.bottomView.changeMaterialCallback = self.internalChangeMaterialBlock;
    self.bottomView.closeCallback = ^{
        @strongify(self);
        if (self.didModifiedRange || self.editView.didModified) {
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil
                                                                                     message:ACCLocalizedString(@"creation_mv_alert_title_for_edit", @"是否放弃此次编辑？")
                                                                              preferredStyle:UIAlertControllerStyleAlert];
            [alertController addAction:[UIAlertAction actionWithTitle:ACCLocalizedString(@"creation_mv_alert_cancel", @"取消") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                
            }]];
            
            [alertController addAction:[UIAlertAction actionWithTitle:ACCLocalizedString(@"creation_mv_alert_discard", @"放弃") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                @strongify(self);

                [self trackForCancelSingleAssetEdit:self.publishModel];
                ACCBLOCK_INVOKE(self.closeAction);
            }]];
            [ACCAlert() showAlertController:alertController animated:YES];
        } else {
            [self trackForCancelSingleAssetEdit:self.publishModel];
            ACCBLOCK_INVOKE(self.closeAction);
        }
    };
    self.bottomView.okCallback = ^{
        @strongify(self);
        BOOL isEdited = NO;
        CMTimeRange newRange = [self.editView currentTimeRange];
        if (CMTimeCompare(newRange.start, self.fragment.sourceTimeRange.start) != 0) {
            [self.dataManager nlemodel_replaceSourceTimeRangeWithInfo:self.fragment
                                                      sourceTimeRange:newRange
                                                                toNLE:self.nleModel];
           
            isEdited = YES;
        }
        
        NSArray *crops = [self.editView currentCrops];
        if (crops) {
            [self.dataManager nlemodel_replaceCropsWithInfo:self.fragment
                                                      Crops:crops
                                                      toNLE:self.nleModel];
                
            isEdited = YES;
        }
        
        [self trackForClickSaveSingleAssetEdit:self.publishModel];
        ACCBLOCK_INVOKE(self.saveAction, nil, isEdited);
    };
    self.bottomView.scrollCallback = ^(CGFloat percent) {
        @strongify(self);
        if (percent < 0.0) {
            return ;
        }
        
        CMTimeRange range = [self.editView.videoAsset tracksWithMediaType:AVMediaTypeVideo].firstObject.timeRange;
        CMTimeValue offset = range.duration.value * percent;
        CMTime timeOffset = CMTimeMake(offset, range.duration.timescale);
        
        self.didModifiedRange = YES;
        [self.editView changeTimeOffest:timeOffset];
    };
    
    [self.bottomView reset];
    
}

- (NSDictionary *)p_smartMVTrackerInfo
{
    return @{
        @"enter_from" : @"smart_mv_material_edit",
        @"shoot_way" : self.publishModel.repoTrack.referString ?: @"",
        @"creation_id" : self.publishModel.repoContext.createId ?: @"",
        @"content_type" : @"smart_mv",
        @"content_source" : @"upload",
        @"mv_id" : self.publishModel.repoMV.templateModelId ?: @"",
        @"music_id" : self.publishModel.repoMusic.music.musicID ?: @"",
    };
}

#pragma mark - track

- (void)trackForChangeVideoAssetTimeRange:(AWEVideoPublishViewModel *)publishModel
{
    // 拖动调整时间选区时上报
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params addEntriesFromDictionary:[self commonParamsForPublishModel:publishModel]];
    
    [ACCTracker() trackEvent:@"edit_mv_time_window" params:[params copy]];
}

- (void)trackForClickSaveSingleAssetEdit:(AWEVideoPublishViewModel *)publishModel
{
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params addEntriesFromDictionary:[self commonParamsForPublishModel:publishModel]];
    
    [ACCTracker() trackEvent:@"save_mv_single_material" params:[params copy]];
}

- (void)trackForCancelSingleAssetEdit:(AWEVideoPublishViewModel *)publishModel
{
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params addEntriesFromDictionary:[self commonParamsForPublishModel:publishModel]];
    
    [ACCTracker() trackEvent:@"cancel_mv_single_material" params:[params copy]];
}

- (NSDictionary *)commonParamsForPublishModel:(AWEVideoPublishViewModel *)publishModel
{
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"enter_from"] = @"mv_edit_page";
    params[@"shoot_way"] = publishModel.repoTrack.referString ? : @"";
    params[@"content_source"] =  @"upload";
    params[@"content_type"] = [self contentTypeFromModel:publishModel];
    params[@"creation_id"] = publishModel.repoContext.createId ?: @"";
    params[@"mv_id"] = publishModel.repoMV.templateModelId ?: @"";
    
    [params addEntriesFromDictionary:[publishModel.repoCutSame smartVideoAdditonParamsForTrack]];
    
    return [params copy];
}

- (NSString *)contentTypeFromModel:(AWEVideoPublishViewModel *)publishModel
{
    if (publishModel.repoContext.videoType == AWEVideoTypeMV && publishModel.repoCutSame.accTemplateType == ACCMVTemplateTypeCutSame) {
        return @"jianying_mv";
    } else if (publishModel.repoContext.videoType == AWEVideoTypeMV && publishModel.repoCutSame.isClassicalMV) {
        return @"mv";
    }
    
    switch (publishModel.repoContext.videoType) {
        case AWEVideoTypeMoments:
            return @"moment";
            break;
        case AWEVideoTypeSmartMV:
            return @"smart_mv";
            break;
        case AWEVideoTypeOneClickFilming:
            return @"ai_upload";
            break;
            
        default:
            break;
    }
    
    return @"";
}

#pragma mark - AWEVideoRangeSliderDelegate
- (BOOL)videoRangeIgnoreGesture
{
    return YES;
}

- (void)videoRangeDidBeginByType:(AWEThumbType)type;
{
    [self.editView pauseBySlide];
}

- (void)videoRangeDidEndByType:(AWEThumbType)type
{
    [self.editView playIfPauseBySlide];
}

- (void)videoRangeDidChangByPosition:(CGFloat)position movedType:(AWEThumbType)type
{
    CMTime time = CMTimeMakeWithSeconds(position, NSEC_PER_SEC);
    [self.editView seekToTime:time];
}

@end
