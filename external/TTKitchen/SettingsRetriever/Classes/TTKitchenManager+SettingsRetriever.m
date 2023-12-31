//
//  TTKitchenSyncer+SettingsRetriever.m
//  TTKitchen-28d61c40
//
//  Created by bytedance on 2021/2/3.
//

#import "TTKitchenManager+SettingsRetriever.h"
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>

@implementation TTKitchenManager (SettingsRetriever)

+ (void)registerCloudCommandHandler {
    TTRegisterKitchenMethod
    [[AWECloudCommandManager sharedInstance] addCustomCommandHandlerCls:self];
}

// MARK: - AWECustomCommandHandler

+ (nonnull NSString *)cloudCommandIdentifier {
    return @"get_settings_command_on";
}

+ (nonnull instancetype)createInstance {
    return [self sharedInstance];
}

- (void)excuteCommandWithParams:(nonnull NSDictionary *)params completion:(nonnull AWECustomCommandCompletion)completion {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (completion) {
            NSDictionary *allKVs = [TTKitchen allKitchenRawDictionary];
            AWECustomCommandResult *result = [AWECustomCommandResult new];
            result.data = [[allKVs btd_jsonStringPrettyEncoded] dataUsingEncoding:NSUTF8StringEncoding];
            result.fileType = @"text";
            result.status = AWECloudCommandStatusSucceed;
            completion(result);
        }
    });
}

@end
