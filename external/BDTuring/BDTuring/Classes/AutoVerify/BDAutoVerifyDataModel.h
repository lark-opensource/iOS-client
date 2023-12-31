//
//  BDAutoVerifyDataModel.h
//  BDTuring
//
//  Created by yanming.sysu on 2020/8/6.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDAutoVerifyDataModel : NSObject

@property (nonatomic, assign) NSUInteger operateDuration;
@property (nonatomic, assign) CGFloat force;
@property (nonatomic, assign) CGFloat majorRadius;
@property (nonatomic, assign) NSUInteger clickDuration;
@property (nonatomic, assign) CGPoint clickPoint;
@property (nonatomic, assign) CGSize maskViewSize;

@end

NS_ASSUME_NONNULL_END
