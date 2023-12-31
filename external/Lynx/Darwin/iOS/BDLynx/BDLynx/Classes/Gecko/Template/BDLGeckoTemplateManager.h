//
//  BDLGeckoTemplateManager.h
//  BDLynx
//
//  Created by zys on 2020/2/9.
//

#import <Foundation/Foundation.h>
#import "BDLTemplateProtocol.h"
NS_ASSUME_NONNULL_BEGIN

@interface BDLGeckoTemplateManager : NSObject <BDLTemplateProtocol>

+ (instancetype)sharedInstance;
- (void)gurdDataUpdate:(NSString *)channel succeed:(BOOL)succeed;

@end

NS_ASSUME_NONNULL_END
