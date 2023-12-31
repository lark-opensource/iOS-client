//
//  BGTool.m
//  BGDB
//
//  Created by huangzhibiao on 17/2/16.
//  Copyright © 2017年 Biao. All rights reserved.
//

#include <objc/message.h>
#include <objc/runtime.h>
#import <UIKit/UIKit.h>
#import "HMDALogProtocol.h"
#import "HMDBGToolCustomization.h"
#import "HMDBGTool.h"
#import "HMDBGDB.h"
#import "NSCache+HMDBGCache.h"
#import "NSArray+HMDSafe.h"
#import "HMDMacro.h"

#define SqlText @"text" //数据库的字符类型
#define SqlReal @"real" //数据库的浮点类型
#define SqlInteger @"integer" //数据库的整数类型
#define SqlBlob @"blob" //数据库的二进制类型

#define BGValue @"BGValue"
#define BGData @"BGData"
#define BGArray @"BGArray"
#define BGSet @"BGSet"
#define BGDictionary @"BGDictionary"
#define BGModel @"BGModel"
#define BGMapTable @"BGMapTable"
#define BGHashTable @"BGHashTable"

#define bg_typeHead_NS @"@\"NS"
#define bg_typeHead__NS @"@\"__NS"

#define bg_typeHead_UI @"@\"UI"
#define bg_typeHead__UI @"@\"__UI"
#import "HMDRecordStoreObject.h"

//100M大小限制.
#define MaxData @(838860800)

/**
 *  遍历所有类的block（父类）
 */
typedef void (^BGClassesEnumeration)(Class c, BOOL *stop);
static NSSet *foundationClasses_;

@implementation HMDBGTool
/**
 封装处理传入数据库的key和value.
 */
NSString* hmdbg_sqlKey(NSString* key){
    return key;
}

/**
 转换OC对象成数据库数据.
 */
NSString* hmdbg_sqlValue(id value){
    
    if([value isKindOfClass:[NSNumber class]]) {
        return value;
    }else if([value isKindOfClass:[NSString class]]){
        return [NSString stringWithFormat:@"'%@'",value];
    }else{
        NSString* type = [NSString stringWithFormat:@"@\"%@\"",NSStringFromClass([value class])];
        value = [HMDBGTool getSqlValue:value type:type encode:YES];
        if ([value isKindOfClass:[NSString class]]) {
            return [NSString stringWithFormat:@"'%@'",value];
        }else{
            return value;
        }
    }
}

/**
 根据keyPath和Value的数组, 封装成数据库语句，来操作库.
 */
NSString* hmdbg_keyPathValues(NSArray* keyPathValues){
    return [HMDBGTool getLikeWithKeyPathAndValues:keyPathValues where:NO];
}

/**
 清除缓存
 */

void hmdbg_cleanCache(void){
    [[NSCache hmdbg_cache] removeAllObjects];
}
/**
 json字符转json格式数据 .
 */
+(id)jsonWithString:(NSString*)jsonString {
    NSAssert(jsonString,@"Data can not be nil!");
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSError *err;
    
    if (!jsonData) return nil;
    
    id dic = [NSJSONSerialization JSONObjectWithData:jsonData
                                             options:NSJSONReadingMutableContainers
                                               error:&err];
    
    NSAssert(!err,@"Analyzed Json Failed!");
    return dic;
}
/**
 字典转json字符 .
 */
+(NSString*)dataToJson:(id)data{
    NSAssert(data,@"Data can not be nil!");
    NSError *parseError = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:data options:NSJSONWritingPrettyPrinted error:&parseError];
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

+ (NSSet *)foundationClasses
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // 集合中没有NSObject，因为几乎所有的类都是继承自NSObject，具体是不是NSObject需要特殊判断
        foundationClasses_ = [NSSet setWithObjects:
                              [NSURL class],
                              [NSDate class],
                              [NSValue class],
                              [NSData class],
                              [NSError class],
                              [NSArray class],
                              [NSDictionary class],
                              [NSString class],
                              [NSAttributedString class], nil];
    });
    return foundationClasses_;
}

+ (void)bg_enumerateClasses:(__unsafe_unretained Class)srcCla complete:(BGClassesEnumeration)enumeration
{
    // 1.没有block就直接返回
    if (enumeration == nil) return;
    // 2.停止遍历的标记
    BOOL stop = NO;
    // 3.当前正在遍历的类
    Class c = srcCla;
    // 4.开始遍历每一个类
    while (c && !stop) {
        // 4.1.执行操作
        enumeration(c, &stop);
        // 4.2.获得父类
        c = class_getSuperclass(c);
        if ([self isClassFromFoundation:c]) break;
    }
}

+ (BOOL)isClassFromFoundation:(Class)c
{
    if (c == [NSObject class] || c == NSClassFromString(@"NSManagedObject")) return YES;
    __block BOOL result = NO;
    [[self foundationClasses] enumerateObjectsUsingBlock:^(Class foundationClass, BOOL *stop) {
        if ([c isSubclassOfClass:foundationClass]) {
            result = YES;
            *stop = YES;
        }
    }];
    return result;
}

+ (NSString * _Nullable)getIvarEncoding:(NSString * _Nonnull)ivarName class:(Class _Nonnull)aClass {
    if(ivarName == nil || aClass == nil) return nil;
    if([aClass respondsToSelector:@selector(HMD_BGTool_overrideIvarTypeForIvarNameWithoutPrefixUnderscore:)]) {
        NSString *key = ivarName;
        if([key hasPrefix:@"_"]) key = [ivarName substringFromIndex:1];
        NSString *temp = [aClass HMD_BGTool_overrideIvarTypeForIvarNameWithoutPrefixUnderscore:key];
        if(temp != nil) return temp;
    }
    Ivar ivar = class_getInstanceVariable(aClass, ivarName.UTF8String);
    if(ivar == NULL) {
        DEBUG_POINT
        return nil;
    }
    const char *encodeType = ivar_getTypeEncoding(ivar);
    if(encodeType == NULL) {
        DEBUG_POINT
        return nil;
    }
    return [NSString stringWithUTF8String:encodeType];
}

/**
 根据类获取变量名列表
 @onlyKey YES:紧紧返回key,NO:在key后面添加type.
 */
