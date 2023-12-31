//
//  BDPBlankDetectConfig.h
//  Timor
//
//  Created by changrong on 2020/8/6.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString *const BDPBlankDetectCommandClose;
extern NSString *const BDPBlankDetectCommandBlank;
extern NSString *const BDPBlankDetectCommandNotBlank;

@interface BDPBlankDetectConfig : NSObject

@property (nonatomic, copy) NSString *strategy;

@end

NS_ASSUME_NONNULL_END
