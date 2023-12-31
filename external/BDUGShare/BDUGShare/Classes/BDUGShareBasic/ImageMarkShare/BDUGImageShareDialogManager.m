//
//  BDUGTokenShareDialogManager.m
//  BDUGShare
//
//  Created by zengzhihui on 2018/5/31.
//

static NSString *const kBDUGImageMarkStringKey = @"kBDUGImageMarkStringKey";

#import "BDUGImageShareDialogManager.h"
#import <ByteDanceKit/ByteDanceKit.h>
#import "BDUGImageShareModel.h"
#import <Photos/Photos.h>
#import "BDUGImageMarkAdapter.h"
#import "BDUGImageShareModel.h"
#import "BDUGTokenShareModel.h"
#import <TTNetworkManager/TTNetworkManager.h>
#import <TTNetworkManager/TTDefaultHTTPRequestSerializer.h>
#import <TTNetworkManager/TTHTTPResponseSerializerBase.h>
#import "BDUGAlbumImageAnalysts.h"
#import "BDUGShareEvent.h"
#import "BDUGShareSequenceManager.h"

@interface BDUGImageShareDialogManager () <BDUGAlbumImageAnalystsDelegate>

@property (nonatomic, copy) BDUGImageShareDialogBlock imageShareDialogBlock;
@property (nonatomic, copy) BDUGImageShareDialogBlock imageShareAlbumAuthorizationDialogBlock;
@property (nonatomic, copy) BDUGImageShareAnalysisResultBlock imageAnalysisDialogBlock;

@property (nonatomic, strong) NSMutableArray <BDUGAdditionalImageShareDialogBlock> *additionalShareDialogs;
@property (nonatomic, strong) NSMutableArray <BDUGAdditionalImageShareDialogBlock> *additionalAuthorizationDialogs;
@property (nonatomic, strong) NSMutableArray <BDUGAdditionalImageShareAnalysisResultBlock> *additionalAnalysisDialogs;

@end

@implementation BDUGImageShareDialogManager

#pragma mark -

+ (instancetype)sharedManager {
    static BDUGImageShareDialogManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self class] new];
    });
    return sharedManager;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)init {
    if (self = [super init]) {
        
    }
    return self;
}

#pragma mark - public method

//注册口令解析 -- 注册立即会调用解析方法，同时注册App进入前台通知
+ (void)imageShareRegisterDialogBlock:(BDUGImageShareDialogBlock)dialogBlock {
    [BDUGImageShareDialogManager sharedManager].imageShareDialogBlock = dialogBlock;
}

+ (void)additionalImageShareRegisterDialogBlock:(BDUGAdditionalImageShareDialogBlock)dialogBlock {
    [[BDUGImageShareDialogManager sharedManager].additionalShareDialogs addObject:dialogBlock];
}

+ (void)additionalImageShareRegisterAlbumAuthorizationDialogBlock:(BDUGAdditionalImageShareDialogBlock)dialogBlock {
    [[BDUGImageShareDialogManager sharedManager].additionalAuthorizationDialogs addObject:dialogBlock];
}

+ (void)additionalImageAnalysisRegisterDialogBlock:(BDUGAdditionalImageShareAnalysisResultBlock)dialogBlock {
    [[BDUGImageShareDialogManager sharedManager].additionalAnalysisDialogs addObject:dialogBlock];
    [[BDUGImageShareDialogManager sharedManager] registerImageAnalysisWithPermissionAlert:NO notificationName:nil];
}

+ (void)imageAnalysisRegisterWithPermissionAlert:(BOOL)permissionAlert
                                     dialogBlock:(BDUGImageShareAnalysisResultBlock)dialogBlock {
    [self imageAnalysisRegisterWithPermissionAlert:permissionAlert notificationName:nil dialogBlock:dialogBlock];
}

