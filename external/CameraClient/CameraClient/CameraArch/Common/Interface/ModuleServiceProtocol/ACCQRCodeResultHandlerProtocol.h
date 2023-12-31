//
//  ACCQRCodeResultHandlerProtocol.h
//  Indexer
//
//  Created by xiafeiyu on 11/9/21.
//

#import <Foundation/Foundation.h>

#import <CreativeKit/ACCServiceLocator.h>

@protocol ACCQRCodeResultHandlerProtocol <NSObject>

- (void)handleScanResult:(nullable NSString *)result isShapedType:(BOOL)isShapedType enterFrom:(NSString *)enterFrom URLProcessBlock:(NSURL * _Nullable (^ _Nullable)(NSURL *))URLProcessBlock completion:(dispatch_block_t)completion;

@end
