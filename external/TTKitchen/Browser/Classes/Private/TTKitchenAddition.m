//
//  TTKitchenAddition.m
//  Pods
//
//  Created by SongChai on 2018/4/18.
//

#import "TTKitchenAddition.h"
#import "TTKitchenInternal.h"

@implementation TTKitchenModel (BrowserAddition)

- (BOOL)isSwitchOpen {
    if (self.type == TTKitchenModelTypeBOOL) {
        return [TTKitchen getBOOL:self.key];
    }
    return NO;
}

- (NSString *)text {
    if (self.type == TTKitchenModelTypeFloat) {
        return [NSString stringWithFormat:@"%.f", [TTKitchen getFloat:self.key]];
    } else if (self.type == TTKitchenModelTypeString) {
        return [TTKitchen getString:self.key];
    } else if (self.type & TTKitchenModelTypeDictionary) {
        NSDictionary *dict = [TTKitchen getDictionary:self.key];
        if (dict) {
            if (![NSJSONSerialization isValidJSONObject:dict]) {
                return [dict description];
            }
            NSError *parseError = nil;
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:&parseError];
            if (jsonData && parseError == nil) {
                NSString *result = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                if (result) {
                    return result;
                }
            }
        }
    } else if (self.type & TTKitchenModelTypeArray) {
        NSArray *array = [TTKitchen getArray:self.key];
        if (array) {
            if (![NSJSONSerialization isValidJSONObject:array]) {
                return [array description];
            }
            NSError *parseError = nil;
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:array options:NSJSONWritingPrettyPrinted error:&parseError];
            if (jsonData && parseError == nil) {
                NSString *result = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                if (result) {
                    return result;
                }
            }
        }
    }
    
    return @"";
}

- (void)textFieldAction:(NSString *)text error:(NSError **)error {
    if (self.type == TTKitchenModelTypeString) {
        [TTKitchen setString:text forKey:self.key];
        self.freezedValue = text;
    }
    
    if (self.type == TTKitchenModelTypeFloat) {
        [TTKitchen setFloat:text.doubleValue forKey:self.key];
        self.freezedValue = @(text.doubleValue);
    }
    
    if (self.type & TTKitchenModelTypeDictionary ||
        self.type & TTKitchenModelTypeArray) {
        text = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        NSError *jsonError;
        id value = [NSJSONSerialization JSONObjectWithData:[text dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingAllowFragments error:&jsonError];
        
        if (jsonError) {
            *error = [NSError errorWithDomain:@"不符合JSON规范" code:jsonError.code userInfo:jsonError.userInfo];
            return;
        }
        
        if (self.type & TTKitchenModelTypeDictionary) {
            if ([value isKindOfClass:[NSDictionary class]]) {
                [TTKitchen setDictionary:value forKey:self.key];
                self.freezedValue = value;
            } else {
                *error = [NSError errorWithDomain:@"不是字典" code:0 userInfo:nil];
            }
        } else if (self.type & TTKitchenModelTypeArray) {
            if ([value isKindOfClass:[NSArray class]]) {
                [TTKitchen setArray:value forKey:self.key];
                self.freezedValue = value;
            } else {
                *error = [NSError errorWithDomain:@"不是数组" code:0 userInfo:nil];
            }
        }
    }
    
}

- (void)switchAction {
    if (self.type == TTKitchenModelTypeBOOL) {
        BOOL current = [TTKitchen getBOOL:self.key];
        [TTKitchen setBOOL:!current forKey:self.key];
        self.freezedValue = @(!current); //通过TTKitchenBrowserViewController可以修改freezed的值
    }
}

@end
