//
//  TestALinkURL.m
//  RangersAppLog-Unit-Tests
//
//  Created by 朱元清 on 2021/7/15.
//

#import <XCTest/XCTest.h>
#import "NSURL+ral_ALink.h"

@interface TestALinkURL : XCTestCase
@property (nonatomic) NSURL *universalALink;
@property (nonatomic) NSURL *URLSchemeALink;
@end

@implementation TestALinkURL

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
    self.universalALink = [NSURL URLWithString:@"https://jd.volctracer.com/a/test_i_am_a_token?tr_shareuser=shareuser&tr_admaster=admaster&tr_param1=param1"];
    self.URLSchemeALink = [NSURL URLWithString:@"jd://product/1?tr_token=test_i_am_a_token&tr_shareuser=shareuser&tr_admaster=admaster&tr_param1=param1"];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testALinkToken {
    NSString *token_universalALink = [self.universalALink ral_alink_token];
    XCTAssertTrue([token_universalALink isEqualToString:@"test_i_am_a_token"]);
    
    NSString *token_URLSchemeALink = [self.URLSchemeALink ral_alink_token];
    XCTAssertTrue([token_URLSchemeALink isEqualToString:@"test_i_am_a_token"]);
}

- (void)testALinkCustomParams {
    NSArray <NSURLQueryItem *> *customParams_universalALink = [self.universalALink ral_alink_custom_params];
    NSArray <NSURLQueryItem *> *customParams_URLSchemeALink = [self.URLSchemeALink ral_alink_custom_params];
    
    XCTAssertEqual(customParams_universalALink.count, 3);
    XCTAssertEqual(customParams_URLSchemeALink.count, 3);
    
    for (NSURLQueryItem *item in customParams_universalALink) {
        XCTAssertTrue([item.name isEqualToString:[@"tr_" stringByAppendingString:item.value]]);
        XCTAssertTrue([item.name hasPrefix:@"tr_"]);
    }
    for (NSURLQueryItem *item in customParams_URLSchemeALink) {
        XCTAssertTrue([item.name isEqualToString:[@"tr_" stringByAppendingString:item.value]]);
        XCTAssertTrue([item.name hasPrefix:@"tr_"]);
    }
}


@end