+ (void)imageAnalysisRegisterWithPermissionAlert:(BOOL)permissionAlert
                                notificationName:(NSString *)notificationName
                                     dialogBlock:(BDUGImageShareAnalysisResultBlock)dialogBlock
{
    //todo： 限制调用次数或内部限制。
    [BDUGImageShareDialogManager sharedManager].imageAnalysisDialogBlock = dialogBlock;
    [[BDUGImageShareDialogManager sharedManager] registerImageAnalysisWithPermissionAlert:permissionAlert
                                                                         notificationName:notificationName];
}

+ (void)imageShareRegisterAlbumAuthorizationDialogBlock:(BDUGImageShareDialogBlock)dialogBlock
{
    [BDUGImageShareDialogManager sharedManager].imageShareAlbumAuthorizationDialogBlock = dialogBlock;
}

+ (void)invokeImageShareDialogBlock:(BDUGImageShareContentModel *)contentModel {
    [[BDUGImageShareDialogManager sharedManager] invokeImageShareDialogBlock:contentModel];
}

+ (void)invokeAlbumAuthorizationDialogBlock:(BDUGImageShareContentModel *)contentModel
{
    [[BDUGImageShareDialogManager sharedManager] invokeAlbumAuthorizationDialogBlock:contentModel];
}

+ (void)invokeImageShareAnalysisResultDialogBlock:(BDUGImageShareAnalysisResultModel *)resultModel {
    [[BDUGImageShareDialogManager sharedManager] invokeImageShareAnalysisResultDialogBlock:resultModel];
}

+ (void)shareImage:(BDUGImageShareContentModel *)contentModel {
    [BDUGShareEventManager event:kSharePopupClick params:@{
        @"channel_type" : (contentModel.originShareInfo.channelStringForEvent ?: @""),
        @"share_type" : @"image",
        @"popup_type" : @"go_share",
        @"click_result" : @"submit",
        @"panel_type" : (contentModel.originShareInfo.panelType ?: @""),
        @"panel_id" : (contentModel.originShareInfo.panelID ?: @""),
        @"resource_id" : (contentModel.originShareInfo.groupID ?: @""),
    }];
    PHAuthorizationStatus authStatus = [PHPhotoLibrary authorizationStatus];
    [BDUGShareEventManager event:kShareAuthorizeRequest params:@{
        @"had_authorize" : (authStatus == PHAuthorizationStatusAuthorized ? @(1) : @(0)),
        @"panel_type" : (contentModel.originShareInfo.panelType ?: @""),
        @"panel_id" : (contentModel.originShareInfo.panelID ?: @""),
        @"resource_id" : (contentModel.originShareInfo.groupID ?: @""),
    }];
    if (authStatus == PHAuthorizationStatusNotDetermined) {
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSString *showSuccess = @"cancel";
                if (status == PHAuthorizationStatusAuthorized) {
                    // 已授权
                    [self shareImageWithPermission:YES contentModel:contentModel];
                    showSuccess = @"submit";
                } else {
                    // 无权限
                    [self shareImageWithPermission:NO contentModel:contentModel];
                }
                [BDUGShareEventManager event:kShareAuthorizeClick params:@{
                    @"channel_type" : (contentModel.originShareInfo.channelStringForEvent ?: @""),
                    @"is_first_request" : @"yes",
                    @"click_result" : showSuccess,
                    @"share_type" : @"image",
                    @"panel_type" : (contentModel.originShareInfo.panelType ?: @""),
                    @"panel_id" : (contentModel.originShareInfo.panelID ?: @""),
                    @"resource_id" : (contentModel.originShareInfo.groupID ?: @""),
                }];
            });
        }];
        [BDUGShareEventManager event:kShareAuthorizeShow params:@{
            @"is_first_request" : @"yes",
            @"channel_type" : (contentModel.originShareInfo.channelStringForEvent ?: @""),
            @"share_type" : @"image",
            @"panel_type" : (contentModel.originShareInfo.panelType ?: @""),
            @"panel_id" : (contentModel.originShareInfo.panelID ?: @""),
            @"resource_id" : (contentModel.originShareInfo.groupID ?: @""),
        }];
    } else if (authStatus == PHAuthorizationStatusAuthorized) {
        // 已授权
        [self shareImageWithPermission:YES contentModel:contentModel];
    } else {
        [self shareImageWithPermission:NO contentModel:contentModel];
        [BDUGShareEventManager event:kShareAuthorizeShow params:@{
            @"is_first_request" : @"no",
            @"channel_type" : (contentModel.originShareInfo.channelStringForEvent ?: @""),
            @"share_type" : @"image",
            @"panel_type" : (contentModel.originShareInfo.panelType ?: @""),
            @"panel_id" : (contentModel.originShareInfo.panelID ?: @""),
            @"resource_id" : (contentModel.originShareInfo.groupID ?: @""),
        }];
    }
}

