//
//  NSData+BDXSource.h
//  BDXResourceLoader-Pods-Aweme
//
//  Created by bill on 2021/3/4.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSData (BDXSource)

// 类型参考BDHybridMonitor.h中BDHM_ResourceStatus定义,如果没有，则为NSIntegerMax
@property(nonatomic, assign) NSInteger bdx_SourceFrom;

@property(nonatomic, strong) NSString *bdx_SourceFromString;

// 资源的url
@property(nonatomic, strong) NSString *bdx_SourceUrl;

@end

NS_ASSUME_NONNULL_END