+(NSArray*)getClassIvarList:(__unsafe_unretained Class)cla onlyKey:(BOOL)onlyKey{
    //获取缓存的属性信息
    NSCache* cache = [NSCache hmdbg_cache];
    NSString* cacheKey;
    cacheKey = onlyKey?[NSString stringWithFormat:@"%@_IvarList_yes",NSStringFromClass(cla)]:[NSString stringWithFormat:@"%@_IvarList_no",NSStringFromClass(cla)];
    NSArray* cachekeys = [cache objectForKey:cacheKey];
    if(cachekeys){
        return cachekeys;
    }
    
    NSMutableArray* keys = [NSMutableArray array];
    //    if(onlyKey){
    //        [keys addObject:hmdbg_primaryKey];
    //    }else{
    //        //手动添加库自带的自动增长主键ID和类型q
    //        [keys addObject:[NSString stringWithFormat:@"%@*q",hmdbg_primaryKey]];
    //    }
    
    [self bg_enumerateClasses:cla complete:^(__unsafe_unretained Class c, BOOL *stop) {
        unsigned int numIvars = 0; //成员变量个数
        Ivar *vars = class_copyIvarList(c, &numIvars);
        NSMutableArray* ivarKeys = [NSMutableArray arrayWithCapacity:numIvars];
        for(int i = 0; i < numIvars; i++) {
            @autoreleasepool {
                Ivar thisIvar = vars[i];
                NSString* key = [NSString stringWithUTF8String:ivar_getName(thisIvar)];//获取成员变量的名
                if ([key hasPrefix:@"_"]) {
                    key = [key substringFromIndex:1];
                }
                if (!onlyKey) {
                    //获取成员变量的数据类型
                    NSString* type = [NSString stringWithUTF8String:ivar_getTypeEncoding(thisIvar)];
                    if([cla respondsToSelector:@selector(HMD_BGTool_overrideIvarTypeForIvarNameWithoutPrefixUnderscore:)]) {
                        NSString *temp = [cla HMD_BGTool_overrideIvarTypeForIvarNameWithoutPrefixUnderscore:key];
                        if(temp != nil) type = temp;
                    }
                    key = [NSString stringWithFormat:@"%@*%@",key,type];
                }
                [ivarKeys hmd_addObject:key];//存储对象的变量名
            }
        }
        //保证父类的在前
        NSRange range = NSMakeRange(0, [ivarKeys count]);
        NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:range];
        [keys insertObjects:ivarKeys atIndexes:indexSet];
        free(vars);//释放资源
    }];
    
    [cache setObject:keys forKey:cacheKey];
    
    return keys;
}

/**
 抽取封装条件数组处理函数
 */
+(NSArray*)where:(NSArray*)where{
    NSMutableArray* results = [NSMutableArray array];
    NSMutableString* SQL = [NSMutableString string];
    if(!(where.count%3)){
        [SQL appendString:@" where "];
        for(int i=0;i<where.count;i+=3){
            [SQL appendFormat:@"%@%@?",where[i],where[i+1]];
            if (i != (where.count-3)) {
                [SQL appendString:@" and "];
            }
        }
    }else{
        //NSLog(@"条件数组错误!");
        NSAssert(NO,@"Conditional array error!");
    }
    NSMutableArray* wheres = [NSMutableArray array];
    for(int i=0;i<where.count;i+=3){
        [wheres addObject:where[i+2]];
    }
    [results addObject:SQL];
    [results addObject:wheres];
    return results;
}
/**
 封装like语句获取函数
 */
+(NSString*)getLikeWithKeyPathAndValues:(NSArray* _Nonnull)keyPathValues where:(BOOL)where{
    NSAssert(keyPathValues,@"KeyPathValues cannot be nil!");
    NSAssert(!(keyPathValues.count%3),@"The format of keyPathValues is wrong");
    NSMutableArray* keys = [NSMutableArray array];
    NSMutableArray* values = [NSMutableArray array];
    NSMutableArray* relations = [NSMutableArray array];
    for(int i=0;i<keyPathValues.count;i+=3){
        [keys addObject:keyPathValues[i]];
        [relations addObject:keyPathValues[i+1]];
        [values addObject:keyPathValues[i+2]];
    }
    NSMutableString* likeM = [NSMutableString string];
    !where?:[likeM appendString:@" where "];
    NSInteger keysCount = keys.count;
    for(int i=0;i<keysCount;i++){
        @autoreleasepool {
            BOOL likeOr = NO;
            NSString* keyPath = keys[i];
            id value = values[i];
            NSAssert([keyPath containsString:@"."], @"keyPath is wrong! Correct format should be like 'user.stident.name'.");
            NSArray* keypaths = [keyPath componentsSeparatedByString:@"."];
            NSMutableString* keyPathParam = [NSMutableString string];
            for(int i=1;i<keypaths.count;i++){
                i!=1?:[keyPathParam appendString:@"%"];
                [keyPathParam appendFormat:@"%@",keypaths[i]];
                [keyPathParam appendString:@"%"];
            }
            //[keyPathParam appendFormat:@"%@",value];
            if ([relations[i] isEqualToString:hmdbg_contains]){//包含关系
                if(![value isKindOfClass:[NSString class]]){
                    NSAssert(NO, @"The classes that are not inheriting NSString can not set hmdbg_contains!");
                }
                [keyPathParam appendFormat:@"%@",value];
                [keyPathParam appendString:@"%"];
            }else{
                
                if([value isKindOfClass:[NSString class]]){
                    [keyPathParam appendFormat:@"\"%@",value];
                }else{
                    [keyPathParam appendFormat:@": %@",value];
                }

                if([value isKindOfClass:[NSString class]]){
                    [keyPathParam appendString:@"\\%"];
                }else{
                    [keyPathParam appendString:@",%"];
                    likeOr = YES;
                }
            }
            if(likeOr){
                if(keypaths.count<=2){
                    [likeM appendFormat:@"((%@ like '%@') or (%@ like '%@'))",keypaths[0],keyPathParam,keypaths[0],[keyPathParam stringByReplacingOccurrencesOfString:@"," withString:@"\n}"]];
                }else{
                    [likeM appendFormat:@"((%@ like '%@') or (%@ like '%@'))",keypaths[0],keyPathParam,keypaths[0],[keyPathParam stringByReplacingOccurrencesOfString:@"," withString:@"\\"]];
                }
            }else{
                [likeM appendFormat:@"%@ like '%@'",keypaths[0],keyPathParam];
            }
            if(i != (keys.count-1)){
                [likeM appendString:@" and "];
            }
        }
    }
    return likeM;
}

