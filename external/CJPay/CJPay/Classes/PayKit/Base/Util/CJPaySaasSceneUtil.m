//
//  CJPaySaasSceneUtil.m
//  CJPay
//
//  Created by 利国卿 on 2023/7/19.
//

#import "CJPaySaasSceneUtil.h"
#import "CJPaySDKMacro.h"

static NSMutableArray<CJPaySaasRecordModel *> *cjSaasSceneArray;
NSString * const CJPaySaasKey = @"is_caijing_saas";

@interface CJPaySaasRecordModel ()

@property (nonatomic, copy) NSString *recordKey;
@property (nonatomic, copy) NSString *saasSceneValue;

@end

@implementation CJPaySaasRecordModel

- (instancetype)initWithKey:(NSString *)key saasScene:(NSString *)saasScene {
    self = [self init];
    if (self) {
        _recordKey = key;
        _saasSceneValue = saasScene;
    }
    return self;
}

@end

@implementation CJPaySaasSceneUtil

// 使用NSMutableArray模拟栈来存储SaaS环境标识，避免嵌套调用导致标识不正确问题
+ (NSMutableArray<CJPaySaasRecordModel *> *)getSaasSceneArray {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cjSaasSceneArray = [NSMutableArray new];
    });
    return cjSaasSceneArray;
}

// SaaS标识入栈，一般为支付流程入口调用
+ (void)addSaasKey:(NSString *)recordKey saasSceneValue:(NSString *)saasScene {
    if (!Check_ValidString(recordKey)) {
        CJPayLogAssert(YES, @"saasKey为空！");
        return;
    }
    NSString *saasSceneValue = Check_ValidString(saasScene) ? saasScene : @"";
    CJPaySaasRecordModel *model = [[CJPaySaasRecordModel alloc] initWithKey:recordKey saasScene:saasSceneValue];
    [[self getSaasSceneArray] btd_addObject:model];
}

// 取得当前支付流程（栈顶）的SaaS标识
+ (NSString *)getCurrentSaasSceneValue {
    id lastSaasModel = [[self getSaasSceneArray] lastObject];
    if ([lastSaasModel isKindOfClass:CJPaySaasRecordModel.class]) {
        CJPaySaasRecordModel *model = (CJPaySaasRecordModel *)lastSaasModel;
        return model.saasSceneValue;
    }
    return @"";
}

// 移除当前支付流程SaaS标识（出栈），一般为支付流程结束时调用
+ (void)removeSaasSceneByKey:(NSString *)saasRecordKey {
    id lastSaasModel = [[self getSaasSceneArray] lastObject];
    if ([lastSaasModel isKindOfClass:CJPaySaasRecordModel.class]) {
        CJPaySaasRecordModel *model = (CJPaySaasRecordModel *)lastSaasModel;
        if (![saasRecordKey isEqualToString:model.recordKey]) {
            CJPayLogAssert(YES, @"栈顶saasKey与要移除的saasKey不一致！");
            return;
        }
        [[self getSaasSceneArray] removeLastObject];
    }
}

@end
