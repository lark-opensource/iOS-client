//
//  AWEInfoStickerManager.m
//  AWEStudio
//
//  Created by guochenxiang on 2018/10/12.
//  Copyright © 2018 bytedance. All rights reserved.
//

#import "AWEInfoStickerManager.h"
#import <CreationKitInfra/ACCAlertProtocol.h>
#import <CreationKitArch/ACCStickerNetServiceProtocol.h>

#import "ACCLocationProtocol.h"
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CameraClient/ACCInfoStickerNetServiceProtocol.h>
#import <CreationKitInfra/ACCLoadingViewProtocol.h>
NSString * const kErrorTemperature = @"-99";

@interface AWEInfoStickerManager ()

@end

@implementation AWEInfoStickerManager

- (NSString *)fetchCurrentTime
{
    NSTimeInterval interval = [[NSDate date] timeIntervalSince1970];
    return [NSString stringWithFormat:@"%lld", (long long int)interval];
}

- (void)fetchTemperatureCompletion:(void (^)(NSError *, NSString *))complection
{
    NSString *cityCode = [ACCLocation() currentSelectedCityCode];
    [IESAutoInline(ACCBaseServiceProvider(), ACCInfoStickerNetServiceProtocol) requestTemperatureInfoStickersWithCityCode:cityCode completion:^(AWEInfoStickerResponse * _Nullable model, NSError * _Nullable error) {
            if (error || model.temperature == nil|| [model.statusCode isEqualToNumber:@(2850)]) {
               NSError *err = [NSError errorWithDomain:@"request temperature failed" code:0 userInfo:nil];
               complection(err, kErrorTemperature);
            } else {
               complection(nil, [NSString stringWithFormat:@"%d", [model.temperature intValue]]);
            }
    }];
}

- (void)fetchPOIPermissionCompletion:(void (^)(NSError *))complection
{
    if ([ACCLocation() hasPermission]) {
        [self p_fetchLocationCompletion:complection];
    } else {
        [ACCLocation() requestPermissionWithCertName:@"bpea-studio_poi_sticker_request_permission" completion:^(ACCLocationPermission permission, NSError * _Nullable error) {
            switch (permission) {
                case ACCLocationPermissionAllowed: {
                    [self p_fetchLocationCompletion:complection];
                }
                    break;
                case ACCLocationPermissionAlreadyDenied: {
                    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:ACCLocalizedCurrentString(@"tip") message:ACCLocalizedString( @"av_tips_forbid_local", @"位置权限被禁用，请到设置中授予抖音允许访问位置权限") preferredStyle:UIAlertControllerStyleAlert];
                    [alertController addAction:[UIAlertAction actionWithTitle: ACCLocalizedString(@"go_to_settings",@"go_to_settings") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
                            NSError *error = [NSError errorWithDomain:@"Permission denied" code:1011 userInfo:nil];
                            complection(error);
                        });
                    }]];
                    
                    [alertController addAction:[UIAlertAction actionWithTitle:ACCLocalizedCurrentString(@"cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                        NSError *error = [NSError errorWithDomain:@"Permission denied" code:1010 userInfo:nil];
                        complection(error);
                    }]];
                    [ACCAlert() showAlertController:alertController animated:YES];
                }
                    break;
                case ACCLocationPermissionDenied:{
                    NSError *error = [NSError errorWithDomain:@"Permission denied" code:1010 userInfo:nil];
                    complection(error);
                }
                    break;
            }
        }];
    }
}

- (void)p_fetchLocationCompletion:(void (^)(NSError *))complection
{
    UIView<ACCTextLoadingViewProtcol> *loadingView = [ACCLoading() showWindowLoadingWithTitle:@"加载中..." animated:YES];
    __block BOOL isCanceled = NO;
    @weakify(loadingView);
    [loadingView showCloseBtn:YES closeBlock:^{
        @strongify(loadingView);
        [loadingView dismissWithAnimated:YES];
        isCanceled = YES;
        NSError *error = [NSError errorWithDomain:@"cancel request location info" code:1011 userInfo:nil];
        ACCBLOCK_INVOKE(complection,  error);
    }];
    [ACCLocation() requestCurrentLocationWithCertName:@"bpea-studio_poi_sticker_location_info" completion:^(id<ACCLocationModel>  _Nullable locationModel, ACCLocationPermission permission, NSError * _Nullable error) {
        if (isCanceled) {
            return;
        }
        @strongify(loadingView);
        CLLocation *location = locationModel.location;
        if ([@(location.coordinate.longitude) stringValue]  && [@(location.coordinate.latitude) stringValue]) {
            complection(nil);
        } else {
            NSError *error = [NSError errorWithDomain:@"request location failed" code:1010 userInfo:nil];
            complection(error);
        }
        [loadingView dismissWithAnimated:YES];
    }];
}

@end
