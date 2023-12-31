//
//  TTDownloadLogLite.h
//  Pods
//
//  Created by diweiguang on 2021/6/22.
//
#import <JSONModel/JSONModel.h>

#ifndef TTDownloadLogLite_h
#define TTDownloadLogLite_h

NS_ASSUME_NONNULL_BEGIN

@interface TTDownloadLogLite : JSONModel
- (void)addDownloadLog:(NSString *)log error:(NSError *)error;
@end

NS_ASSUME_NONNULL_END

#endif /* TTDownloadLogLite_h */