/**
 判断是不是 "唯一约束" 字段.
 */
+(BOOL)isUniqueKey:(NSString*)uniqueKey with:(NSString*)param{
    NSArray* array = [param componentsSeparatedByString:@"*"];
    NSString* key = array[0];
    return [uniqueKey isEqualToString:key];
}
/**
 判断并获取字段类型
 */
+(NSString*)keyAndType:(NSString*)param{
    NSArray* array = [param componentsSeparatedByString:@"*"];
    NSString* key = array[0];
    NSString* type = array[1];
    NSString* SqlType;
    type = [self getSqlType:type];
    if ([SqlText isEqualToString:type]) {
        SqlType = SqlText;
    }else if ([SqlReal isEqualToString:type]){
        SqlType = SqlReal;
    }else if ([SqlInteger isEqualToString:type]){
        SqlType = SqlInteger;
    }else if ([SqlBlob isEqualToString:type]){
        SqlType = SqlBlob;
    }else{
        NSAssert(NO,@" Can not find a matched type!");
    }
    return [NSString stringWithFormat:@"%@ %@",key,SqlType];
}

+(NSString*)getSqlType:(NSString*)type{
    if([type isEqualToString:@"i"]||[type isEqualToString:@"I"]||
             [type isEqualToString:@"s"]||[type isEqualToString:@"S"]||
             [type isEqualToString:@"q"]||[type isEqualToString:@"Q"]||
             [type isEqualToString:@"b"]||[type isEqualToString:@"B"]||
             [type isEqualToString:@"c"]||[type isEqualToString:@"C"]|
             [type isEqualToString:@"l"]||[type isEqualToString:@"L"]) {
        return SqlInteger;
    }else if([type isEqualToString:@"f"]||[type isEqualToString:@"F"]||
             [type isEqualToString:@"d"]||[type isEqualToString:@"D"]){
        return SqlReal;
    }
    else if([type isEqualToString:@"@\"NSDictionary\""]||[type isEqualToString:@"@\"NSMutableDictionary\""]||
            [type isEqualToString:@"@\"NSArray\""]||[type isEqualToString:@"@\"NSMutableArray\""]){
        return SqlBlob;
    }
    else{
        return SqlText;
    }
}
//对象转json字符
+(NSString *)jsonStringWithObject:(id)object{
    NSMutableDictionary* keyValueDict = [NSMutableDictionary dictionary];
    NSArray* keyAndTypes = [HMDBGTool getClassIvarList:[object class] onlyKey:NO];
    //忽略属性
    NSArray* ignoreKeys = [HMDBGTool executeSelector:hmdbg_ignoreKeysSelector forClass:[object class]];
    for(NSString* keyAndType in keyAndTypes){
        @autoreleasepool {
            NSArray* arr = [keyAndType componentsSeparatedByString:@"*"];
            NSString* propertyName = arr[0];
            NSString* propertyType = arr[1];
            
            if([ignoreKeys containsObject:propertyName])continue;
            
            if(![propertyName isEqualToString:hmdbg_primaryKey]){
                id propertyValue = [object valueForKey:propertyName];
                if (propertyValue){
                    id Value = [self getSqlValue:propertyValue type:propertyType encode:YES];
                    keyValueDict[propertyName] = Value;
                }
            }
        }
    }
    return [self dataToJson:keyValueDict];
}
//根据value类型返回用于数组插入数据库的NSDictionary
+(NSDictionary*)dictionaryForArrayInsert:(id)value{
    
    if ([value isKindOfClass:[NSArray class]]){
        return @{BGArray:[self jsonStringWithArray:value]};
    }else if ([value isKindOfClass:[NSSet class]]){
        return @{BGSet:[self jsonStringWithArray:value]};
    }else if ([value isKindOfClass:[NSString class]] || [value isKindOfClass:[NSNumber class]]){
        return @{BGValue:value};
    }else if([value isKindOfClass:[NSData class]]){
        NSData* data = value;
        NSAssert(data.length<MaxData.integerValue,@"The upper limit of the storage is 100M");
        return @{BGData:[data base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength]};
    }else if ([value isKindOfClass:[NSDictionary class]]){
        return @{BGDictionary:[self jsonStringWithDictionary:value]};
    }else if ([value isKindOfClass:[NSMapTable class]]){
        return @{BGMapTable:[self jsonStringWithMapTable:value]};
    }else if([value isKindOfClass:[NSHashTable class]]){
        return @{BGHashTable:[self jsonStringWithNSHashTable:value]};
    }else{
        NSString* modelKey = [NSString stringWithFormat:@"%@*%@",BGModel,NSStringFromClass([value class])];
        return @{modelKey:[self jsonStringWithObject:value]};
    }
    
}
//NSArray,NSSet转json字符
+(NSString*)jsonStringWithArray:(id)array{
    if ([NSJSONSerialization isValidJSONObject:array]) {
        return [self dataToJson:array];
    }else{
        NSMutableArray* arrM = [NSMutableArray array];
        for(id value in array){
            [arrM addObject:[self dictionaryForArrayInsert:value]];
        }
        return [self dataToJson:arrM];
    }
}

