//
//  CJPayNetworkErrorContext.h
//  Aweme
//
//  Created by shanghuaijun on 2023/3/9.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CJPayNetworkErrorContext : NSObject

@property (nonatomic, strong, nullable) NSError *error;
@property (nonatomic, copy) NSString *urlStr;
@property (nonatomic, copy) NSString *scene;

@end

NS_ASSUME_NONNULL_END
