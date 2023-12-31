//
//  BDSettings.h
//  Lynx
//
//  Created by admin on 2020/10/21.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDSettings : NSObject
+ (instancetype _Nonnull)shareInstance;
- (void)initSettings;
- (void)syncSettings;
@end

NS_ASSUME_NONNULL_END
