//
//  BDPGetPerformanceEntry.m
//  TTMicroApp
//
//  Created by ChenMengqi on 2023/4/25.
//

#import "BDPGetPerformanceEntry.h"

@implementation BDPGetPerformanceEntry

/*
 BDPGetPerformanceEntryTypeLaunch,
 BDPGetPerformanceEntryTypeResource,
 BDPGetPerformanceEntryTypeScript,
 BDPGetPerformanceEntryTypePaint,
 BDPGetPerformanceEntryTypeDefault
 */
-(NSString *)convertEntryType{
    switch (self.entryType) {
        case BDPGetPerformanceEntryTypeLaunch:
            return @"launch";
        case BDPGetPerformanceEntryTypeResource:
            return @"resource";
        case BDPGetPerformanceEntryTypePaint:
            return @"paint";
        case BDPGetPerformanceEntryTypeScript:
            return @"script";
        default:
            break;
    }
    return @"";
}

@end
