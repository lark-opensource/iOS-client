//
//  IESFalconStatRecorder.h
//  Pods
//
//  Created by 陈煜钏 on 2019/10/8.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface IESFalconStatRecorder : NSObject

+ (void)recordFalconStat:(NSDictionary *)statDictionary;

@end

NS_ASSUME_NONNULL_END
