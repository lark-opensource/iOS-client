//
//  HMDUITrackerManager+LarkPowerOptimize.m
//  LarkMonitor
//
//  Created by ByteDance on 2023/9/18.
//

#import <Stinger/Stinger.h>

void lark_disableUITrackerRecords(void)
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class cls = NSClassFromString(@"HMDUITrackerManager");
        SEL sel1 = NSSelectorFromString(@"hmdTrackableContext:eventWithName:parameters:");
        SEL sel2 = NSSelectorFromString(@"hmdTrackWithName:event:parameters:");
        if (![cls instancesRespondToSelector:sel1] || ![cls instancesRespondToSelector:sel2]) {
            return;
        }
        
        NSError *error=nil;
        [cls st_hookInstanceMethod:sel1 withOptions:STOptionInstead|STOptionWeakCheckSignature usingBlock:^(id<StingerParams> params){

        } error:&error];
        
        [cls st_hookInstanceMethod:sel2 withOptions:STOptionInstead|STOptionWeakCheckSignature usingBlock:^(id<StingerParams> params){
            
        } error:&error];
    });
}
