//
//  NSArray+CJPay.h
//  CJPay
//
//  Created by jiangzhongping on 2018/8/19.
//

#import <Foundation/Foundation.h>

@interface NSArray<ObjectType> (CJPay)

- (ObjectType)cj_objectAtIndex:(NSInteger)index;

- (NSArray<ObjectType> *)cj_subarrayWithRange:(NSRange)range;

@end
