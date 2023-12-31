//
//  TTKitchenJSONModelizer.m
//  BDAssert
//
//  Created by 李琢鹏 on 2019/5/27.
//

#import "TTKitchenJSONModelizer.h"
#import <JSONModel/JSONModelClassProperty.h>

@implementation TTKitchenJSONModelizer

+ (void)load {
    [TTKitchenManager setModelizer:self];
}

+ (id)modelWithDictionary:(NSDictionary *)dictionary modelClass:(Class)modelClass error:(NSError **)error {
    return [[modelClass alloc] initWithDictionary:dictionary error:error];
}

@end

@interface JSONModel ()

-(id)__transform:(id)value forProperty:(JSONModelClassProperty*)property error:(NSError**)err;

@end

@implementation TTKitchenJSONModel

-(BOOL)__isJSONModelSubClass:(Class)class
{
    // http://stackoverflow.com/questions/19883472/objc-nsobject-issubclassofclass-gives-incorrect-failure
#ifdef UNIT_TESTING
    return [@"JSONModel" isEqualToString: NSStringFromClass([class superclass])];
#else
    return [class isSubclassOfClass:JSONModel.class];
#endif
}

-(id)__transform:(id)value forProperty:(JSONModelClassProperty*)property error:(NSError**)err {
    Class protocolClass = NSClassFromString(property.protocol);
    if (!protocolClass) {
        if ([value isKindOfClass:[NSArray class]]) {
            @throw [NSException exceptionWithName:@"Bad property protocol declaration"
                                           reason:[NSString stringWithFormat:@"<%@> is not allowed JSONModel property protocol, and not a JSONModel class.", property.protocol]
                                         userInfo:nil];
        }
        return value;
    }
    
    BOOL isJSONModelSubClass = [self __isJSONModelSubClass:protocolClass];
    if (!isJSONModelSubClass) {
        if ([property.type isSubclassOfClass:[NSArray class]]) {
            
            // Expecting an array, make sure 'value' is an array
            if(![[value class] isSubclassOfClass:[NSArray class]])
            {
                if(err != nil)
                {
                    NSString* mismatch = [NSString stringWithFormat:@"Property '%@' is declared as NSArray<%@>* but the corresponding JSON value is not a JSON Array.", property.name, property.protocol];
                    JSONModelError* typeErr = [JSONModelError errorInvalidDataWithTypeMismatch:mismatch];
                    *err = [typeErr errorByPrependingKeyPathComponent:property.name];
                }
                return nil;
            }
            
            NSMutableArray* list = [NSMutableArray arrayWithCapacity:[value count]];
            for (id d in value) {
                if ([d isKindOfClass:protocolClass]) {
                    [list addObject:d];
                }
            }
            return list.copy;
        }
    }
    else {
        return [super __transform:value forProperty:property error:err];
    }
    return value;
}


@end
