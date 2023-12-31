//
//  ACCServiceBinding.h
//  CreativeKit-Pods-Aweme
//
//  Created by Liu Deping on 2021/1/8.
//

#import <Foundation/Foundation.h>

@class ACCServiceBinding;

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT ACCServiceBinding *ACCCreateServiceBinding(Protocol *serviceProtocol, id serviceImpl);
FOUNDATION_EXPORT ACCServiceBinding *ACCCreateMutipleServiceBinding(NSArray<Protocol *> *serviceProtocols, id serviceImpl);

@interface ACCServiceBinding : NSObject

@property (nonatomic, strong, readonly) Protocol *serciceProtocol;
@property (nonatomic, strong, readonly) NSArray<Protocol *> *serciceProtocols;

@property (nonatomic, strong, readonly) id serviceImpl;

@end

NS_ASSUME_NONNULL_END

