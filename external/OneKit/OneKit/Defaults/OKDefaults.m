//
//  OKDefaults.m
//  OneKit
//
//  Created by bob on 2020/4/26.
//

#import "OKDefaults.h"
#import "NSMutableDictionary+OK.h"
#import "NSDictionary+OK.h"
#import "NSFileManager+OK.h"
#import "OKMacros.h"

static NSMutableDictionary<NSString *, OKDefaults *> *allDefaults = nil;
static dispatch_semaphore_t semaphore = NULL;

@interface OKDefaults ()

@property (nonatomic, copy) NSString *identifier;
@property (nonatomic, copy) NSString *plistPath;
@property (nonatomic, strong) NSMutableDictionary *rawData;
@property (nonatomic, strong) dispatch_semaphore_t semaphore;

@end

@implementation OKDefaults

+ (NSString *)defaultPathForIdentifier:(NSString *)identifier {
    static NSString *document = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        document = [[NSFileManager ok_documentPath] stringByAppendingPathComponent:@"onekit_defaults"];
        NSFileManager *fm = [NSFileManager defaultManager];
        BOOL isDir = NO;
        if ([fm fileExistsAtPath:document isDirectory:&isDir]) {
            if (!isDir) {
                [fm removeItemAtPath:document error:nil];
                [fm createDirectoryAtPath:document withIntermediateDirectories:YES attributes:nil error:nil];
            }
        } else {
            [fm createDirectoryAtPath:document withIntermediateDirectories:YES attributes:nil error:nil];
        }
         /// 耗时操作
        dispatch_block_t block = ^{
            NSURL *url = [NSURL fileURLWithPath:document];
            [url setResourceValue:[NSNumber numberWithBool:YES] forKey:NSURLIsExcludedFromBackupKey error:nil];
        };
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)),
                       dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
                       block);
    });
    
    return [document stringByAppendingPathComponent:identifier];
}

+ (instancetype)defaultsWithIdentifier:(NSString *)identifier {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        allDefaults = [NSMutableDictionary new];
        semaphore = dispatch_semaphore_create(1);
    });
    
    if (![identifier isKindOfClass:[NSString class]] || identifier.length < 1) {
        return nil;
    }
    
    OK_Lock(semaphore);
    OKDefaults *defaults = [allDefaults objectForKey:identifier];
    if (!defaults) {
        defaults = [[OKDefaults alloc] initWithIdentifier:identifier];
        [allDefaults setValue:defaults forKey:identifier];
    }
    OK_Unlock(semaphore);

    return defaults;
}

- (instancetype)initWithIdentifier:(NSString *)identifier path:(NSString *)path {
    self = [super init];
    if (self) {
        self.identifier = identifier;
        self.plistPath = path;
        self.rawData = [NSMutableDictionary dictionaryWithContentsOfFile:path] ?: [NSMutableDictionary new];
        self.semaphore = dispatch_semaphore_create(1);
    }

    return self;
}

- (instancetype)initWithIdentifier:(NSString *)identifier {
    NSString *plistPath = [OKDefaults defaultPathForIdentifier:identifier];
    
    return [self initWithIdentifier:identifier path:plistPath];
}


- (BOOL)boolValueForKey:(NSString *)key {
    if (key == nil) {
        return NO;
    }
    OK_Lock(self.semaphore);
    BOOL value = [self.rawData ok_boolValueForKey:key];
    OK_Unlock(self.semaphore);
    
    return value;
}

- (double)doubleValueForKey:(NSString *)key {
    if (key == nil) {
        return 0;
    }
    OK_Lock(self.semaphore);
    double value = [self.rawData ok_doubleValueForKey:key];
    OK_Unlock(self.semaphore);
    
    return value;
}

- (NSInteger)integerValueForKey:(NSString *)key {
    if (key == nil) {
        return 0;
    }
    OK_Lock(self.semaphore);
    NSInteger value = [self.rawData ok_integerValueForKey:key];
    OK_Unlock(self.semaphore);
    
    return value;
}

- (long long)longlongValueForKey:(NSString *)key {
    if (key == nil) {
        return 0;
    }
    OK_Lock(self.semaphore);
    long long value = [self.rawData ok_longlongValueForKey:key];
    OK_Unlock(self.semaphore);
    
    return value;
}

- (NSString *)stringValueForKey:(NSString *)key {
    if (key == nil) {
        return nil;
    }
    OK_Lock(self.semaphore);
    NSString *value = [self.rawData ok_stringValueForKey:key];
    OK_Unlock(self.semaphore);
    
    return value;
}

- (NSDictionary *)dictionaryValueForKey:(NSString *)key {
    if (key == nil) {
        return nil;
    }
    OK_Lock(self.semaphore);
    NSDictionary *value = [self.rawData ok_dictionaryValueForKey:key];
    OK_Unlock(self.semaphore);
    
    return value;
}

- (NSArray *)arrayValueForKey:(NSString *)key {
    if (key == nil) {
        return nil;
    }
    OK_Lock(self.semaphore);
    NSArray *value = [self.rawData ok_arrayValueForKey:key];
    OK_Unlock(self.semaphore);
    
    return value;
}

- (void)setDefaultValue:(id)value forKey:(NSString *)key {
    if (key == nil) {
        return;
    }
    OK_Lock(self.semaphore);
    [self.rawData setValue:value forKey:key];
    OK_Unlock(self.semaphore);
}

- (id)defaultValueForKey:(NSString *)key {
    if (key == nil) {
        return nil;
    }
    OK_Lock(self.semaphore);
    id value = [self.rawData objectForKey:key];
    OK_Unlock(self.semaphore);
    
    return value;
}

- (void)saveDataToFile {
    OK_Lock(self.semaphore);
    NSDictionary *data = [self.rawData ok_safeJsonObject];
    if (@available(iOS 11, *)) {
        [data writeToURL:[NSURL fileURLWithPath:self.plistPath] error:nil];
    } else {
        [data writeToFile:self.plistPath atomically:YES];
    }
    OK_Unlock(self.semaphore);
}

- (void)clearAllData {
    OK_Lock(self.semaphore);
    self.rawData = [NSMutableDictionary new];
    [[NSFileManager defaultManager] removeItemAtPath:self.plistPath error:nil];
    OK_Unlock(self.semaphore);
}

@end
