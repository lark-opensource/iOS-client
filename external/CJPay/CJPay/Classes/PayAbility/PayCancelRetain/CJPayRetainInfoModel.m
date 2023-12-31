//
//  CJPayRetainInfoModel.m
//  Pods
//
//  Created by chenbocheng on 2021/8/11.
//

#import "CJPayRetainInfoModel.h"
#import "CJPaySDKMacro.h"
#import "CJPayTrackerProtocol.h"
#import "CJPayRetainMsgModel.h"

@implementation CJPayRetainInfoModel

- (BOOL)hasDiscount {
    return Check_ValidString(self.voucherContent) || Check_ValidArray(self.retainMsgModels);
}

- (void)trackRetainPopUpWithEvent:(NSString *)event trackDelegate:(id<CJPayTrackerProtocol>)trackDelegate extraParam:(NSDictionary *)extraParam {
    if (![trackDelegate conformsToProtocol:@protocol(CJPayTrackerProtocol)]) {
        return;
    }
    
    NSMutableDictionary *param = [NSMutableDictionary new];
    [param cj_setObject:[self hasDiscount] ? @"1" : @"0" forKey:@"is_discount"];
    
    NSString *activityLabel = self.outPutActivityLabelForTrack;
    if (!(Check_ValidString(activityLabel))) {
        NSArray *arr = [self.voucherContent componentsSeparatedByString:@"$"];
        activityLabel = [arr cj_objectAtIndex:1] ?: @"";
    }
    [param cj_setObject:activityLabel forKey:@"activity_label"];
    
    if (extraParam) {
        [param addEntriesFromDictionary:extraParam];
    }
    
    
    NSArray<NSNumber *> *vourcherTypes = @[@(CJPayRetainVoucherTypeV2), @(CJPayRetainVoucherTypeV3)];
    if (![vourcherTypes containsObject:@(self.voucherType)] || !Check_ValidArray(self.retainMsgModels)) {
        [trackDelegate event:event params:param];
        return;
    }
    
    __block NSString *nowString = @"";
    __block NSString *nextString = @"";
    
    [self.retainMsgModels enumerateObjectsUsingBlock:^(CJPayRetainMsgModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (![obj isKindOfClass:CJPayRetainMsgModel.class]) {
            return;
        }
        
        if (obj.voucherType == 1) {
            nowString = [NSString stringWithFormat:@"%@_%@", CJString(obj.leftMsg), CJString(obj.rightMsg)];
        } else if (obj.voucherType == 2) {
            nextString = [NSString stringWithFormat:@"%@_%@", CJString(obj.leftMsg), CJString(obj.rightMsg)];
        }
    }];
    
    [param cj_setObject:nowString forKey:@"now"];
    [param cj_setObject:nextString forKey:@"next"];
    [param cj_setObject:@(self.retainMsgModels.count) forKey:@"num"];
    [param cj_setObject:[self getVourcherTypeStr] forKey:@"voucher_style"];
    [param cj_setObject:CJString(self.title) forKey:@"title"];
    
    [trackDelegate event:event params:param];
}

- (NSString *)getVourcherTypeStr {
    switch (self.voucherType) {
        case CJPayRetainVoucherTypeV1:
            return @"1.0";
        case CJPayRetainVoucherTypeV2:
            return @"2.0";
        case CJPayRetainVoucherTypeV3:
            return @"3.0";
        default:
            return @"1.0";
    }
}

@end
