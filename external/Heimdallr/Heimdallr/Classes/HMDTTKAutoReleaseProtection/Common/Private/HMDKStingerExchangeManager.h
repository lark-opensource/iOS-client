//
//  HMDKStingerExchangeManager.h
//  Indexer
//
//  Created by Martin Lyu on 2022/3/14.
//

#import <Foundation/Foundation.h>

@protocol StingerParams;

typedef void(^HMDStingerExchangeBodyBlock)(id<StingerParams> _Nonnull params, void * _Nullable rst);

NS_ASSUME_NONNULL_BEGIN

@interface HMDKStingerExchangeManager : NSObject

+ (instancetype)sharedInstance;

- (BOOL)exchangeMethod:(NSString *)methodString block:(HMDStingerExchangeBodyBlock)bodyBlock;

@end

NS_ASSUME_NONNULL_END