//根据value类型返回用于字典插入数据库的NSDictionary
+(NSDictionary*)dictionaryForDictionaryInsert:(id)value{
    if ([value isKindOfClass:[NSArray class]]){
        return @{BGArray:[self jsonStringWithArray:value]};
    }else if ([value isKindOfClass:[NSSet class]]){
        return @{BGSet:[self jsonStringWithArray:value]};
    }else if ([value isKindOfClass:[NSString class]] || [value isKindOfClass:[NSNumber class]]){
        return @{BGValue:value};
    }else if([value isKindOfClass:[NSData class]]){
        NSData* data = value;
        NSAssert(data.length<MaxData.integerValue,@"The upper limit of the storage is 100M");
        return @{BGData:[data base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength]};
    }else if ([value isKindOfClass:[NSDictionary class]]){
        return @{BGDictionary:[self jsonStringWithDictionary:value]};
    }else if ([value isKindOfClass:[NSMapTable class]]){
        return @{BGMapTable:[self jsonStringWithMapTable:value]};
    }else if ([value isKindOfClass:[NSHashTable class]]){
        return @{BGHashTable:[self jsonStringWithNSHashTable:value]};
    }else{
        NSString* modelKey = [NSString stringWithFormat:@"%@*%@",BGModel,NSStringFromClass([value class])];
        return @{modelKey:[self jsonStringWithObject:value]};
    }
}
//字典转json字符串.
+(NSString*)jsonStringWithDictionary:(NSDictionary*)dictionary{
    if ([NSJSONSerialization isValidJSONObject:dictionary]) {
        return [self dataToJson:dictionary];
    }else{
        NSMutableDictionary* dictM = [NSMutableDictionary dictionary];
        for(NSString* key in dictionary.allKeys){
            dictM[key] = [self dictionaryForDictionaryInsert:dictionary[key]];
        }
        return [self dataToJson:dictM];
    }

}
//NSMapTable转json字符串.
+(NSString*)jsonStringWithMapTable:(NSMapTable*)mapTable{
    NSMutableDictionary* dictM = [NSMutableDictionary dictionary];
    NSArray* objects = mapTable.objectEnumerator.allObjects;
    NSArray* keys = mapTable.keyEnumerator.allObjects;
    for(int i=0;i<objects.count;i++){
        NSString* key = keys[i];
        id object = objects[i];
        dictM[key] = [self dictionaryForDictionaryInsert:object];
    }
    return [self dataToJson:dictM];
}
//NSHashTable转json字符串.
+(NSString*)jsonStringWithNSHashTable:(NSHashTable*)hashTable{
    NSMutableArray* arrM = [NSMutableArray array];
    NSArray* values = hashTable.objectEnumerator.allObjects;
    for(id value in values){
        [arrM addObject:[self dictionaryForArrayInsert:value]];
    }
    return  [self dataToJson:arrM];
}
//NSDate转字符串,格式: yyyy-MM-dd HH:mm:ss
+(NSString*)stringWithDate:(NSDate*)date{
    NSDateFormatter* formatter = [NSDateFormatter new];
    formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss.SSS";
    return [formatter stringFromDate:date];
}
//跟value和数据类型type 和编解码标志 返回编码插入数据库的值,或解码数据库的值.
+(id)getSqlValue:(id)value type:(NSString*)type encode:(BOOL)encode{
    if(!value || [value isKindOfClass:[NSNull class]])return nil;
    
    @try {
        if(([type hasPrefix:bg_typeHead_NS]||[type hasPrefix:bg_typeHead__NS])&&[type containsString:@"String"]){
            if([type containsString:@"AttributedString"]){//处理富文本.
                if(encode) {
                    return [[NSKeyedArchiver archivedDataWithRootObject:value] base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
                }else{
                    NSData* data = [[NSData alloc] initWithBase64EncodedString:value options:NSDataBase64DecodingIgnoreUnknownCharacters];
                    return [NSKeyedUnarchiver unarchiveObjectWithData:data];
                }
            }else{
                return value;
            }
        }else if(([type hasPrefix:bg_typeHead_NS]||[type hasPrefix:bg_typeHead__NS])&&[type containsString:@"Number"]){
            if(encode) {
                return [NSString stringWithFormat:@"%@",value];
            }else{
                return [[NSNumberFormatter new] numberFromString:value];
            }
        }else if(([type hasPrefix:bg_typeHead_NS]||[type hasPrefix:bg_typeHead__NS])&&[type containsString:@"Array"]){
            if(encode){
                return [self jsonStringWithArray:value];
            }else{
                if ([value isKindOfClass:[NSData class]]) {
                    // encode性能优化，兼容旧版本数据
                    return [NSKeyedUnarchiver unarchiveObjectWithData:value];
                } else {
                    return [self arrayFromJsonString:value];
                }
            }
        }else if(([type hasPrefix:bg_typeHead_NS]||[type hasPrefix:bg_typeHead__NS])&&[type containsString:@"Dictionary"]){
            if(encode){
                return [self jsonStringWithDictionary:value];
            }else{
                if ([value isKindOfClass:[NSData class]]) {
                    // encode性能优化，兼容旧版本数据
                    return [NSKeyedUnarchiver unarchiveObjectWithData:value];
                } else {
                    return [self dictionaryFromJsonString:value];
                }
            }
        }else if(([type hasPrefix:bg_typeHead_NS]||[type hasPrefix:bg_typeHead__NS])&&[type containsString:@"Set"]){
            if(encode){
                return [self jsonStringWithArray:value];
            }else{
                return [self arrayFromJsonString:value];
            }
        }else if(([type hasPrefix:bg_typeHead_NS]||[type hasPrefix:bg_typeHead__NS])&&[type containsString:@"Data"]){
            if(encode){
                NSData* data = value;
                NSAssert(data.length<MaxData.integerValue,@"The upper limit of the storage is 100M");
                return [data base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
            }else{
                return [[NSData alloc] initWithBase64EncodedString:value options:NSDataBase64DecodingIgnoreUnknownCharacters];
            }
        }else if(([type hasPrefix:bg_typeHead_NS]||[type hasPrefix:bg_typeHead__NS])&&[type containsString:@"MapTable"]){
            if(encode){
                return [self jsonStringWithMapTable:value];
            }else{
                return [self mapTableFromJsonString:value];
            }
        }else if(([type hasPrefix:bg_typeHead_NS]||[type hasPrefix:bg_typeHead__NS])&&[type containsString:@"HashTable"]){
            if(encode){
                return [self jsonStringWithNSHashTable:value];
            }else{
                return [self hashTableFromJsonString:value];
            }
        }else if(([type hasPrefix:bg_typeHead_NS]||[type hasPrefix:bg_typeHead__NS])&&[type containsString:@"Date"]){
            if(encode){
                return [self stringWithDate:value];
            }else{
                return [self dateFromString:value];
            }
        }else if(([type hasPrefix:bg_typeHead_NS]||[type hasPrefix:bg_typeHead__NS])&&[type containsString:@"URL"]){
            if(encode){
                return [value absoluteString];
            }else{
                return [NSURL URLWithString:value];
            }
        }else if(([type hasPrefix:bg_typeHead_UI]||[type hasPrefix:bg_typeHead__UI])&&[type containsString:@"Image"]){
            if(encode){
                NSData* data = UIImageJPEGRepresentation(value, 1);
                NSAssert(data.length<MaxData.integerValue,@"The upper limit of the storage is 100M");
                return [data base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
            }else{
                return [UIImage imageWithData:[[NSData alloc] initWithBase64EncodedString:value options:NSDataBase64DecodingIgnoreUnknownCharacters]];
            }
        }else if(([type hasPrefix:bg_typeHead_UI]||[type hasPrefix:bg_typeHead__UI])&&[type containsString:@"Color"]){
            if(encode){
                CGFloat r, g, b, a;
                [value getRed:&r green:&g blue:&b alpha:&a];
                return [NSString stringWithFormat:@"%.3f,%.3f,%.3f,%.3f", r, g, b, a];
            }else{
                NSArray<NSString*>* arr = [value componentsSeparatedByString:@","];
                return [UIColor colorWithRed:arr[0].floatValue green:arr[1].floatValue blue:arr[2].floatValue alpha:arr[3].floatValue];
            }
        }else if ([type containsString:@"NSRange"]){
            if(encode){
                return NSStringFromRange([value rangeValue]);
            }else{
                return [NSValue valueWithRange:NSRangeFromString(value)];
            }
        }else if ([type containsString:@"CGRect"]&&[type containsString:@"CGPoint"]&&[type containsString:@"CGSize"]){
            if(encode){
                return NSStringFromCGRect([value CGRectValue]);
            }else{
                return [NSValue valueWithCGRect:CGRectFromString(value)];
            }
        }else if (![type containsString:@"CGRect"]&&[type containsString:@"CGPoint"]&&![type containsString:@"CGSize"]){
            if(encode){
                return NSStringFromCGPoint([value CGPointValue]);
            }else{
                return [NSValue valueWithCGPoint:CGPointFromString(value)];
            }
        }else if (![type containsString:@"CGRect"]&&![type containsString:@"CGPoint"]&&[type containsString:@"CGSize"]){
            if(encode){
                return NSStringFromCGSize([value CGSizeValue]);
            }else{
                return [NSValue valueWithCGSize:CGSizeFromString(value)];
            }
        }else if([type isEqualToString:@"i"]||[type isEqualToString:@"I"]||
                 [type isEqualToString:@"s"]||[type isEqualToString:@"S"]||
                 [type isEqualToString:@"q"]||[type isEqualToString:@"Q"]||
                 [type isEqualToString:@"b"]||[type isEqualToString:@"B"]||
                 [type isEqualToString:@"c"]||[type isEqualToString:@"C"]||
                 [type isEqualToString:@"l"]||[type isEqualToString:@"L"]){
            return value;
        }else if([type isEqualToString:@"f"]||[type isEqualToString:@"F"]||
                 [type isEqualToString:@"d"]||[type isEqualToString:@"D"]){
            return value;
        }else{
            
            if(encode){
                NSBundle *bundle = [NSBundle bundleForClass:[value class]];
                NSBundle *selfBundle = [NSBundle bundleForClass:[self class]];
                if(bundle == selfBundle){//自定义的类
                    return [self jsonStringWithArray:@[value]];
                }else{//特殊类型
                    return [[NSKeyedArchiver archivedDataWithRootObject:value] base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
                }
            }else{
                if([value containsString:BGModel]){//自定义的类
                    return [self arrayFromJsonString:value].firstObject;
                }else{//特殊类型
                    NSData* data = [[NSData alloc] initWithBase64EncodedString:value options:NSDataBase64DecodingIgnoreUnknownCharacters];
                    return [NSKeyedUnarchiver unarchiveObjectWithData:data];
                }
            }
        }
    } @catch (NSException *exception) {
        HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"[BGTool getSqlValue:%@ type:%@ encode:%s] failed with Exception (%@)  Maybe It's due to the failure analysis of dirty data in NSKeyedUnarchive.", value, type, encode?"YES":"NO", exception);
        return nil;
    } @finally {
    }
}

/**
 根据传入的对象获取表名.
 */
+(NSString *)getTableNameWithObject:(id)object{
    NSString* tablename;
    if([[object class] respondsToSelector:@selector(tableName)]) {
        tablename = [[object class] tableName];
    }
    
    if (!tablename) {
        tablename = NSStringFromClass([object class]);
    }
    
    return tablename;
}
/**
 存储转换用的字典转化成对象处理函数.
 */
+(id)objectFromJsonStringWithTableName:(NSString* _Nonnull)tablename class:(__unsafe_unretained _Nonnull Class)cla valueDict:(NSDictionary*)valueDict{
    id object = [cla new];
    NSMutableArray* valueDictKeys = [NSMutableArray arrayWithArray:valueDict.allKeys];
    NSMutableArray* keyAndTypes = [NSMutableArray arrayWithArray:[self getClassIvarList:cla onlyKey:NO]];
    
    for(int i=0;i<valueDictKeys.count;i++){
        @autoreleasepool {
            NSString* sqlKey = valueDictKeys[i];
            for(NSString* keyAndType in keyAndTypes){
                NSArray* arrKT = [keyAndType componentsSeparatedByString:@"*"];
                NSString* key = [arrKT firstObject];
                NSString* type = [arrKT lastObject];
                
                if ([sqlKey isEqualToString:key]){
                    id tempValue = valueDict[sqlKey];
                    id ivarValue = [self getSqlValue:tempValue type:type encode:NO];
                    @try {
                        !ivarValue?:[object setValue:ivarValue forKey:key];
                    } @catch (NSException *exception) {
                        id localID = [valueDict objectForKey:@"localID"];
                        HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr",
                                                  @"+ [BGTool objectFromJsonStringWithTableName:%@ "
                                                                                         "class:%@ "
                                                                                     "valueDict:%@] "
                                                  "tempValue %@ ivarValue %@ key:%@ type: %@ "
                                                   "Failed with reason: %@ "
                                                   "Try to clean up data at table %@ localID:%@",
                                                   tablename, cla, valueDict,
                                                   tempValue, ivarValue, key, type,
                                                   exception, tablename, localID);
                        if(localID && tablename && [localID isKindOfClass:NSNumber.class]) {
                            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
                                Class aClass = NSClassFromString(@"Heimdallr");
                                SEL aSEL = NSSelectorFromString(@"receiveDevastedDataForTableName:localID:");
                                if(aClass != nil && aSEL != NULL && [aClass respondsToSelector:aSEL])
                                    ((void (*)(id, SEL, NSString *, NSNumber *))objc_msgSend)(aClass, aSEL, tablename, localID);
                            });
                        }
                    } @finally {}
                    [keyAndTypes removeObject:keyAndType];
                    [valueDictKeys removeObjectAtIndex:i];
                    i--;
                    break;//匹配处理完后跳出内循环.
                }
                
            }
        }
    }
    
    return object;
}