+ (void)shareImageWithPermission:(BOOL)permission contentModel:(BDUGImageShareContentModel *)contentModel {
    if (!permission) {
        [self invokeAlbumAuthorizationDialogBlock:contentModel];
        if (contentModel.originShareInfo.completeBlock) {
            contentModel.originShareInfo.completeBlock(BDUGImageShareStatusCodeSaveImageToAlbumPermissionDenied, nil);
        }
        return;
    }
    __block NSString *identifier;
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        //写入图片到相册
        PHAssetChangeRequest *req = [PHAssetChangeRequest creationRequestForAssetFromImage:contentModel.image];
        identifier = req.placeholderForCreatedAsset.localIdentifier;
    } completionHandler:^(BOOL success, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *errorTip;
            BDUGImageShareStatusCode status;
            if (error) {
                errorTip = [NSString stringWithFormat:@"图片保存失败 %@", error.description];
                status = BDUGImageShareStatusCodeGetImageFailed;
            } else {
                [[BDUGAlbumImageAnalysts sharedManager] markAlbumImageIdentifier:identifier valid:NO];
                status = BDUGImageShareStatusCodeSuccess;
                errorTip = nil;
                if (contentModel.originShareInfo.openThirdPlatformBlock) {
                    BOOL openPlatformSuccess = contentModel.originShareInfo.openThirdPlatformBlock();
                    if (!openPlatformSuccess) {
                        status = BDUGImageShareStatusCodePlatformOpenFailed;
                        errorTip = @"打开三方应用失败";
                    }
                }
            }
            if (contentModel.originShareInfo.completeBlock) {
                contentModel.originShareInfo.completeBlock(status, errorTip);
            }
        });
    }];
}

+ (void)cancelImageShare:(BDUGImageShareContentModel *)contentModel {
    [BDUGShareEventManager event:kSharePopupClick params:@{
        @"channel_type" : (contentModel.originShareInfo.channelStringForEvent ?: @""),
        @"share_type" : @"image",
        @"popup_type" : @"go_share",
        @"click_result" : @"cancel",
        @"panel_type" : (contentModel.originShareInfo.panelType ?: @""),
        @"panel_id" : (contentModel.originShareInfo.panelID ?: @""),
        @"resource_id" : (contentModel.originShareInfo.groupID ?: @""),
    }];
    if (contentModel.originShareInfo.completeBlock) {
        contentModel.originShareInfo.completeBlock(BDUGImageShareStatusCodeUserCancel, nil);
    }
}

+ (void)triggerAlbumAuthorization
{
    [[UIApplication sharedApplication]openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
}

#pragma mark - analysis method

- (void)registerImageAnalysisWithPermissionAlert:(BOOL)permission {
    [self registerImageAnalysisWithPermissionAlert:permission notificationName:nil];
}

- (void)registerImageAnalysisWithPermissionAlert:(BOOL)permission
                                notificationName:(NSString *)notificationName
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [[BDUGAlbumImageAnalysts sharedManager] activateAlbumImageAnalystsWithPermissionAlert:permission notificationName:notificationName];
        [BDUGAlbumImageAnalysts sharedManager].imageHiddenMarkDelegate = self;
    });
}

