//
//  AweQuaterbackSDK+extension.m
//  Quaterback
//
//  Created by hopo on 2021/8/19.
//

#import "BDBDMain+local.h"
#import "BDDYCZipArchive.h"
#import "BDBDModule.h"
#import "BDDYCModule+Internal.h"
#import "BDDDYHTSHeader.h"
#import "BDBDQuaterback.h"
#import "BDBDQuaterback+Internal.h"
#import "BDDYCModuleManager.h"

@implementation BDBDQuaterbackInfo

- (instancetype)init {
    self = [super init];
    if (self) {
        _async = YES;
    }
    return self;
}

@end

@implementation BDBDMain (local)

+ (BOOL)unzipFileAtPath:(NSString *)path
          toDestination:(NSString *)destination
             completion:(void (^_Nullable)(NSArray<NSString *> * _Nullable filePaths, NSError * _Nullable error))completionHandler {
    return [BDDYCZipArchive unzipFileAtPath:path toDestination:destination completion:^(NSArray<NSString *> * _Nullable filePaths, NSError * _Nullable error) {
        if (completionHandler) {
            completionHandler(filePaths, error);
        }
    }];
}

+ (void)loadQuaterbackWithInfo:(BDBDQuaterbackInfo *)info error:(NSError **)error {

    NSArray<NSString *> * files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:info.path error:error];
    if (*error) {
        return;
    }
    NSMutableArray *filePaths = [NSMutableArray array];
    [files enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [filePaths addObject:[info.path stringByAppendingPathComponent:obj]];
    }];

    [[BDBDQuaterback sharedMain] runBrady];

    BDBDModule *module = [BDBDModule moduleWithFiles:[filePaths mutableCopy]];
    [module initModuleModel];
    module.moduleModel.name = info.name;
    module.moduleModel.version = [NSString stringWithFormat:@"%d", info.version];
    module.moduleModel.async = info.async;

    [[BDDYCModuleManager sharedManager] addModule:module];

    if ([[BDBDQuaterback sharedMain].delegate respondsToSelector:@selector(moduleData:willLoadWithError:)]) {
        [[BDBDQuaterback sharedMain].delegate moduleData:module willLoadWithError:nil];
    }
    [module loadAndReturnError:&error
       skipsFileNameValidation:info.skipsFileNameValidation];
}

@end
