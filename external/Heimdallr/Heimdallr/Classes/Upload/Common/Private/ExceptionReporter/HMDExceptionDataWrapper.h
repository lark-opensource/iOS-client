//
//  HMDExceptionDataWrapper.h
//  Heimdallr
//
//  Created by yuanzhangjing on 2019/6/9.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HMDExceptionDataWrapper : NSObject

@property (nonatomic, strong, readonly) NSMutableArray * _Nonnull modules;
@property (nonatomic, strong, readonly) NSMutableArray * _Nonnull dataDicts;

@end

NS_ASSUME_NONNULL_END
