//
//  TSPKSignalManagerTests.m
//  TSPrivacyKit-06c17350-Unit-Tests
//
//  Created by ByteDance on 2022/12/27.
//

#import <XCTest/XCTest.h>
#import <TSPrivacyKit/TSPKSignalManager+public.h>
#import <TSPrivacyKit/TSPKSignalManager+private.h>
#import <ByteDanceKit/ByteDanceKit.h>
#import <OCMock/OCMock.h>

@interface TSPKSignalManagerTests : XCTestCase

@end

@implementation TSPKSignalManagerTests

- (void)setUp {
    [[TSPKSignalManager sharedManager] setConfig:[self config]];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

#pragma mark - tests

- (void)testVideoSignalFlow {
    NSString *permissionType = @"video";
    
    [TSPKSignalManager removeAllSignalsWithPermissionType:permissionType];
    
    NSString *careInstance = @"0x10001";
    NSString *otherInstance = @"0x10002";
    
    [TSPKSignalManager addCommonSignalWithType:TSPKCommonSignalTypePage content:@"CareViewController1 enter"];
    [TSPKSignalManager addCommonSignalWithType:TSPKCommonSignalTypePage content:@"CarelessViewController1"];
    [TSPKSignalManager addPairSignalWithAPIUsageType:TSPKAPIUsageTypeStart permissionType:permissionType content:@"system open" instanceAddress:careInstance];
    [TSPKSignalManager addCommonSignalWithType:TSPKCommonSignalTypeApp content:@"app enter background"];
    [TSPKSignalManager addPairSignalWithAPIUsageType:TSPKAPIUsageTypeStart permissionType:permissionType content:@"system open" instanceAddress:otherInstance];
    [TSPKSignalManager addPairSignalWithAPIUsageType:TSPKAPIUsageTypeStop permissionType:permissionType content:@"system close" instanceAddress:otherInstance];
    [TSPKSignalManager addSignalWithType:TSPKSignalTypeGuard permissionType:@"whatever" content:@"xxxx"];
    NSString *content = @"Guard detect unreleased";
    [TSPKSignalManager addSignalWithType:TSPKSignalTypeGuard
                          permissionType:permissionType
                                 content:content
                               extraInfo:@{@"instance": careInstance}];
    [TSPKSignalManager addPairSignalWithAPIUsageType:TSPKAPIUsageTypeStop permissionType:permissionType content:@"system close" instanceAddress:careInstance];
    [TSPKSignalManager addCommonSignalWithType:TSPKCommonSignalTypePage content:@"CareViewController1 leave"];

    // expected result
    NSArray *expectedSignals = @[
        @{@"content" : @"CareViewController1 enter"},
        @{@"content" : @"system open", @"instance": careInstance, @"usage": @(TSPKAPIUsageTypeStart)},
        @{@"content" : @"app enter background"},
        @{@"content" : @"system open", @"instance": otherInstance, @"usage": @(TSPKAPIUsageTypeStart)},
        @{@"content" : @"system close", @"instance": otherInstance, @"usage": @(TSPKAPIUsageTypeStop)},
        @{@"content" : @"Guard detect unreleased", @"instance" : careInstance},
        @{@"content" : @"system close", @"instance": careInstance, @"usage": @(TSPKAPIUsageTypeStop)},
        @{@"content" : @"CareViewController1 leave"}
    ];
    NSLog(@"expectedSignals %@", expectedSignals);
    
    [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
    
    // 1
    NSDictionary *result = [TSPKSignalManager signalInfoWithPermissionType:permissionType instanceAddress:careInstance];
    NSArray *signals = [result btd_arrayValueForKey:@"signals"];
    NSLog(@"signals %@", signals);
    XCTAssertEqual(signals.count, expectedSignals.count, @"video signals count not equal");
    // compare content
    [self compareSignals:expectedSignals withSignals:signals];
    
    // 2
    NSDictionary *pairResult = [TSPKSignalManager pairSignalInfoWithPermissionType:permissionType];
    NSArray *pairSignals = [pairResult btd_arrayValueForKey:@"signals"];
    NSLog(@"pair signals %@", pairSignals);
    XCTAssertEqual(pairSignals.count, expectedSignals.count, @"video signals count not equal");
    // compare content
    [self compareSignals:expectedSignals withSignals:pairSignals];
}

- (void)testNotCommonSignal {
    NSString *permissionType = @"video";
    
    [TSPKSignalManager removeAllSignalsWithPermissionType:permissionType];
    
    [TSPKSignalManager addCommonSignalWithType:TSPKCommonSignalTypePage content:@"CareViewController1 enter"];
    [TSPKSignalManager addCommonSignalWithType:TSPKCommonSignalTypePage content:@"CareViewController1 leave"];
    NSArray *expectedSignals = @[
        @{@"content" : @"CareViewController1 enter"},
        @{@"content" : @"CareViewController1 leave"}
    ];
    
    [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];

    NSDictionary *result = [TSPKSignalManager pairSignalInfoWithPermissionType:permissionType];
    NSArray *signals = [result btd_arrayValueForKey:@"signals"];
    NSLog(@"signals %@", signals);
    XCTAssertEqual(signals.count, expectedSignals.count, @"video signals count not equal");
    // compare content
    [self compareSignals:expectedSignals withSignals:signals];
}

- (void)testMaxSize {
    NSString *permissionType = @"audio";
    
    [TSPKSignalManager removeAllSignalsWithPermissionType:permissionType];
    
    NSString *careInstance = @"0x10001";
    
    for (NSInteger i = 0; i < 11; i++) {
        [TSPKSignalManager addCommonSignalWithType:TSPKCommonSignalTypeApp content:@"app enter background"];
    }
    
    [TSPKSignalManager addSignalWithType:TSPKSignalTypeGuard permissionType:permissionType content:@"Guard detect"];
    [TSPKSignalManager addPairSignalWithAPIUsageType:TSPKAPIUsageTypeStart permissionType:permissionType content:@"system open" instanceAddress:careInstance];
    
    // expected result
    NSArray *expectedSignals = @[
        @{@"content" : @"app enter background"},
        @{@"content" : @"app enter background"},
        @{@"content" : @"app enter background"},
        @{@"content" : @"app enter background"},
        @{@"content" : @"app enter background"},
        @{@"content" : @"app enter background"},
        @{@"content" : @"app enter background"},
        @{@"content" : @"app enter background"},
        @{@"content" : @"Guard detect"},
        @{@"content" : @"system open", @"instance": careInstance, @"usage": @(TSPKAPIUsageTypeStart)},
    ];
    
    [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
        
    // result
    NSDictionary *result = [TSPKSignalManager signalInfoWithPermissionType:permissionType instanceAddress:careInstance];
    NSArray *signals = [result btd_arrayValueForKey:@"signals"];
    NSLog(@"signals %@", signals);
    
    XCTAssertEqual(signals.count, expectedSignals.count, @"audio signals count not equal");
    
    // compare content
    [self compareSignals:expectedSignals withSignals:signals];
}


- (void)testComposition {
    NSString *permissionType = @"location";
    [TSPKSignalManager removeAllSignalsWithPermissionType:permissionType];
    
    [TSPKSignalManager addCommonSignalWithType:TSPKCommonSignalTypeApp content:@"app enter background"];
    [TSPKSignalManager addSignalWithType:TSPKSignalTypeCustom permissionType:permissionType content:@"location custom"];
    [TSPKSignalManager addCommonSignalWithType:TSPKCommonSignalTypeApp content:@"app enter foreground"];
    [TSPKSignalManager addSignalWithType:TSPKSignalTypeGuard permissionType:permissionType content:@"whatever"];
    [TSPKSignalManager addPairSignalWithAPIUsageType:TSPKAPIUsageTypeStart permissionType:permissionType content:@"whatevet" instanceAddress:@"0x88923"];

    // expected result
    NSArray *expectedSignals = @[
        @{@"content" : @"location custom"},
    ];
    
    [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
        
    // result
    NSArray *signals = [TSPKSignalManager signalFlowWithPermissionType:permissionType];
    NSLog(@"signals %@", signals);
    
    XCTAssertEqual(signals.count, expectedSignals.count, @"location signals count not equal");
    
    // compare content
    [self compareSignals:expectedSignals withSignals:signals];
}

#pragma mark - helper

- (void)compareSignals:(NSArray *)signals withSignals:(NSArray *)anotherSignals {
    // compare content
    [signals enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull expectedSignal, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *expectedContent = [expectedSignal btd_stringValueForKey:@"content"];
        NSDictionary *signal = anotherSignals[idx];
        NSString *content = [signal btd_stringValueForKey:@"content"];
        XCTAssertTrue([expectedContent isEqualToString:content], @"content not equal");
    }];
}

#pragma mark - prepare

- (NSDictionary *)config {
    return @{
        @"max_signal_size" : @(10),
        @"alog": @{
            @"Tool": @[
                @{
                    @"content": @"ToolALog",
                    @"dataTypes":@[
                        @"video"
                    ]
                }
            ]
        },
        @"before_start_range": @10,
        @"carePages":@[
            @"CareViewController1",
            @"CareViewController2",
        ],
        @"composition":@{
            @"audio":@[
                @"common",
                @"guard",
                @"system",
                @"custom",
                @"pair_method",
                @"log"
            ],
            @"location":@[
                @"custom"
            ],
            @"video":@[
                @"common",
                @"guard",
                @"system",
                @"custom",
                @"pair_method",
                @"log"
            ]
        }};
}

@end
