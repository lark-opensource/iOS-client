//  Copyright 2023 The Lynx Authors. All rights reserved.

#import "BDXLynxTextArea.h"
#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>

@interface MockUITextView : UITextView

@end

@implementation MockUITextView

@end

@interface BDXLynxTextArea (Test)

@property (nonatomic, assign) NSInteger maxLines;
@property (nonatomic, assign) CGFloat mWidth;

- (NSAttributedString *)getContentWithLimitedLines:(UIFont*)font
                                             lines:(NSInteger)maxLines
                                            source:(NSAttributedString*)source
                                              dest:(NSAttributedString*)dest
                                            dStart:(NSInteger)dStart
                                              dEnd:(NSInteger)dEnd
                                             index:(NSInteger*)cursor
                                       constraints:(CGSize)constraints;
@end


@interface BDXLynxTextAreaUnitTest : XCTestCase

@end

@implementation BDXLynxTextAreaUnitTest

- (void)setUp {

}

- (void)tearDown {
  // Put teardown code here. This method is called after the invocation of each test method in the
  // class.
}

- (void)testMaxLinesFilter {
    // font-size: 100rpx
    UIFont *font = [UIFont systemFontOfSize:52.400001525878906];
    NSString *sourceString = @"12345678901234567890123";
    NSDictionary *attrsDictionary = [NSDictionary dictionaryWithObject:font
                                    forKey:NSFontAttributeName];
    NSAttributedString *source = [[NSAttributedString alloc] initWithString:sourceString attributes:attrsDictionary];
    NSAttributedString *dest = [[NSAttributedString alloc] initWithString:@"" attributes:attrsDictionary];
    NSInteger dStart = 0;
    NSInteger dEnd = 0;
    NSInteger cursor = 0;
    NSInteger maxLines = 1;
    
    BDXLynxTextArea *textArea = [[BDXLynxTextArea alloc] init];
    // width: 750rpx;
    CGSize constraints = CGSizeMake(393, CGFLOAT_MAX);
    NSAttributedString *result = [textArea getContentWithLimitedLines:font lines:maxLines source:source dest:dest dStart:dStart dEnd:dEnd index:&cursor constraints:constraints];
    NSAttributedString *expect = [[NSAttributedString alloc] initWithString:@"1234567890123" attributes:attrsDictionary];
    XCTAssertEqualObjects(result, expect);
}

- (void)testMaxLinesFilterOnLongString {
    // font-size: 100rpx
    UIFont *font = [UIFont systemFontOfSize:52.400001525878906];
    NSString *sourceString = @"1\n2fsadkfjaosdjoiajsvadfasdr\n3\n4jadifjadf\n5\n6\n7\n8\n9\n0\n";
    NSDictionary *attrsDictionary = [NSDictionary dictionaryWithObject:font
                                    forKey:NSFontAttributeName];
    NSAttributedString *source = [[NSAttributedString alloc] initWithString:sourceString attributes:attrsDictionary];
    NSAttributedString *dest = [[NSAttributedString alloc] initWithString:@"" attributes:attrsDictionary];
    NSInteger dStart = 0;
    NSInteger dEnd = 0;
    NSInteger cursor = 0;
    NSInteger maxLines = 5;
    
    BDXLynxTextArea *textArea = [[BDXLynxTextArea alloc] init];
    // width: 750rpx;
    CGSize constraints = CGSizeMake(393, CGFLOAT_MAX);
    NSAttributedString *result = [textArea getContentWithLimitedLines:font lines:maxLines source:source dest:dest dStart:dStart dEnd:dEnd index:&cursor constraints:constraints];
    NSAttributedString *expect = [[NSAttributedString alloc] initWithString:@"1\n2fsadkfjaosdjoiajsvadfasdr\n3\n4jadifjadf" attributes:attrsDictionary];
    XCTAssertEqualObjects(result, expect);
}


@end
