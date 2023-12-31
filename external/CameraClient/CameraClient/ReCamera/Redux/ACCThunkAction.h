//
//  ACCThunkAction.h
//  CameraClient
//
//  Created by Liu Deping on 2020/1/5.
//

#import <Foundation/Foundation.h>
#import "ACCAction.h"
#import "ACCMiddleware.h"

typedef void (^ACCThunkBody)(ACCActionHandler dispatcher, ACCStateGetter getState);

NS_ASSUME_NONNULL_BEGIN

@interface ACCThunkAction : ACCAction

- (instancetype)initWithThunkBody:(ACCThunkBody)thunkBody;

@property (nonatomic, copy, readonly) ACCThunkBody thunkBody;

@end

NS_ASSUME_NONNULL_END
