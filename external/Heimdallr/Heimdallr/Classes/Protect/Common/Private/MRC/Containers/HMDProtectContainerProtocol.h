//
//  HMDProtectContainerProtocol.h
//  Heimdallr
//
//  Created by sunrunwang on 2019/4/3.
//

NS_ASSUME_NONNULL_BEGIN

@protocol HMDP_NSNumber <NSObject>
- (NSComparisonResult)HMDP_compare:(NSNumber *)otherNumber;
- (BOOL)HMDP_isEqualToNumber:(NSNumber *)number;
@end

@protocol HMDP_NSString <NSObject>
- (unichar)HMDP_characterAtIndex:(NSUInteger)index;
- (NSString *)HMDP_substringFromIndex:(NSUInteger)from;
- (NSString *)HMDP_substringToIndex:(NSUInteger)to;
- (NSString *)HMDP_substringWithRange:(NSRange)range;
- (NSString *)HMDP_stringByReplacingCharactersInRange:(NSRange)range withString:(NSString *)replacement;
- (NSString *)HMDP_stringByAppendingString:(NSString *)aString;
@end

@protocol HMDP_NSMutableString <NSObject>
- (void)HMDP_appendString:(NSString *)aString;
- (void)HMDP_replaceCharactersInRange:(NSRange)range withString:(NSString *)aString;
- (void)HMDP_insertString:(NSString *)aString atIndex:(NSUInteger)loc;
- (void)HMDP_deleteCharactersInRange:(NSRange)range;
@end

@protocol HMDP_NSArray <NSObject>
+ (instancetype)HMDP_arrayWithObjects:(id _Nonnull const * _Nonnull)objects
                                count:(NSUInteger)cnt;
- (NSArray *)HMDP_objectsAtIndexes:(NSIndexSet *)indexes;
- (id)HMDP_objectAtIndex:(NSUInteger)index;
- (id)HMDP_objectAtIndexedSubscript:(NSUInteger)idx;
- (NSArray *)HMDP_subarrayWithRange:(NSRange)range;
@end

@protocol HMDP_NSMutableArray <NSObject>
- (void)HMDP_removeObjectAtIndex:(NSUInteger)index;
- (void)HMDP_removeObjectsInRange:(NSRange)range;
- (void)HMDP_removeObjectsAtIndexes:(NSIndexSet *)indexes;
- (void)HMDP_insertObject:(id)anObject atIndex:(NSUInteger)index;
- (void)HMDP_insertObjects:(NSArray *)objects atIndexes:(NSIndexSet *)indexes;
- (void)HMDP_replaceObjectAtIndex:(NSUInteger)index withObject:(id)anObject;
- (void)HMDP_replaceObjectsAtIndexes:(NSIndexSet *)indexes withObjects:(NSArray *)objects;
- (void)HMDP_replaceObjectsInRange:(NSRange)range withObjectsFromArray:(NSArray *)otherArray;
- (void)HMDP_replaceObjectsInRange:(NSRange)range withObjectsFromArray:(NSArray *)otherArray range:(NSRange)otherRange;
- (void)HMDP_setObject:(id)obj atIndexedSubscript:(NSUInteger)idx;
@end

@protocol HMDP_NSDictionary <NSObject>
+ (instancetype)HMDP_dictionaryWithObjects:(NSArray *)objects forKeys:(NSArray<id<NSCopying>> *)keys;
+ (instancetype)HMDP_dictionaryWithObjects:(id _Nonnull const * _Nullable)objects
                                   forKeys:(id<NSCopying>  _Nonnull const * _Nullable)keys
                                     count:(NSUInteger)cnt;
@end

@protocol HMDP_NSMutableDictionary <NSObject>
- (void)HMDP_setObject:(id _Nonnull)anObject forKey:(id<NSCopying>)aKey;
- (void)HMDP_setValue:(id _Nullable)value forKey:(NSString *)key;
- (void)HMDP_removeObjectForKey:(id)aKey;
- (void)HMDP_setObject:(id)obj forKeyedSubscript:(id<NSCopying>)key;
@end

@protocol HMDP_NSAttributedString <NSObject>
- (instancetype)HMDP_initWithString:(NSString *)str;
- (instancetype)HMDP_initWithString:(NSString *)str attributes:(nullable NSDictionary<NSAttributedStringKey, id> *)attrs;
- (NSAttributedString *)HMDP_attributedSubstringFromRange:(NSRange)range;
- (void)HMDP_enumerateAttribute:(NSAttributedStringKey)attrName
                        inRange:(NSRange)enumerationRange
                        options:(NSAttributedStringEnumerationOptions)opts
                     usingBlock:(void (^)(id value, NSRange range, BOOL *stop))block;
- (void)HMDP_enumerateAttributesInRange:(NSRange)enumerationRange
                                options:(NSAttributedStringEnumerationOptions)opts
                             usingBlock:(void (^)(NSDictionary<NSAttributedStringKey, id> *attrs, NSRange range, BOOL *stop))block;
- (NSData *)HMDP_dataFromRange:(NSRange)range
            documentAttributes:(NSDictionary<NSAttributedStringDocumentAttributeKey, id> *)dict
                         error:(NSError * _Nullable *)error;
- (NSFileWrapper *)HMDP_fileWrapperFromRange:(NSRange)range
                          documentAttributes:(NSDictionary<NSAttributedStringDocumentAttributeKey, id> *)dict
                                       error:(NSError * _Nullable *)error;
- (BOOL)HMDP_containsAttachmentsInRange:(NSRange)range;
@end

