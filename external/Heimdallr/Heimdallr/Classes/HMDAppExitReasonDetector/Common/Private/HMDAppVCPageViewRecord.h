//
//  HMDAppVCPageViewRecord.h
//  Pods
//
//  Created by wangyinhui on 2023/2/22.
//

#import <Foundation/Foundation.h>

#ifndef HMDAppVCPageViewRecord_h
#define HMDAppVCPageViewRecord_h

@interface HMDAppVCPageViewRecord : NSObject

+(nonnull instancetype)shared;

//key: vc name  value:entry times
-(nullable NSDictionary<NSString*, NSNumber *> *)getHistoryPageViewStatisticInfo;

-(void)recordPageViewForVCAsync:(nonnull NSString *)vc;

-(void)writePageViewInfoToFileAsync;

-(void)reportLastPageViewInfoAsync;

@end


#endif /* HMDAppVCPageViewRecord_h */
