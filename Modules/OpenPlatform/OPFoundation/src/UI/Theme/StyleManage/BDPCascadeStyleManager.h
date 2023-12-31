//
//  BDPCascadeStyleManager.h
//  Timor
//
//  Created by 刘相鑫 on 2019/10/11.
//

#import <Foundation/Foundation.h>

@class BDPCascadeStyleNode;

NS_ASSUME_NONNULL_BEGIN

@interface BDPCascadeStyleManager : NSObject

+ (instancetype)sharedManager;
- (BDPCascadeStyleNode *)styleNodeForClass:(Class)cls
                                  category:(NSString *)category;
- (void)applyStyleForObject:(NSObject *)obj category:(NSString *)category;

@end

NS_ASSUME_NONNULL_END
