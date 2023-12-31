//
//  ACCDynamicReducer.h
//  CameraClient
//
//  Created by leo on 2019/12/19.
//

#import <Foundation/Foundation.h>
#import "ACCCompositeReducer.h"

NS_ASSUME_NONNULL_BEGIN

@interface ACCDynamicReducer : ACCCompositeReducer
- (void)addReducer:(ACCReducer *)reducer withKey:(NSString *)key;
- (void)addReducers:(NSDictionary *)reducerMap;
@end

NS_ASSUME_NONNULL_END
