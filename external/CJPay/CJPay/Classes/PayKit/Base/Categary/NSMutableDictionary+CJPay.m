//
//  NSMutableDictionary+CJExtension.m
//  CJPay
//
//  Created by 王新华 on 8/9/19.
//

#import "NSMutableDictionary+CJPay.h"
#import "NSDictionary+CJPay.h"
#import <objc/runtime.h>

@implementation NSMutableDictionary(CJPay)

- (void)cj_setObject:(id) object forKey:(NSString *)key {
    if (object == nil) {
        return;
    }
    [self setValue:object forKey:key];
}

- (void)cj_fill:(id) object WhenNotExistForKey:(NSString *)key {
    if (![self cj_objectForKey:key] && object != nil) {
        [self setValue:object forKey:key];
    }
}

- (void)cj_setValue:(id _Nullable)value forKeyPath:(NSString *)keypath {
    const void *associatedKey = &self;
    NSMutableDictionary *isMutableDic = objc_getAssociatedObject(self,associatedKey);
    if(isMutableDic == nil) {
        isMutableDic = [[NSMutableDictionary alloc]init];
        objc_setAssociatedObject(self,associatedKey,isMutableDic,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    NSArray *keypaths = [keypath componentsSeparatedByString:@"."];
    NSString *lastKeyPath;
    
    for (int i = 0; i<= (NSInteger)keypaths.count - 1; i++) {
        NSString *path = [self pathInline:keypaths preCount:i];
        id pathValue = [self valueForKeyPath:path];
        id isMutable = [isMutableDic valueForKey:path];
        
        if (isMutable == nil){
            if ([pathValue isKindOfClass:NSDictionary.class]) {
                [self setValue:[NSMutableDictionary dictionaryWithDictionary:pathValue] forKeyPath:path];
                [isMutableDic setValue:[NSMutableDictionary new] forKeyPath:path];
            } else if ([pathValue isKindOfClass:NSString.class]) {
                [self setValue:[NSMutableString stringWithString:pathValue] forKeyPath:path];
                [isMutableDic setValue:@1 forKeyPath:path];
            } else if (!pathValue) {
                NSMutableDictionary *dic = [NSMutableDictionary new];
                [[self valueForKeyPath:lastKeyPath] cj_setObject:dic forKey:keypaths[i]];
                [isMutableDic setValue:[NSMutableDictionary new] forKeyPath:path];
            }
        }
        lastKeyPath = path;
    }
    [self setValue:value forKeyPath:keypath];
}


- (NSString *)pathInline:(NSArray *)paths preCount:(int) preCount {
    NSMutableString *mutablePath = [NSMutableString new];
    for (int i = 0; i <= preCount && i < paths.count; i++) {
        [mutablePath appendString:paths[i]];
        [mutablePath appendString:@"."];
    }
    if ([mutablePath hasSuffix:@"."]) {
        return [mutablePath substringToIndex:mutablePath.length - 1];
    } else {
        return mutablePath;
    }
}


@end