@protocol HMDP_NSMutableAttributedString <NSObject>
- (void)HMDP_replaceCharactersInRange:(NSRange)range withString:(NSString *)str;
- (void)HMDP_deleteCharactersInRange:(NSRange)range;
- (void)HMDP_setAttributes:(NSDictionary<NSAttributedStringKey, id> *)attrs range:(NSRange)range;
- (void)HMDP_addAttribute:(NSAttributedStringKey)name value:(id)value range:(NSRange)range;
- (void)HMDP_addAttributes:(NSDictionary<NSAttributedStringKey, id> *)attrs range:(NSRange)range;
- (void)HMDP_removeAttribute:(NSAttributedStringKey)name range:(NSRange)range;
- (void)HMDP_insertAttributedString:(NSAttributedString *)attrString atIndex:(NSUInteger)loc;
- (void)HMDP_replaceCharactersInRange:(NSRange)range withAttributedString:(NSAttributedString *)attrString;
- (void)HMDP_fixAttributesInRange:(NSRange)range;

// 虽然这个 attributesAtIndex:effectiveRange: 方法是 NSAttributedString 定义的
// 但是只有在 NSMutableAttributedString 的条件下才崩溃, 就系统自己言行不统一
// 暂时只改到 mutableAttributeString 保护, 后续改动再观望
- (NSDictionary<NSAttributedStringKey, id> *)HMDP_attributesAtIndex:(NSUInteger)location
                                                     effectiveRange:(NSRangePointer)range;
@end

@protocol HMDP_NSSet <NSObject>
- (BOOL)HMDP_intersectsSet:(NSSet *)otherSet;
- (BOOL)HMDP_isEqualToSet:(NSSet *)otherSet;
- (BOOL)HMDP_isSubsetOfSet:(NSSet *)otherSet;
@end

@protocol HMDP_NSMutableSet <NSObject>
- (void)HMDP_addObject:(NSObject*)object;
- (void)HMDP_removeObject:(NSObject*)object;
- (void)HMDP_addObjectsFromArray:(NSArray*)array;
- (void)HMDP_intersectSet:(NSSet*)otherSet;
- (void)HMDP_minusSet:(NSSet*)otherSet;
- (void)HMDP_unionSet:(NSSet*)otherSet;
- (void)HMDP_setSet:(NSSet*)otherSet;
@end

@protocol HMDP_NSOrderedSet <NSObject>

- (id)HMDP_objectAtIndex:(NSUInteger)idx;
- (NSArray<id> *)HMDP_objectsAtIndexes:(NSIndexSet *)indexes;
- (void)HMDP_getObjects:(id _Nonnull __unsafe_unretained [_Nullable])objects range:(NSRange)range;

@end

@protocol HMDP_NSMutableOrderedSet <NSObject>

- (void)HMDP_setObject:(id)obj atIndex:(NSUInteger)idx;
- (void)HMDP_addObject:(id)object;
- (void)HMDP_addObjects:(const id _Nonnull [_Nullable])objects count:(NSUInteger)count;
- (void)HMDP_insertObject:(id)object atIndex:(NSUInteger)idx;
- (void)HMDP_insertObjects:(NSArray<id> *)objects atIndexes:(NSIndexSet *)indexes;
- (void)HMDP_exchangeObjectAtIndex:(NSUInteger)idx1 withObjectAtIndex:(NSUInteger)idx2;
- (void)HMDP_moveObjectsAtIndexes:(NSIndexSet *)indexes toIndex:(NSUInteger)idx;
- (void)HMDP_replaceObjectAtIndex:(NSUInteger)idx withObject:(id)object;
- (void)HMDP_replaceObjectsInRange:(NSRange)range withObjects:(const id _Nonnull [_Nullable])objects count:(NSUInteger)count;
- (void)HMDP_replaceObjectsAtIndexes:(NSIndexSet *)indexes withObjects:(NSArray<id> *)objects;
- (void)HMDP_removeObjectAtIndex:(NSUInteger)idx;
- (void)HMDP_removeObject:(id)object;
- (void)HMDP_removeObjectsInRange:(NSRange)range;
- (void)HMDP_removeObjectsAtIndexes:(NSIndexSet *)indexes;
- (void)HMDP_removeObjectsInArray:(NSArray<id> *)array;

@end

@protocol HMDP_NSURL <NSObject>

- (instancetype)HMDP_initFileURLWithPath:(NSString *)path;
- (instancetype)HMDP_initFileURLWithPath:(NSString *)path isDirectory:(BOOL)isDir relativeToURL:(nullable NSURL *)baseURL;
- (instancetype)HMDP_initFileURLWithPath:(NSString *)path relativeToURL:(nullable NSURL *)baseURL;
- (instancetype)HMDP_initFileURLWithPath:(NSString *)path isDirectory:(BOOL)isDir;
- (instancetype)HMDP_initFileURLWithFileSystemRepresentation:(const char *)path isDirectory:(BOOL)isDir relativeToURL:(nullable NSURL *)baseURL;
- (nullable instancetype)HMDP_initWithString:(NSString *)URLString;
- (nullable instancetype)HMDP_initWithString:(NSString *)URLString relativeToURL:(nullable NSURL *)baseURL;
- (instancetype)HMDP_initWithDataRepresentation:(NSData *)data relativeToURL:(nullable NSURL *)baseURL;
- (instancetype)HMDP_initAbsoluteURLWithDataRepresentation:(NSData *)data relativeToURL:(nullable NSURL *)baseURL;

@end

@protocol HMDP_CALayer <NSObject>

- (void)HMDP_setPosition:(CGPoint)position;

@end

NS_ASSUME_NONNULL_END
