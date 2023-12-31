//
//  TSDeallocAssociate.h
//  TSPrivacyKit
//
//  Created by PengYan on 2020/7/13.
//

#import <Foundation/Foundation.h>



typedef void (^TSDeallocBlock)(void);

@interface TSDeallocAssociate : NSObject

- (instancetype _Nullable)initWithBlock:(TSDeallocBlock _Nullable)block;

@end


