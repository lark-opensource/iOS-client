//
//  HMDCommonAPISetting.h
//  Heimdallr
//
//  Created by yuanzhangjing on 2019/5/23.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HMDCommonAPISetting : NSObject

@property (nonatomic, copy) NSArray *hosts; //备用域名
@property (nonatomic, assign) BOOL enableEncrypt;

@end

NS_ASSUME_NONNULL_END