- (void)analysisShareInfo:(UIImage *)image hasReadMark:(BOOL *)hasReadMark completion:(BDUGShareAnalysisContinueBlock)completion
{
    __weak typeof(self) weakSelf = self;
    [BDUGImageMarkAdapter asyncReadImageMark:image completion:^(NSInteger errCode, NSString *errTip, NSString *resultString) {
        if (*hasReadMark == YES) {
            return ;
        }
        BOOL succeed = (errCode == 0 && resultString.length > 0);
        if (succeed) {
            [BDUGImageMarkAdapter cancelLaterTasks];
            [weakSelf processImageMark:resultString];
            !completion ?: completion(YES);
            [BDUGShareEventManager trackService:kShareMonitorHiddenmarkRead attributes:@{@"status" : @(0)}];
            [BDUGShareEventManager event:kShareHiddenInterfaceRead params:nil];
        } else {
            //该图片中没有信息。
            !completion ?: completion(NO);
        }
    }];
}

- (void)processImageMark:(NSString *)imageMark
{
    if (imageMark.length == 0) {
        return;
    }
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:2];
    [params setValue:imageMark forKey:@"token"];
    NSString *requestURLString = [[BDUGShareSequenceManager sharedInstance].configuration.hostString stringByAppendingString:[self tokenAnalysisPath]];
    [[TTNetworkManager shareInstance] requestForJSONWithURL:requestURLString params:params method:@"GET" needCommonParams:YES  requestSerializer:[TTDefaultHTTPRequestSerializer class] responseSerializer:[TTHTTPJSONResponseSerializerBase class] autoResume:YES callback:^(NSError *error, id jsonObj) {
        NSString *isSucceed = @"failed";
        NSString *groupType = @"hidden_mark";
        NSString *failedReason = @"";
        if (error == nil && [jsonObj isKindOfClass:[NSDictionary class]]) {
            isSucceed = @"success";
            NSInteger status = [(NSDictionary *)jsonObj btd_intValueForKey:@"status"];
            if ([(NSDictionary *)jsonObj objectForKey:@"status"] != nil && status == 0) {
                NSDictionary *data = [(NSDictionary *)jsonObj btd_dictionaryValueForKey:@"data"];
                BDUGTokenShareAnalysisResultModel *tokenModel = [[BDUGTokenShareAnalysisResultModel alloc] initWithDict:data];
                tokenModel.groupTypeForEvent = groupType;
                BDUGImageShareAnalysisResultModel *model = [BDUGImageShareAnalysisResultModel resultModelWithResultInfo:imageMark];
                model.tokenInfo = tokenModel;
                [self invokeImageShareAnalysisResultDialogBlock:model];
            } else if (status == 2) {
                BDUGLoggerInfo(@"口令失效");
                [self invokeImageShareAnalysisResultDialogBlock:nil];
                failedReason = @"expired";
            } else if (status == 1001) {
                BDUGLoggerError(@"口令与应用不匹配");
                [self invokeImageShareAnalysisResultDialogBlock:nil];
                //口令与应用不匹配，清空剪切板
                failedReason = @"other_app";
            } else {
                BDUGLoggerInfo(@"不处理口令");
                failedReason = @"failed";
            }
        } else {
            BDUGLoggerError(([NSString stringWithFormat:@"口令分享接口错误, error : %@", error.description]));
            failedReason = @"failed";
        }
        [BDUGShareEventManager event:kShareEventRecognizeInterfaceRequest params:@{
                                                                         @"recognize_type" : groupType,
                                                                         @"is_success" : isSucceed,
                                                                         @"failed_reason" : failedReason,
                                                                         }];
        [BDUGShareEventManager trackService:kShareMonitorTokenInfo attributes:@{@"status" : (isSucceed ? @(0) : @(1))}];
    }];
}

- (NSString *)tokenAnalysisPath {
    return @"ug_token/info/v1/";
}

#pragma mark - private method

