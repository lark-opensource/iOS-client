//
//  BDUGImageQRCodeAnalysisManager.m
//  BDUGShare_Example
//
//  Created by 杨阳 on 2019/6/19.
//  Copyright © 2019 xunianqiang. All rights reserved.
//


#import "BDUGImageQRCodeAnalysisManager.h"
#import <TTScanQrCode/TTScanCodeParser.h>
#import "BDUGAlbumImageAnalysts.h"
#import "BDUGShareEvent.h"

@implementation BDUGImageAnalysisResultModel

@end

@interface BDUGImageQRCodeAnalysisManager () <BDUGAlbumImageAnalystsDelegate>

@property (nonatomic, strong) TTScanCodeParser *imageParser;

@property (nonatomic, copy) BDUGImageAnalysisResultBlock analysisResultBlock;

@end

@implementation BDUGImageQRCodeAnalysisManager

+ (instancetype)sharedManager {
    static BDUGImageQRCodeAnalysisManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self class] new];
    });
    return sharedManager;
}

+ (void)imageAnalysisRegisterWithPermissionAlert:(BOOL)permissionAlert
                                     dialogBlock:(BDUGImageAnalysisResultBlock)dialogBlock
{
    [self imageAnalysisRegisterWithPermissionAlert:permissionAlert notificationName:nil dialogBlock:dialogBlock];
}

+ (void)imageAnalysisRegisterWithPermissionAlert:(BOOL)permissionAlert
                                notificationName:(NSString *)notificationName
                                     dialogBlock:(BDUGImageAnalysisResultBlock)dialogBlock
{
    [BDUGImageQRCodeAnalysisManager sharedManager].analysisResultBlock = dialogBlock;
    [[BDUGAlbumImageAnalysts sharedManager] activateAlbumImageAnalystsWithPermissionAlert:permissionAlert notificationName:notificationName];
    [BDUGAlbumImageAnalysts sharedManager].imageQRCodeDelegate = [BDUGImageQRCodeAnalysisManager sharedManager];
}

#pragma mark - BDUGAlbumImageAnalystsDelegate

- (void)analysisShareInfo:(UIImage *)image hasReadMark:(BOOL *)hasReadMark completion:(BDUGShareAnalysisContinueBlock)completion
{
    if (*hasReadMark == YES) {
        return ;
    }
    if (!_imageParser) {
        _imageParser = [[TTScanCodeParser alloc] init];
    }
    TTScanCodeParserResult *result = [self.imageParser parseWithImage:image];
    
    BOOL parseResult = result && result.parsedText.length > 0;
    //通知BDUGAlbumImageAnalysts，解析结果。
    !completion ?: completion(parseResult);
    if (parseResult) {
        BDUGImageAnalysisResultModel *model = [[BDUGImageAnalysisResultModel alloc] init];
        model.resultString = result.parsedText;
        //通知业务方解析结果。
        !self.analysisResultBlock ?: self.analysisResultBlock(model);
        [BDUGShareEventManager trackService:kShareMonitorQRCodeRead metric:nil category:@{@"status" : @(0)} extra:nil];
        [BDUGShareEventManager event:kShareQRCodeInterfaceRead params:nil];
    }
}

@end
