//
//  ACCReducer.h
//  Pods
//
//  Created by leo on 2019/12/11.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class ACCAction;

@interface ACCReducer : NSObject
+ (instancetype)reducer;

// 如果设置了这个属性，则此reducer只会处理对应class的action
@property (nonatomic, assign) Class domainActionClass;

- (id)stateWithAction:(ACCAction *)action andState:(id)state;
@end

NS_ASSUME_NONNULL_END