/**
 字典或json格式字符转模型用的处理函数.
 */
+(id)bg_objectWithClass:(__unsafe_unretained _Nonnull Class)cla value:(id)value{
    if(value == nil)return nil;
    
    NSMutableDictionary* dataDict;
    id object = [cla new];
    if ([value isKindOfClass:[NSString class]]){
        NSAssert([NSJSONSerialization isValidJSONObject:value],@"The format of json data is wrong!");
        dataDict = [[NSMutableDictionary alloc] initWithDictionary:[self jsonWithString:value] copyItems:YES];
    }else if ([value isKindOfClass:[NSDictionary class]]){
        dataDict = [[NSMutableDictionary alloc] initWithDictionary:value copyItems:YES];
    }else{
        NSAssert(NO,@"Wrong data format! Only Nsdictionary or json data can be converted!");
    }
    NSDictionary* const objectClaInArr = [HMDBGTool executeSelector:NSSelectorFromString(@"bg_objectClassInArray") forClass:[object class]];
    NSDictionary* const objectClaForCustom = [HMDBGTool executeSelector:NSSelectorFromString(@"bg_objectClassForCustom") forClass:[object class]];
    NSDictionary* const bg_replacedKeyFromPropertyNameDict = [HMDBGTool executeSelector:NSSelectorFromString(@"bg_replacedKeyFromPropertyName") forClass:[object class]];
    NSArray* const claKeys = [self getClassIvarList:cla onlyKey:YES];
    //遍历自定义变量集合信息.
    !objectClaForCustom?:[objectClaForCustom enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull customKey, id  _Nonnull customObj, BOOL * _Nonnull stop) {
        if ([customKey containsString:@"."]){
            NSArray* keyPaths = [customKey componentsSeparatedByString:@"."];
            id value = [dataDict valueForKeyPath:customKey];
            dataDict[keyPaths.lastObject] = value;
            if(![objectClaForCustom.allKeys containsObject:keyPaths.firstObject]){
                [dataDict removeObjectForKey:keyPaths.firstObject];
            }
        }
    }];
    
    //处理要替换的key和属性名.
    if(bg_replacedKeyFromPropertyNameDict && bg_replacedKeyFromPropertyNameDict.count){
        [bg_replacedKeyFromPropertyNameDict enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            if([dataDict.allKeys containsObject:key]){
                dataDict[obj] = dataDict[key];
                [dataDict removeObjectForKey:key];
            }
        }];
    }
    
    [dataDict enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull dataDictObj, BOOL * _Nonnull stop) {
        for(NSString* claKey in claKeys){
            if ([key isEqualToString:claKey]){
                __block id ArrObject = dataDictObj;
                //遍历自定义变量数组集合信息.
                !objectClaInArr?:[objectClaInArr enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull Arrkey, id  _Nonnull ArrObjCla, BOOL * _Nonnull stop){
                    if([key isEqualToString:Arrkey]){
                        NSMutableArray* ArrObjects = [NSMutableArray array];
                        for(NSDictionary* ArrObj in dataDictObj){
                            id obj = [self bg_objectWithClass:ArrObjCla value:ArrObj];
                            [ArrObjects addObject:obj];
                        }
                        ArrObject = ArrObjects;
                        *stop = YES;
                    }
                }];
                
                //遍历自定义变量集合信息.
                !objectClaForCustom?:[objectClaForCustom enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull customKey, id  _Nonnull customObj, BOOL * _Nonnull stop) {
                    NSString* tempKey = customKey;
                    if ([customKey containsString:@"."]){
                        tempKey = [customKey componentsSeparatedByString:@"."].lastObject;
                    }
                    
                    if([key isEqualToString:tempKey]){
                        ArrObject = [self bg_objectWithClass:customObj value:[dataDict valueForKey:tempKey]];
                        *stop = YES;
                    }
                }];
                
                [object setValue:ArrObject forKey:key];
                break;//匹配到了就跳出循环.
            }
        }
    }];
    
    return object;
}

