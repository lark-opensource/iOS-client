//
//  HMDOTManagerTest.m
//  Pods
//
//  Created by liuhan on 2021/11/12.
//

#import <XCTest/XCTest.h>
#import "HMDOTManager+HMDUnitTest.h"
#if !RANGERSAPM
#import <Heimdallr/HMDConfigDataProcessor.h>

@interface HMDConfigDataProcessor (HMDUnitTest)

+ (NSDictionary *)_mergeCacheDict:(NSDictionary *)cacheDict withMergeDict:(NSDictionary<NSString *, id> *)mergeDict;

@end

@interface HMDConfigManagerTest : XCTestCase

@end

@implementation HMDConfigManagerTest

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testDictionaryMerge {
    
    NSDictionary *resDic1 = [HMDConfigDataProcessor _mergeCacheDict:nil withMergeDict:@{
        @"key1#key2#key3" : @"value"
    }];
    NSDictionary *expectedResDic1 = @{
        @"key1": @{
            @"key2": @{
                @"key3": @"value"
            }
        }
    };
    XCTAssert([expectedResDic1 isEqual:resDic1]);
    
    NSDictionary *origDic2 = @{
        @"key1": @{
            @"key2": @{
                @"key3": @"value1"
            }
        }
    };
    NSDictionary *mergeDic2 = @{
        @"key1#key2#key3" : @"value2"
    };
    NSDictionary *resDic2 = [HMDConfigDataProcessor _mergeCacheDict:origDic2 withMergeDict:mergeDic2];
    NSDictionary *expectedResDic2 = @{
        @"key1": @{
            @"key2": @{
                @"key3": @"value2"
            }
        }
    };
    XCTAssert([expectedResDic2 isEqual:resDic2]);
    
    
    NSDictionary *origDic3 = @{
        @"key1": @{
            @"key2": @{
                @"key3": @"value1"
            }
        }
    };
    NSDictionary *mergeDic3 = @{
        @"key1#key2" : @"value2"
    };
    NSDictionary *resDic3 = [HMDConfigDataProcessor _mergeCacheDict:origDic3 withMergeDict:mergeDic3];
    NSDictionary *expectedResDic3 = @{
        @"key1": @{
            @"key2": @"value2"
        }
    };
    XCTAssert([expectedResDic3 isEqual:resDic3]);
    
    
    NSDictionary *origDic4 = @{
        @"key1": @{
            @"key2": @{
                @"key3": @"value1"
            }
        }
    };
    NSDictionary *mergeDic4 = @{
        @"key1#key2#key3" : @{
            @"key4": @"value2"
        }
    };
    NSDictionary *resDic4 = [HMDConfigDataProcessor _mergeCacheDict:origDic4 withMergeDict:mergeDic4];
    NSDictionary *expectedResDic4 = @{
        @"key1": @{
            @"key2": @{
                @"key3": @{
                    @"key4": @"value2"
                }
            }
        }
    };
    XCTAssert([expectedResDic4 isEqual:resDic4]);
    
    NSDictionary *origDic5 = @{
        @"key1": @{
            @"key2": @{
                @"key3": @"value1"
            }
        }
    };
    NSDictionary *mergeDic5 = @{
        @"key1#key2#key3#key4" : @"value3"
    };
    NSDictionary *resDic5 = [HMDConfigDataProcessor _mergeCacheDict:origDic5 withMergeDict:mergeDic5];
    NSDictionary *expectedResDic5 = @{
        @"key1": @{
            @"key2": @{
                @"key3": @{
                    @"key4": @"value3"
                }
            }
        }
    };
    XCTAssert([expectedResDic5 isEqual:resDic5]);
}

@end

#endif
