//
//  CJPayLocalCardOCRWithPitayaImpl.m
//  cjpay_ocr_optimize
//
//  Created by ByteDance on 2023/5/8.
//

#import "CJPayLocalCardOCRWithPitayaImpl.h"
#import <ByteDanceKit/UIImage+BTDAdditions.h>
#import <Pitaya/PTYMobileCVMat.h>
#import "CJPayLocalCardOCRWithPitaya.h"
#import "CJPayRequestParam.h"
#import "CJPayPitayaEngine.h"
#import "CJPayProtocolManager.h"
#import "CJPaySDKMacro.h"

static NSString *const CJPayPitayaAppID = @"1792";
static NSString *const CJPayPitayaBusiness = @"card_detect";

@interface CJPayLocalCardOCRWithPitayaImpl()<CJPayLocalCardOCRWithPitaya>

@end

@implementation CJPayLocalCardOCRWithPitayaImpl

CJPAY_REGISTER_PLUGIN({
    CJPayRegisterCurrentClassToPtocol(self, CJPayLocalCardOCRWithPitaya);
});

#pragma mark CJPayLocalCardOCRPlugin
- (void)initEngine {
    if (![CJPayPitayaEngine.sharedPitayaEngine hasInitPitaya]) {
        NSDictionary *info = @{@"channel": [UIApplication btd_currentChannel],
                               @"device_id": CJString([CJPayRequestParam gAppInfoConfig].deviceIDBlock()),
                               @"user_id": CJString([CJPayRequestParam gAppInfoConfig].userIDBlock())
        };
        [CJPayPitayaEngine.sharedPitayaEngine initPitayaEngine:info appId:CJPayPitayaAppID appVersion:[CJSDKParamConfig defaultConfig].settingsVersion];
    }
}

- (void)scanWithImage:(UIImage *)image callback:(void (^)(BOOL success, int code, NSString *errorMsg, NSObject *output, UIImage *outImage))callback {
    PTYMobileCVMat *cvMat = [[PTYMobileCVMat alloc] initWithImage:image];
    NSDictionary *params = @{@"image": cvMat};
    [CJPayPitayaEngine.sharedPitayaEngine runPacket:CJPayPitayaBusiness params:params runCallback:^(BOOL success, NSError * _Nullable error, PTYTaskData * _Nullable output, PTYPackage * _Nullable package) {
        if (!success || !output.params) {
            CJPayLogError(@"Pitaya detecting bankcard result: %d, error: %@", success ? 1 : 0, error);
            callback(NO, -1, @"Pitaya run failed", nil, nil);
            return;
        }
        
        NSNumber *codeNumber = [output.params btd_numberValueForKey:@"code"];
        int codeInt = codeNumber.intValue;
        
        // 银行卡检测，至少有4个端点
        NSArray *points = [output.params btd_arrayValueForKey:@"coordinates"];
        NSString *error_msg = [output.params btd_stringValueForKey:@"msg"];
        if (!points || points.count < 4) {
            CJPayLogError(@"Pitaya detected bankcard's points is empty or < 4");
            callback(YES, codeInt, error_msg, output.params, nil);
            return;
        }
        
        // 每个点至少有x、y两个数据，如果不满足则过滤掉
        NSArray *safeArray = [points filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id  _Nullable evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
            NSArray<NSNumber *> *points = evaluatedObject;
            return points.count > 1;
        }]];
        if (safeArray.count != points.count) {
            CJPayLogError(@"Pitaya detected bankcard's points is not valid");
            callback(YES, codeInt, error_msg, output.params, nil);
            return;
        }
        
        // 跟AILab同学讨论，端上检测图片中是否有银行卡，不做裁剪，把原图发给云端识别。
//        CGPoint topLeft = CGPointMake([(NSNumber *)points[0][0] intValue], [(NSNumber *)points[0][1] intValue]);
//        CGPoint topRight = CGPointMake([(NSNumber *)points[1][0] intValue], [(NSNumber *)points[1][1] intValue]);
//        CGPoint bottomRight = CGPointMake([(NSNumber *)points[2][0] intValue], [(NSNumber *)points[2][1] intValue]);
//        CGPoint bottomLeft = CGPointMake([(NSNumber *)points[3][0] intValue], [(NSNumber *)points[3][1] intValue]);
//        CGRect cropRect = CGRectMake(topLeft.x, topLeft.y, topRight.x - topLeft.x, bottomLeft.y - topLeft.y);
//
//        UIImage * outImage = [UIImage btd_cutImage:image withRect:cropRect];
        callback(YES, codeInt, @"Pitaya run succeed", output.params, image);
    } async:NO];
}

@end