/**
 模型转字典.
 */
+(NSMutableDictionary*)bg_keyValuesWithObject:(id)object ignoredKeys:(NSArray*)ignoredKeys{
    NSMutableArray<NSString*>* keys = [[NSMutableArray alloc] initWithArray:[self getClassIvarList:[object class] onlyKey:YES]];
    if (ignoredKeys) {
        [keys removeObjectsInArray:ignoredKeys];
    }
    NSDictionary* const objectClaInArr = [HMDBGTool executeSelector:NSSelectorFromString(@"bg_objectClassInArray") forClass:[object class]];
    NSDictionary* const objectClaForCustom = [HMDBGTool executeSelector:NSSelectorFromString(@"bg_dictForCustomClass") forClass:[object class]];
    NSMutableDictionary* dictM = [NSMutableDictionary dictionary];
    
    [keys enumerateObjectsUsingBlock:^(NSString * _Nonnull key, NSUInteger idx, BOOL * _Nonnull stop) {
        __block id value = [object valueForKey:key];
        //遍历自定义变量数组集合信息.
        !objectClaInArr?:[objectClaInArr enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull Arrkey, id  _Nonnull ArrObjCla, BOOL * _Nonnull stop){
            if([key isEqualToString:Arrkey]){
                NSMutableArray* ArrObjects = [NSMutableArray array];
                for(id arrObj in value){
                    id dictObj = [self bg_keyValuesWithObject:arrObj ignoredKeys:nil];
                    [ArrObjects addObject:dictObj];
                }
                value = ArrObjects;
                *stop = YES;
            }
        }];
        
        //遍历自定义变量集合信息.
        !objectClaForCustom?:[objectClaForCustom enumerateKeysAndObjectsUsingBlock:^(NSString*  _Nonnull customKey, id  _Nonnull customObj, BOOL * _Nonnull stop) {
            if([key isEqualToString:customKey]){
                value = [self bg_keyValuesWithObject:[object valueForKey:customKey] ignoredKeys:nil];
                *stop = YES;
            }
        }];

        //存到集合里.
        !value?:[dictM setValue:value forKey:key];
    }];
    
    
    return dictM;
}