- (void)invokeImageShareDialogBlock:(BDUGImageShareContentModel *)contentModel {
    if (_additionalShareDialogs.count > 0) {
        //避免出现懒加载。
        __block BOOL hitAdditionalRegister = NO;
        [_additionalShareDialogs enumerateObjectsUsingBlock:^(BDUGAdditionalImageShareDialogBlock  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
           if (obj && obj(contentModel)) {
               hitAdditionalRegister = YES;
               *stop = YES;
           }
        }];
        if (hitAdditionalRegister) {
            //命中拓展注册，不调用通用回调。
            return;
        }
    }
    if (_imageShareDialogBlock) {
        _imageShareDialogBlock(contentModel);
        [BDUGShareEventManager event:kSharePopupShow params:@{
            @"channel_type" : (contentModel.originShareInfo.channelStringForEvent ?: @""),
            @"popup_type" : @"go_share",
            @"share_type" : @"image",
            @"panel_type" : (contentModel.originShareInfo.panelType ?: @""),
            @"panel_id" : (contentModel.originShareInfo.panelID ?: @""),
            @"resource_id" : (contentModel.originShareInfo.groupID ?: @""),
        }];
    } else {
        NSAssert(0, @"图片隐写分享功能缺失。详见文档。\
                 自定义分享UI：实现imageShareRegisterDialogBlock。\
                 使用默认UI：\
                    1、引入subspec: BDUGShareUI/Token/ImageToken\
                    2、调用BDUGImageShareDialogService相关方法。");
    }
}

- (void)invokeImageShareAnalysisResultDialogBlock:(BDUGImageShareAnalysisResultModel *)resultModel {
    if ([BDUGAlbumImageAnalysts sharedManager].imageShouldAnalysisBlock && ![BDUGAlbumImageAnalysts sharedManager].imageShouldAnalysisBlock()) {
           //实现了should回调并且返回了no，则不弹窗
           return ;
       }
    if (_additionalAnalysisDialogs.count > 0) {
        //避免出现懒加载。
        __block BOOL hitAdditionalRegister = NO;
        [_additionalAnalysisDialogs enumerateObjectsUsingBlock:^(BDUGAdditionalImageShareAnalysisResultBlock  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
           if (obj && obj(resultModel)) {
               hitAdditionalRegister = YES;
               *stop = YES;
           }
        }];
        if (hitAdditionalRegister) {
            //命中拓展注册，不调用通用注册。
            return;
        }
    }
    if (_imageAnalysisDialogBlock) {
        _imageAnalysisDialogBlock(resultModel);
    }
}

- (void)invokeAlbumAuthorizationDialogBlock:(BDUGImageShareContentModel *)contentModel
{
    if (_additionalAuthorizationDialogs.count > 0) {
        //避免出现懒加载。
        __block BOOL hitAdditionalRegister = NO;
        [_additionalAuthorizationDialogs enumerateObjectsUsingBlock:^(BDUGAdditionalImageShareDialogBlock  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
           if (obj && obj(contentModel)) {
               hitAdditionalRegister = YES;
               *stop = YES;
           }
        }];
        if (hitAdditionalRegister) {
            //命中拓展注册，不调用通用回调。
            return;
        }
    }
    if (_imageShareAlbumAuthorizationDialogBlock) {
        _imageShareAlbumAuthorizationDialogBlock(contentModel);
    }
}

#pragma mark - get

- (NSMutableArray<BDUGAdditionalImageShareDialogBlock> *)additionalShareDialogs {
    if (!_additionalShareDialogs) {
        _additionalShareDialogs = [[NSMutableArray alloc] init];
    }
    return _additionalShareDialogs;
}

- (NSMutableArray<BDUGAdditionalImageShareDialogBlock> *)additionalAuthorizationDialogs {
    if (!_additionalAuthorizationDialogs) {
        _additionalAuthorizationDialogs = [[NSMutableArray alloc] init];
    }
    return _additionalAuthorizationDialogs;
}

- (NSMutableArray<BDUGAdditionalImageShareAnalysisResultBlock> *)additionalAnalysisDialogs {
    if (!_additionalAnalysisDialogs) {
        _additionalAnalysisDialogs = [[NSMutableArray alloc] init];
    }
    return _additionalAnalysisDialogs;
}

@end
