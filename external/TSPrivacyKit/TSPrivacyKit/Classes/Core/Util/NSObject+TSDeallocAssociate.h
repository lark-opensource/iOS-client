//
//  NSObject+TSDeallocAssociate.h
//  TSPrivacyKit
//
//  Created by PengYan on 2020/7/13.
//

#import <Foundation/Foundation.h>
#import "TSDeallocAssociate.h"



@interface NSObject (TSDeallocAssociate)

- (NSString *_Nullable)ts_hashTag;

- (void)ts_addDeallocAction:(TSDeallocBlock _Nullable)block withKey:(NSString *_Nullable)key;

@end


