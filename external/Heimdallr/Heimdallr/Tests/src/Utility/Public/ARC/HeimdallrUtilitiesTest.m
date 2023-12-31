//
//  HeimdallrUtilitiesTest.m
//  Pods
//
//  Created by liuhan on 2021/10/13.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import <Heimdallr/HeimdallrUtilities.h>

@interface HeimdallrUtilitiesTest : XCTestCase

@end

@implementation HeimdallrUtilitiesTest

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
}

- (void)test_dateStringFromDate_UTC_MilloFormat {
    //构建参数依赖
    NSDate* date = [NSDate dateWithTimeIntervalSince1970:100];
    //行为
    NSString* dateStringFormat = [HeimdallrUtilities dateStringFromDate:date isUTC:TRUE isMilloFormat:TRUE];
    //验证
    BOOL assertValue = [@[@"1970-01-01 12:01:40.000 AM", @"1970-01-01 00:01:40.000"] containsObject:dateStringFormat];
    XCTAssert(assertValue, @"dateStringFromDate_UTC_MilloFormat error!");
}

- (void)test_dateStringFromDate_UTC_NoMilloFormat {
    //构建参数依赖
    NSDate* date = [NSDate dateWithTimeIntervalSince1970:100];
    //行为
    NSString* dateStringFormat = [HeimdallrUtilities dateStringFromDate:date isUTC:TRUE isMilloFormat:FALSE];
    //验证 [@[@"1970-01-01 12:01:40.000 AM", @"1970-01-01 00:01:40"] containsObject:dateStringFormat]
    
    BOOL assertValue = [@[@"1970-01-01 12:01:40 AM", @"1970-01-01 00:01:40"] containsObject:dateStringFormat];
    XCTAssert(assertValue, @"dateStringFromDate_UTC_MilloFormat error!");
}

- (void)test_dateStringFromDate_NoUTC_NoMilloFormat {
    //构建参数依赖
    NSDate* date = [NSDate dateWithTimeIntervalSince1970:100];
    //行为
    NSString* dateStringFormat = [HeimdallrUtilities dateStringFromDate:date isUTC:FALSE isMilloFormat:FALSE];
    //验证
    
    BOOL assertValue = [@[@"1970-01-01 8:01:40 AM", @"1970-01-01 08:01:40"] containsObject:dateStringFormat];
    XCTAssert(assertValue, @"dateStringFromDate_UTC_MilloFormat error!");
}

- (void)test_dateStringFromDate_NoUTC_MilloFormat {
    //构建参数依赖
    NSDate* date = [NSDate dateWithTimeIntervalSince1970:100];
    //行为
    NSString* dateStringFormat = [HeimdallrUtilities dateStringFromDate:date isUTC:FALSE isMilloFormat:TRUE];
    //验证
    
    BOOL assertValue = [@[@"1970-01-01 8:01:40.000 AM", @"1970-01-01 08:01:40.000"] containsObject:dateStringFormat];
    XCTAssert(assertValue, @"dateStringFromDate_UTC_MilloFormat error!");
}

- (void)test_isClassFromApp {
    //构建参数依赖
    id hmdUtility = OCMClassMock([HeimdallrUtilities class]);
    //行为
    BOOL isClassFromApp = [HeimdallrUtilities isClassFromApp:[hmdUtility class]];
    //验证
    XCTAssertTrue(isClassFromApp, @"Tell class From App Error!");
}

- (void)test_payloadWithDecryptData_withkey_iv {
    //构建参数依赖
    NSString* dataBase6String = @"Ng6omA6leMMb3VOfn1qy0dy4qEon2LqjnHmeZsC2DK7BGoJ9PrTdjIfixGbBw4RzdM+3c1XGOx8bt3GF3EOZTMlvXiSE9AyEEnw2MXwn5PYfZDLRCFJDRK674Htl5vExyQn7JVgm5Ttpdy1p7f52JwLAzihtSCzVAxYF0LeJukiSNIdqYu7GTuOuI5EMoIpSp85cmTex3fCl+w+s+irGotuA37OlpBg0r2cNVhfTwxV6+ce2osEFit1FbC3GPZoCwFD3wCB4hu13NoCaC7xsNkTwJ4zp/Q2aOYRnjSC0JcAs4CIt4whdhIHTk/9fjpnFanRCYnXAw7dR9ohxkGT1eQ==";
    NSData* encryptedData = [dataBase6String dataUsingEncoding:NSUTF8StringEncoding];
    NSString* ran = @"yuNttCSojTyxZods";
    
    //行为
    NSDictionary* decryptedDict = [HeimdallrUtilities payloadWithDecryptData:encryptedData withKey:ran iv:ran];
    
    //验证
    XCTAssertNotNil(decryptedDict, @"payload analysis failed!");
}

- (void)test_payloadWithDecryptData_withErrkey_Erriv {
    //构建参数依赖
    NSString* dataBase6String = @"Ng6omA6leMMb3VOfn1qy0dy4qEon2LqjnHmeZsC2DK7BGoJ9PrTdjIfixGbBw4RzdM+3c1XGOx8bt3GF3EOZTMlvXiSE9AyEEnw2MXwn5PYfZDLRCFJDRK674Htl5vExyQn7JVgm5Ttpdy1p7f52JwLAzihtSCzVAxYF0LeJukiSNIdqYu7GTuOuI5EMoIpSp85cmTex3fCl+w+s+irGotuA37OlpBg0r2cNVhfTwxV6+ce2osEFit1FbC3GPZoCwFD3wCB4hu13NoCaC7xsNkTwJ4zp/Q2aOYRnjSC0JcAs4CIt4whdhIHTk/9fjpnFanRCYnXAw7dR9ohxkGT1eQ==";
    NSData* encryptedData = [dataBase6String dataUsingEncoding:NSUTF8StringEncoding];
    NSString* ran = @"yuNttCSojTyxZod";
    
    //行为
    NSDictionary* decryptedDict = [HeimdallrUtilities payloadWithDecryptData:encryptedData withKey:ran iv:ran];
    
    //验证
    XCTAssertNil(decryptedDict, @"payload analysis failed!");
}

- (void)test_payloadWithDecryptData_withNilkey_Niliv {
    //构建参数依赖
    NSString* dataBase6String = @"Ng6omA6leMMb3VOfn1qy0dy4qEon2LqjnHmeZsC2DK7BGoJ9PrTdjIfixGbBw4RzdM+3c1XGOx8bt3GF3EOZTMlvXiSE9AyEEnw2MXwn5PYfZDLRCFJDRK674Htl5vExyQn7JVgm5Ttpdy1p7f52JwLAzihtSCzVAxYF0LeJukiSNIdqYu7GTuOuI5EMoIpSp85cmTex3fCl+w+s+irGotuA37OlpBg0r2cNVhfTwxV6+ce2osEFit1FbC3GPZoCwFD3wCB4hu13NoCaC7xsNkTwJ4zp/Q2aOYRnjSC0JcAs4CIt4whdhIHTk/9fjpnFanRCYnXAw7dR9ohxkGT1eQ==";
    NSData* encryptedData = [dataBase6String dataUsingEncoding:NSUTF8StringEncoding];
    NSString* ran = @"";
    
    //行为
    NSDictionary* decryptedDict = [HeimdallrUtilities payloadWithDecryptData:encryptedData withKey:ran iv:ran];
    
    //验证
    XCTAssertNil(decryptedDict, @"payload analysis failed!");
}



- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
