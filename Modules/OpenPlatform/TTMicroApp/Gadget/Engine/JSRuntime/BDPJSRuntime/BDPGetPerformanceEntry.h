//
//  BDPGetPerformanceEntry.h
//  TTMicroApp
//
//  Created by ChenMengqi on 2023/4/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

//因为历史原因 bdpperformanceprofilemanager是oc写的，swift 和 oc enum等互调太麻烦了，oc public也会增大包体积，所以跟这个强相关的entry类 也用oc写了


typedef NS_ENUM(NSUInteger, BDPGetPerformanceEntryType) {
    BDPGetPerformanceEntryTypeLaunch,
    BDPGetPerformanceEntryTypeResource,
    BDPGetPerformanceEntryTypeScript,
    BDPGetPerformanceEntryTypePaint,
    BDPGetPerformanceEntryTypeDefault
};

@interface BDPGetPerformanceEntry : NSObject

@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) BDPGetPerformanceEntryType entryType;
@property (nonatomic, assign) double startTime;
@property (nonatomic, assign) double duration;
@property (nonatomic, copy) NSString *fileName;
@property (nonatomic, assign) bool isPreload;
@property (nonatomic, assign) NSInteger webviewId;

-(NSString *)convertEntryType;

@end



NS_ASSUME_NONNULL_END
