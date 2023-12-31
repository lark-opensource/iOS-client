//
//  TSPKLock.h
//  TSPrivacyKit
//
//  Created by PengYan on 2020/7/30.
//

#import <Foundation/Foundation.h>



@protocol TSPKLock <NSObject>

- (void)lock;
- (void)unlock;

@end

@interface TSPKLockFactory : NSObject

+ (id<TSPKLock> _Nullable)getLock;

@end


