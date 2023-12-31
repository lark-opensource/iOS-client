//
//  BDRuleEngineMockConfigStore.m
//  BDRuleEngine-Core-Debug-Expression-Service
//
//  Created by Chengmin Zhang on 2022/6/6.
//

#import "BDRuleEngineMockConfigStore.h"

@interface BDRuleEngineMockConfigStore()
@property (nonatomic, strong) NSDictionary *mockConfig;
@end

@implementation BDRuleEngineMockConfigStore

+ (BDRuleEngineMockConfigStore *)sharedStore
{
    static BDRuleEngineMockConfigStore *sharedStore = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedStore = [[BDRuleEngineMockConfigStore alloc] init];
    });
    return sharedStore;
}

+ (BOOL)enableMock
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"bd_rule_engine_enable_mock_config"];
}

+ (void)setEnableMock:(BOOL)enable
{
    [[NSUserDefaults standardUserDefaults] setBool:enable forKey:@"bd_rule_engine_enable_mock_config"];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:[self __filePath]]) {
            _mockConfig = [[NSDictionary alloc] initWithContentsOfFile:[self __filePath]];
        } else {
            _mockConfig = @{};
        }
    }
    return self;
}

- (BOOL)saveMockConfigValue:(NSDictionary *)value
{
    if ([value isKindOfClass:[NSDictionary class]]) {
        self.mockConfig = value;
        [self __saveStore];
        return YES;
    }
    return NO;
}

- (NSDictionary *)mockConfig
{
    return _mockConfig;
}

- (void)resetMockConfig
{
    _mockConfig = @{};
    [self __saveStore];
}

- (BOOL)__saveStore
{
    BOOL success = [_mockConfig writeToFile:[self __filePath] atomically:YES];
    return success;
}

- (NSString *)__filePath
{
    NSArray *directoryPaths = NSSearchPathForDirectoriesInDomains
     (NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectoryPath = [directoryPaths objectAtIndex:0];
    return  [documentsDirectoryPath stringByAppendingPathComponent:@"rule_engine_mock_config.plist"];
}

@end
