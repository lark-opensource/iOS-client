
#import "TTClearCacheRule.h"
#import "TTDownloadClearCache.h"
#import "TTDownloadManager.h"

NS_ASSUME_NONNULL_BEGIN

static NSString *const kClearCacheId = @"clear_id";
static NSString *const kClearType = @"clear_type";
static NSString *const kClearKeyList = @"key_list";


static NSMutableDictionary<NSString *, TTClearCacheRule *> *clearCacheRuleDic;

@implementation TTDownloadClearCache

+ (void)updateClearCacheRule:(NSArray *)clearRuleArray {
    if (!clearRuleArray) {
        return;
    }

    @synchronized ([TTDownloadClearCache class]) {
        //Get all clear rules from DB.
        if (![TTDownloadClearCache getAllRuleFromDB]) {
            return;
        }
        //1.Add new rule to DB;
        //2.Mark newest TNC rule to delete the invalid later.
        NSError *error = nil;
        [TTDownloadClearCache checkAndInsertNewRules:clearRuleArray error:&error];
        DLLOGD(@"error=%@", error);
        //Run clear work if status is not CLEAR_DONE.
        [TTDownloadClearCache tryClearCacheByTncConfig];
        //Delete invalid rule,which had run and TNC config not found.
        error = nil;
        [TTDownloadClearCache tryDeleteInvalidClearCacheRules:&error];
        DLLOGD(@"error=%@", error);
        //All work done,clear clearCacheRuleDic
        clearCacheRuleDic = nil;
    }
}

+ (void)checkAndInsertNewRules:(NSArray<NSDictionary *> *)clearRuleArray error:(NSError **)error {
    if (clearCacheRuleDic && clearRuleArray.count > 0) {
        for (NSDictionary *obj in clearRuleArray) {
            NSString *clearId = [[obj objectForKey:kClearCacheId] stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
            
            TTClearCacheRule *oldRule;
            if ((oldRule = [clearCacheRuleDic objectForKey:clearId])) {
                //If rule exist,do nothing.Because same rule only run once.
                oldRule.isTncSet = YES;
                continue;
            } else {
                //add new rule
                TTClearCacheRule *newRule = [[TTClearCacheRule alloc] init];
                newRule.clearId = [[obj objectForKey:kClearCacheId] stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
                newRule.clearRuleStatus = CLEAR_INIT;
                newRule.type = [[obj objectForKey:kClearType] intValue];
                newRule.isTncSet = YES;
                newRule.keyList = [[obj objectForKey:kClearKeyList] componentsSeparatedByString:@","];
                [clearCacheRuleDic setObject:newRule forKey:newRule.clearId];
                [[TTDownloadManager shareInstance] insertOrUpdateClearCacheRule:newRule error:error];
                DLLOGD(@"error=%@", *error);
            }
        }
    }
}

+ (void)tryDeleteInvalidClearCacheRules:(NSError **)error {
    if (!clearCacheRuleDic || clearCacheRuleDic.count <= 0) {
        return;
    }
    
    for (NSString *key in clearCacheRuleDic) {
        TTClearCacheRule *obj = [clearCacheRuleDic objectForKey:key];
        if (obj && !obj.isTncSet && obj.clearRuleStatus == CLEAR_DONE) {
            //Here we will clear invalid rule from DB.
            [[TTDownloadManager shareInstance] deleteClearCacheRule:obj error:error];
            DLLOGD(@"error=%@", *error);
        }
    }
}

+ (void)tryClearCacheByTncConfig {
    if (!clearCacheRuleDic || clearCacheRuleDic.count <= 0) {
        return;
    }
    
    for (NSString *key in clearCacheRuleDic) {
        TTClearCacheRule *obj = [clearCacheRuleDic objectForKey:key];
        if (obj && obj.clearRuleStatus != CLEAR_DONE) {
            NSError *error = nil;
            [[TTDownloadManager shareInstance] clearAllCache:obj.type clearCacheKey:obj.keyList error:&error];
            DLLOGD(@"error=%@", error);
            //After clear cache,we must set rule status to CLEAR_DONE.Then we don't
            //clear cache again.
            obj.clearRuleStatus = CLEAR_DONE;
            error = nil;
            [[TTDownloadManager shareInstance] insertOrUpdateClearCacheRule:obj error:&error];
            DLLOGD(@"error=%@", error);
        }
    }
}

+ (BOOL)getAllRuleFromDB {
    NSError *error = nil;
    clearCacheRuleDic = [[TTDownloadManager shareInstance] getAllRuleFromDB:&error];
    DLLOGD(@"error=%@", error);
    return clearCacheRuleDic ? YES : NO;
}

@end

NS_ASSUME_NONNULL_END
