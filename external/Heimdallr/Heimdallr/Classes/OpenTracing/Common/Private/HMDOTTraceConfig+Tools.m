//
//  HMDOTTraceConfig+Tools.m
//  Heimdallr-8bda3036
//
//  Created by liuhan on 2022/6/9.
//

#import "HMDOTTraceConfig+Tools.h"

@implementation HMDOTTraceConfig (Tools)

+ (NSString *)generateRandom16LengthString {
    uint32_t ran1 = arc4random();
    uint32_t ran2 = arc4random();
    uint64_t ran = ran1;
    ran = ran << 32;
    ran += ran2;
    NSString *hexString = [NSString stringWithFormat:@"%@",[[NSString alloc] initWithFormat:@"%016llx", ran]];
    return hexString;
}

- (NSString *)getTraceIDWithTraceParent:(NSString *)traceParent {
    if (!traceParent || traceParent.length != 55) {
        NSAssert(NO, @"traceParent: %@  The length of traceParent must be 55! Standard tracepaernt should be like {Version:2}-{TraceId:32}-{ParentId:16}-{Flags:2}", traceParent);
        return nil;
    }
    NSArray *splitArr = [traceParent componentsSeparatedByString:@"-"];
    if (splitArr.count != 4) {
        NSAssert(NO, @"traceParent: %@  The traceParent not conform W3C. Standard tracepaernt should be like {Version:2}-{TraceId:32}-{ParentId:16}-{Flags:2}", traceParent);
        return nil;
    }
    NSString *originalTraceID = splitArr[1];
    if (originalTraceID.length != 32 || ![self isvalidHexString:originalTraceID]) {
        NSAssert(NO, @"traceParent: %@  The traceParent not conform W3C. Standard tracepaernt should be like {Version:2}-{TraceId:32}-{ParentId:16}-{Flags:2}, the traceID must be a hexstring of 32 characters long", traceParent);
        return nil;
    }
    
    NSString *traceIDHigh = [originalTraceID substringToIndex:16];
    NSString *traceIDLow = [HMDOTTraceConfig generateRandom16LengthString];
    NSString *traceID = [traceIDHigh stringByAppendingString:traceIDLow];
    return traceID;
}

- (NSString *)generateTraceIDWithCCustomHighOrderTraceID:(NSString *)customHighOrderTraceID {
    if (customHighOrderTraceID.length != 16 || ![self isvalidHexString:customHighOrderTraceID]) {
        NSAssert(NO, @"customHighOrderTraceID: %@  The customHighOrderTraceID must be a hexstring of 16 characters long!", customHighOrderTraceID);
        return nil;
    }
    NSString *traceID = [customHighOrderTraceID stringByAppendingString: [HMDOTTraceConfig generateRandom16LengthString]];
    return traceID;
}

- (NSString *)generateTraceID {
    NSString *traceID;
    if (self.traceParent) {
        traceID = [self getTraceIDWithTraceParent:self.traceParent];
        if (traceID) return traceID;
    }
    if (self.customHighOrderTraceID) {
        traceID = [self generateTraceIDWithCCustomHighOrderTraceID:self.customHighOrderTraceID];
        if (traceID) return traceID;
    }
    
    traceID = [[HMDOTTraceConfig generateRandom16LengthString] stringByAppendingString: [HMDOTTraceConfig generateRandom16LengthString]];
    return traceID;
}

- (BOOL) isvalidHexString:(NSString *)hexStr {
    NSCharacterSet *hexChars = [[NSCharacterSet characterSetWithCharactersInString:@"0123456789ABCDEFabcdef"] invertedSet];
    BOOL isvalid = (NSNotFound == [hexStr rangeOfCharacterFromSet:hexChars].location);
    return isvalid;
}

@end
