//
//  IWKDelegateCompletionProbe.h
//  BDWebCore
//
//  Created by li keliang on 2020/1/3.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface IWKDelegateCompletionProbe : NSObject

@property (nonatomic, assign, getter=shouldCatchFatalError, class) BOOL catchFatalError;

@property (nonatomic, copy) NSString *probeName;

@property (nonatomic,   weak, nullable) id caller;
@property (nonatomic, strong, nullable) id completionHandler; // block with none or one params

- (void)callOnce:(__nullable id)result;

+ (instancetype)probeWithSelector:(SEL)selector;

@end

NS_ASSUME_NONNULL_END
