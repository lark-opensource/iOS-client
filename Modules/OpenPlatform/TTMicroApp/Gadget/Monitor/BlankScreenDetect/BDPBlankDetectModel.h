//
//  BDPBlankDetectModel.h
//  Timor
//
//  Created by changrong on 2020/8/6.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDPBlankDetectModel : NSObject

@property (nonatomic, assign) CGFloat blankPixelsRate;
@property (nonatomic, assign) CGFloat lucencyPixelsRate;

@property (nonatomic, copy) NSString *maxPureColor;
@property (nonatomic, assign) CGFloat maxPureColorRate;

@end

NS_ASSUME_NONNULL_END