//根据NSDictionary转换从数据库读取回来的数组数据
+(id)valueForArrayRead:(NSDictionary*)dictionary{
    
    NSString* key = dictionary.allKeys.firstObject;
    if ([key isEqualToString:BGValue]) {
        return dictionary[key];
    }else if ([key isEqualToString:BGData]){
       return [[NSData alloc] initWithBase64EncodedString:dictionary[key] options:NSDataBase64DecodingIgnoreUnknownCharacters];
    }else if([key isEqualToString:BGSet]){
        return [self arrayFromJsonString:dictionary[key]];
    }else if([key isEqualToString:BGArray]){
        return [self arrayFromJsonString:dictionary[key]];
    }else if ([key isEqualToString:BGDictionary]){
       return [self dictionaryFromJsonString:dictionary[key]];
    }else if ([key containsString:BGModel]){
        NSString* claName = [key componentsSeparatedByString:@"*"].lastObject;
        NSDictionary* valueDict = [self jsonWithString:dictionary[key]];
        id object = [self objectFromJsonStringWithTableName:claName class:NSClassFromString(claName) valueDict:valueDict];
        return object;
    }else{
        NSAssert(NO,@"No matching resolution type found!");
        return nil;
    }

}
//json字符串转NSArray
+(NSArray*)arrayFromJsonString:(NSString*)jsonString{
    if(!jsonString || [jsonString isKindOfClass:[NSNull class]])return nil;
    
    if([jsonString containsString:BGModel] || [jsonString containsString:BGData]){
        NSMutableArray* arrM = [NSMutableArray array];
        NSArray* array = [self jsonWithString:jsonString];
        for(NSDictionary* dict in array){
            [arrM addObject:[self valueForArrayRead:dict]];
        }
        return arrM;
    }else{
        return [self jsonWithString:jsonString];
    }
}

//根据NSDictionary转换从数据库读取回来的字典数据
+(id)valueForDictionaryRead:(NSDictionary*)dictDest{
    
    NSString* keyDest = dictDest.allKeys.firstObject;
    if([keyDest isEqualToString:BGValue]){
        return dictDest[keyDest];
    }else if ([keyDest isEqualToString:BGData]){
        return [[NSData alloc] initWithBase64EncodedString:dictDest[keyDest] options:NSDataBase64DecodingIgnoreUnknownCharacters];
    }else if([keyDest isEqualToString:BGSet]){
        return [self arrayFromJsonString:dictDest[keyDest]];
    }else if([keyDest isEqualToString:BGArray]){
        return [self arrayFromJsonString:dictDest[keyDest]];
    }else if([keyDest isEqualToString:BGDictionary]){
        return [self dictionaryFromJsonString:dictDest[keyDest]];
    }else if([keyDest containsString:BGModel]){
        NSString* claName = [keyDest componentsSeparatedByString:@"*"].lastObject;
        NSDictionary* valueDict = [self jsonWithString:dictDest[keyDest]];
        return [self objectFromJsonStringWithTableName:claName class:NSClassFromString(claName) valueDict:valueDict];
    }else{
        NSAssert(NO,@"No matching resolution type found!");
        return nil;
    }

}
//json字符串转NSDictionary
+(NSDictionary*)dictionaryFromJsonString:(NSString*)jsonString{
    if(!jsonString || [jsonString isKindOfClass:[NSNull class]])return nil;
    
    if([jsonString containsString:BGModel] || [jsonString containsString:BGData]){
        NSMutableDictionary* dictM = [NSMutableDictionary dictionary];
        NSDictionary* dictSrc = [self jsonWithString:jsonString];
        for(NSString* keySrc in dictSrc.allKeys){
            NSDictionary* dictDest = dictSrc[keySrc];
            dictM[keySrc]= [self valueForDictionaryRead:dictDest];
        }
        return dictM;
    }else{
        return [self jsonWithString:jsonString];
    }
}
//json字符串转NSMapTable
+(NSMapTable*)mapTableFromJsonString:(NSString*)jsonString{
    if(!jsonString || [jsonString isKindOfClass:[NSNull class]])return nil;
    
    NSDictionary* dict = [self jsonWithString:jsonString];
    NSMapTable* mapTable = [NSMapTable new];
    for(NSString* key in dict.allKeys){
        id value = [self valueForDictionaryRead:dict[key]];
        [mapTable setObject:value forKey:key];
    }
    return mapTable;
}
//json字符串转NSHashTable
+(NSHashTable*)hashTableFromJsonString:(NSString*)jsonString{
    if(!jsonString || [jsonString isKindOfClass:[NSNull class]])return nil;
    
    NSArray* arr = [self jsonWithString:jsonString];
    NSHashTable* hashTable = [NSHashTable new];
    for (id obj in arr) {
        id value = [self valueForArrayRead:obj];
        [hashTable addObject:value];
    }
    return hashTable;
}
//json字符串转NSDate
+(NSDate*)dateFromString:(NSString*)jsonString{
    if(!jsonString || [jsonString isKindOfClass:[NSNull class]])return nil;
    
    NSDateFormatter *formatter = [NSDateFormatter new];
    formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss.SSS";
    NSDate *date = [formatter dateFromString:jsonString];
    return date;
}
//转换从数据库中读取出来的数据.
+(NSArray*)tansformDataFromSqlDataWithTableName:(NSString*)tableName class:(__unsafe_unretained _Nonnull Class)cla array:(NSArray*)array{
    //如果传入的class为空，则直接以字典的形式返回.
    if(cla == nil){
        return array;
    }
    
    NSMutableArray* arrM = [NSMutableArray array];
    for(NSDictionary* dict in array){
        @autoreleasepool {
            if ([dict isKindOfClass:[NSDictionary class]]) {
                id object = [HMDBGTool objectFromJsonStringWithTableName:tableName class:cla valueDict:dict];
                if(object != nil) [arrM addObject:object];
            }
        }
    }
    return arrM;
}
/**
判断类是否实现了某个类方法.
 */
