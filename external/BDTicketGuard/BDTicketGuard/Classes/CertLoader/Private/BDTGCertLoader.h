//
//  BDTGCertLoader.h
//  BDTicketGuard
//
//  Created by ByteDance on 2022/12/23.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


@interface BDTGCertLoader : NSObject

+ (void)preloadCert;

+ (void)loadCertWithCompletion:(void (^)(NSError *))completion;

@end

NS_ASSUME_NONNULL_END
