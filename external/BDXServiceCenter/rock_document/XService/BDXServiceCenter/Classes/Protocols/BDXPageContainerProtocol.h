//
//  BDXPageContainerProtocol.h
//  BDXServiceCenter
//
//  Created by bill on 2021/3/15.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "BDXServiceProtocol.h"
#import "BDXContainerProtocol.h"
#import "BDXKitProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@class BDXContext;
@class BDXSchemaParam;
@protocol BDXPageSchemaParamProtocol;

@protocol BDXPageContainerProtocol <BDXContainerProtocol>

- (BOOL)close:(nullable NSDictionary *)params;
- (BOOL)close:(nullable NSDictionary *)params completion:(nullable dispatch_block_t)completion;

@end

@protocol BDXPageContainerServiceProtocol <BDXServiceProtocol>

- (nullable id<BDXPageContainerProtocol>)create:(NSString *_Nonnull)url context:(nullable BDXContext *)context;
- (nullable id<BDXPageContainerProtocol>)open:(NSString *_Nonnull)url context:(nullable BDXContext *)context;

@end


@protocol BDXNavigationBarProtocol <NSObject>

@property (nonatomic, weak) UIViewController<BDXPageContainerProtocol> *container;

- (void)updateTitle:(NSString *)title;
/// 在容器的viewDidLoad的时候调用
/// @param params 从URL中解析到的参数，自定义的参数可以从params.extra中获取
- (void)attachToContainerWithParams:(BDXSchemaParam<BDXPageSchemaParamProtocol>*)params;

@end

NS_ASSUME_NONNULL_END
