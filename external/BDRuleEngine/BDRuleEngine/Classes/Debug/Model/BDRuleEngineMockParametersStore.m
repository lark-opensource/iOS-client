//
//  BDRuleEngineMockParametersStore.m
//  BDRuleEngine
//
//  Created by WangKun on 2021/12/21.
//

#import "BDRuleEngineMockParametersStore.h"

@interface BDRuleEngineMockParametersStore()
@property (nonatomic, strong) NSMutableDictionary *mockDict;
@end

@implementation BDRuleEngineMockParametersStore

+ (BDRuleEngineMockParametersStore *)sharedStore
{
    static BDRuleEngineMockParametersStore *sharedStore = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedStore = [[BDRuleEngineMockParametersStore alloc] init];
    });
    return sharedStore;
}

+ (BOOL)enableMock
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"bd_rule_engine_enable_mock_params"];
}

+ (void)setEnableMock:(BOOL)enable
{
    [[NSUserDefaults standardUserDefaults] setBool:enable forKey:@"bd_rule_engine_enable_mock_params"];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:[self __filePath]]) {
            NSDictionary *dict = [[NSDictionary alloc] initWithContentsOfFile:[self __filePath]];
            _mockDict = [dict mutableCopy];
        } else {
            _mockDict = [[NSMutableDictionary alloc] init];
        }
    }
    return self;
}

- (void)saveMockValue:(id<NSCopying>)value
             forKey:(NSString *)key
{
    [_mockDict setObject:value forKey:key];
    [self __saveStore];
}

- (id)mockValueForKey:(NSString *)key
{
    if (!key) {
        return nil;
    }
    return _mockDict[key];
}

- (void)resetMock
{
    [_mockDict removeAllObjects];
    [self __saveStore];
}

- (BOOL)__saveStore
{
    BOOL success = [[_mockDict copy] writeToFile:[self __filePath] atomically:YES];
    return success;
}

- (NSString *)__filePath
{
    NSArray *directoryPaths = NSSearchPathForDirectoriesInDomains
     (NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectoryPath = [directoryPaths objectAtIndex:0];
    return  [documentsDirectoryPath stringByAppendingPathComponent:@"rule_engine_mock_params.plist"];
}

@end