+(id _Nullable)executeSelector:(SEL)selector forClass:(Class)cla{
    id obj = nil;
    if([cla respondsToSelector:selector]){
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        obj = [cla performSelector:selector];
#pragma clang diagnostic pop
    }
    return obj;
}
/**
 判断对象是否实现了某个方法.
 */
+(id _Nullable)executeSelector:(SEL)selector forObject:(id)object{
    id obj = nil;
    if([object respondsToSelector:selector]){
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        obj = [object performSelector:selector];
#pragma clang diagnostic pop
    }
    return obj;
}
/**
 获取存储数据
 */
+(NSMutableDictionary*)getDictWithObject:(id)object ignoredKeys:(NSArray* const)ignoredKeys{
    NSMutableDictionary* modelInfoDictM = [NSMutableDictionary dictionary];
    NSArray* keyAndTypes = [HMDBGTool getClassIvarList:[object class] onlyKey:NO];
    for(NSString* keyAndType in keyAndTypes){
        @autoreleasepool {
            NSArray* keyTypes = [keyAndType componentsSeparatedByString:@"*"];
            NSString* propertyName = keyTypes[0];
            NSString* propertyType = keyTypes[1];
            
            if(![ignoredKeys containsObject:propertyName]){
                
                //数据库表列名(BG_ + 属性名),加BG_是为了防止和数据库关键字发生冲突.
                NSString* sqlColumnName = propertyName;
                
                id propertyValue;
                id sqlValue;
                
                propertyValue = [object valueForKey:propertyName];
                
                if(propertyValue){
                    //列值
                    sqlValue = [HMDBGTool getSqlValue:propertyValue type:propertyType encode:YES];
                    modelInfoDictM[sqlColumnName] = sqlValue;
                }
                
            }
        }
    }
    NSAssert(modelInfoDictM.allKeys.count,@"Object cannnot be nil! Cannot store object which is nil!");
    return modelInfoDictM;
    
}
/**
 根据对象获取要更新或插入的字典.
 */
+(NSDictionary* _Nonnull)getDictWithObject:(id _Nonnull)object ignoredKeys:(NSArray* const _Nullable)ignoredKeys filtModelInfoType:(bg_getModelInfoType)filtModelInfoType{
    
    //获取存到数据库的数据.
    NSMutableDictionary* valueDict = [self getDictWithObject:object ignoredKeys:ignoredKeys];
    
    if (filtModelInfoType == bg_ModelInfoSingleUpdate){//单条更新操作时,移除 创建时间和主键 字段不做更新
        //判断是否定义了“联合主键”.
        NSArray* unionPrimaryKeys = [HMDBGTool executeSelector:hmdbg_unionPrimaryKeysSelector forClass:[object class]];
        NSString* bg_id = hmdbg_sqlKey(hmdbg_primaryKey);
        if(unionPrimaryKeys.count == 0){
            if([valueDict.allKeys containsObject:bg_id]) {
                [valueDict removeObjectForKey:bg_id];
            }
        }else{
            if(![valueDict.allKeys containsObject:bg_id]) {
                valueDict[bg_id] = @(1);//没有就预备放入
            }
        }
    }else if(filtModelInfoType == bg_ModelInfoInsert){//插入时要移除主键,不然会出错.
        //判断是否定义了“联合主键”.
        NSArray* unionPrimaryKeys = [HMDBGTool executeSelector:hmdbg_unionPrimaryKeysSelector forClass:[object class]];
        NSString* bg_id = hmdbg_sqlKey(hmdbg_primaryKey);
        if(unionPrimaryKeys.count == 0){
            if([valueDict.allKeys containsObject:bg_id]) {
                [valueDict removeObjectForKey:bg_id];
            }
        }else{
            if(![valueDict.allKeys containsObject:bg_id]) {
                valueDict[bg_id] = @(1);//没有就预备放入
            }
        }
    };
    
    return valueDict;
}
/**
 过滤建表的key.
 */
+(NSArray*)bg_filtCreateKeys:(NSArray*)bg_createkeys ignoredkeys:(NSArray*)bg_ignoredkeys{
    NSMutableArray* createKeys = [NSMutableArray arrayWithArray:bg_createkeys];
    NSMutableArray* ignoredKeys = [NSMutableArray arrayWithArray:bg_ignoredkeys];
    //判断是否有需要忽略的key集合.
    if (ignoredKeys.count){
        for(__block int i=0;i<createKeys.count;i++){
            @autoreleasepool {
                if(ignoredKeys.count){
                    NSString* createKey = [createKeys[i] componentsSeparatedByString:@"*"][0];
                    [ignoredKeys enumerateObjectsUsingBlock:^(id  _Nonnull ignoreKey, NSUInteger idx, BOOL * _Nonnull stop) {
                        if([createKey isEqualToString:ignoreKey]){
                            [createKeys removeObjectAtIndex:i];
                            [ignoredKeys removeObjectAtIndex:idx];
                            i--;
                            *stop = YES;
                        }
                    }];
                }else{
                    break;
                }
            }
        }
    }
    return createKeys;
}
/**
 如果表格不存在就新建.
 */


/**
 整形判断
 */
+ (BOOL)isPureInt:(NSString *)string{
    NSScanner* scan = [NSScanner scannerWithString:string];
    int val;
    return [scan scanInt:&val] && [scan isAtEnd];
}
/**
 浮点形判断
 */
+ (BOOL)isPureFloat:(NSString *)string{
    NSScanner* scan = [NSScanner scannerWithString:string];
    float val;
    return [scan scanFloat:&val] && [scan isAtEnd];
}

+(BOOL)getBoolWithKey:(NSString*)key{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults boolForKey:key];
}
+(void)setBoolWithKey:(NSString*)key value:(BOOL)value{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:value forKey:key];
}
+(NSString*)getStringWithKey:(NSString*)key{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults stringForKey:key];
}
+(void)setStringWithKey:(NSString*)key value:(NSString*)value{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:value forKey:key];
}
+(NSInteger)getIntegerWithKey:(NSString*)key{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults integerForKey:key];
}
+(void)setIntegerWithKey:(NSString*)key value:(NSInteger)value{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:value forKey:key];
}

@end
