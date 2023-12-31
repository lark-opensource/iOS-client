//
//  AWECloudCommandModel.m
//  Pods
//
//  Created by willorfang on 2017/1/23.
//
//

#import "AWECloudCommandModel.h"
#import "NSDictionary+AWECloudCommandUtil.h"

@interface AWECloudCommandModel ()

@property (nonatomic, copy) NSArray<NSString *> *blockList;

@end

@implementation AWECloudCommandModel

- (instancetype)initWithDict:(NSDictionary *)dict {
    self = [super init];
    if (self) {
        _commandId = @([dict awe_cc_longlongValueForKey:@"command_id"]);
        _type = [dict awe_cc_stringValueForKey:@"type"];
        NSString *str = [dict awe_cc_stringValueForKey:@"params"];
        if (str.length > 0) {
            NSData *jsonData = [str dataUsingEncoding:NSUTF8StringEncoding];
            _params = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:nil];
        }
    }
    return self;
}

- (void)configFileBlockList:(NSArray<NSString *> *)blockList {
    self.blockList = blockList;
}

- (NSArray<NSString *> *)allowedFilePathsAfterChecking:(NSString *)path {
    NSMutableArray *allowedPaths = [NSMutableArray array];
    NSMutableArray *hitBlockList = [NSMutableArray array];
    NSString *absolutePath = [NSHomeDirectory() stringByAppendingPathComponent:path];
    BOOL allowed = YES;
    
    // hit block list
    for (NSString *blockFilePath in self.blockList) {
        NSString *blockFullPah = [NSHomeDirectory() stringByAppendingPathComponent:blockFilePath];
        if ([absolutePath containsString:blockFullPah]) {
            allowed = NO;
            break;
        }
        if ([blockFullPah containsString:absolutePath]) {
            [hitBlockList addObject:blockFullPah];
            allowed = NO;
        }
    }
    
    // allowed direcory or file
    if (allowed) {
        [allowedPaths addObject:absolutePath];
    }
    
    // not allowed direcory or file
    if (!hitBlockList.count) {
        return allowedPaths.copy;
    }
    
    // look up allowed file
    NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtPath:absolutePath];
    if (!enumerator) {
        return allowedPaths.copy;
    }
    NSArray *subPaths = enumerator.allObjects;
    for (NSString *subPath in subPaths) {
        @autoreleasepool {
            NSString *subFullPath = [absolutePath stringByAppendingPathComponent:subPath];
            BOOL allowedFile = YES;
            BOOL isDirectory;
            BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:subFullPath isDirectory:&isDirectory];
            if (!exists || isDirectory) {
                continue;
            }
            
            for (NSString *blockFullPah in hitBlockList) {
                if ([subFullPath containsString:blockFullPah]) {
                    allowedFile = NO;
                    break;
                }
            }
            
            // allowed file
            if (allowedFile) {
                [allowedPaths addObject:subFullPath];
            }
        }
    }
    
    return allowedPaths.copy;
}

@end

/////////////////////////////////////////////////////////////////////

@implementation AWECloudCommandResult

- (instancetype)init
{
    self = [super init];
    if (self) {
        _status = AWECloudCommandStatusSucceed;
        _fileType = @"unknown";
    }
    return self;
}

@end

/////////////////////////////////////////////////////////////////////

static NSMapTable<NSString *, Class<AWECloudCommandProtocol>> *registeredCommandDict;

inline void AWECloudCommandRegisterCommand(NSString *type, Class<AWECloudCommandProtocol> commandClass)
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        registeredCommandDict = [NSMapTable mapTableWithKeyOptions:NSMapTableStrongMemory valueOptions:NSMapTableCopyIn];
    });
    
    if (!commandClass) {
        return;
    }
    
    NSString *errorString = [NSString stringWithFormat:@"Duplicate registered command type: %@", type];
#pragma unused(errorString)
    NSCAssert([registeredCommandDict objectForKey:type] == nil, errorString);
    
    errorString = [NSString stringWithFormat:@"%@ must confirm to AWECloudCommandProtocol", commandClass];
    NSCAssert([commandClass conformsToProtocol:@protocol(AWECloudCommandProtocol)], errorString);
    
    [registeredCommandDict setObject:commandClass forKey:type];
}

inline Class<AWECloudCommandProtocol> AWECloudCommandForType(NSString *type)
{
    return [registeredCommandDict objectForKey:type];
}
