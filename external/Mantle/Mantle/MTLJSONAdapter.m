//
//  MTLJSONAdapter.m
//  Mantle
//
//  Created by Justin Spahr-Summers on 2013-02-12.
//  Copyright (c) 2013 GitHub. All rights reserved.
//

#import <objc/runtime.h>

#import "NSDictionary+MTLJSONKeyPath.h"

#import <Mantle/EXTRuntimeExtensions.h>
#import <Mantle/EXTScope.h>
#import "MTLJSONAdapter.h"
#import "MTLModel.h"
#import "MTLTransformerErrorHandling.h"
#import "MTLReflection.h"
#import "NSValueTransformer+MTLPredefinedTransformerAdditions.h"
#import "MTLValueTransformer.h"

NSString * const MTLJSONAdapterErrorDomain = @"MTLJSONAdapterErrorDomain";
const NSInteger MTLJSONAdapterErrorNoClassFound = 2;
const NSInteger MTLJSONAdapterErrorInvalidJSONDictionary = 3;
const NSInteger MTLJSONAdapterErrorInvalidJSONMapping = 4;

// An exception was thrown and caught.
const NSInteger MTLJSONAdapterErrorExceptionThrown = 1;

// Associated with the NSException that was caught.
NSString * const MTLJSONAdapterThrownExceptionErrorKey = @"MTLJSONAdapterThrownException";

static void *MTLModelAdapterCachedPropertyKeysKey = &MTLModelAdapterCachedPropertyKeysKey;

@interface MTLJSONAdapter ()

// The MTLModel subclass being parsed, or the class of `model` if parsing has
// completed.
@property (nonatomic, strong, readonly) Class modelClass;

// A cached copy of the return value of +JSONKeyPathsByPropertyKey.
@property (nonatomic, copy, readonly) NSDictionary *JSONKeyPathsByPropertyKey;

// A cached copy of the return value of -valueTransformersForModelClass:
@property (nonatomic, copy, readonly) NSDictionary *valueTransformersByPropertyKey;

// Used to cache the JSON adapters returned by -JSONAdapterForModelClass:error:.
@property (nonatomic, strong, readonly) NSMapTable *JSONAdaptersByModelClass;

// If +classForParsingJSONDictionary: returns a model class different from the
// one this adapter was initialized with, use this method to obtain a cached
// instance of a suitable adapter instead.
//
// modelClass - The class from which to parse the JSON. This class must conform
//              to <MTLJSONSerializing>. This argument must not be nil.
// error -      If not NULL, this may be set to an error that occurs during
//              initializing the adapter.
//
// Returns a JSON adapter for modelClass, creating one of necessary. If no
// adapter could be created, nil is returned.
- (MTLJSONAdapter *)JSONAdapterForModelClass:(Class)modelClass error:(NSError **)error;

// Collect all value transformers needed for a given class.
//
// modelClass - The class from which to parse the JSON. This class must conform
//              to <MTLJSONSerializing>. This argument must not be nil.
//
// Returns a dictionary with the properties of modelClass that need
// transformation as keys and the value transformers as values.
+ (NSDictionary *)valueTransformersForModelClass:(Class)modelClass;

/// Initializes the receiver with a given model class.
///
/// modelClass - The MTLModel subclass to attempt to parse from the JSON and
///              back. This class must conform to <MTLJSONSerializing>. This
///              argument must not be nil.
///
/// Returns an initialized adapter.
- (id)initWithModelClass:(Class)modelClass;

@end

@implementation MTLJSONAdapter

#pragma mark Convenience methods

+ (id)modelOfClass:(Class)modelClass fromJSONDictionary:(NSDictionary *)JSONDictionary error:(NSError **)error {
	MTLJSONAdapter *adapter = [self adapterWithModelClass:modelClass];
	
	return [adapter modelFromJSONDictionary:JSONDictionary error:error];
}

+ (NSArray *)modelsOfClass:(Class)modelClass fromJSONArray:(NSArray *)JSONArray error:(NSError **)error {
	if (JSONArray == nil || ![JSONArray isKindOfClass:NSArray.class]) {
		if (error != NULL) {
			NSDictionary *userInfo = @{
									   NSLocalizedDescriptionKey: NSLocalizedString(@"Missing JSON array", @""),
									   NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:NSLocalizedString(@"%@ could not be created because an invalid JSON array was provided: %@", @""), NSStringFromClass(modelClass), JSONArray.class],
									   };
			*error = [NSError errorWithDomain:MTLJSONAdapterErrorDomain code:MTLJSONAdapterErrorInvalidJSONDictionary userInfo:userInfo];
		}
		return nil;
	}
	
	NSMutableArray *models = [NSMutableArray arrayWithCapacity:JSONArray.count];
	for (NSDictionary *JSONDictionary in JSONArray){
		MTLModel *model = [self modelOfClass:modelClass fromJSONDictionary:JSONDictionary error:error];
		
		if (model == nil) return nil;
		
		[models addObject:model];
	}
	
	return models;
}

+ (NSDictionary *)JSONDictionaryFromModel:(id<MTLJSONSerializing>)model error:(NSError **)error {
	MTLJSONAdapter *adapter = [self adapterWithModelClass:model.class];
	return [adapter JSONDictionaryFromModel:model error:error];
}

+ (NSArray *)JSONArrayFromModels:(NSArray *)models error:(NSError **)error {
	NSParameterAssert(models != nil);
	NSParameterAssert([models isKindOfClass:NSArray.class]);
	
	NSMutableArray *JSONArray = [NSMutableArray arrayWithCapacity:models.count];
	for (MTLModel<MTLJSONSerializing> *model in models) {
		NSDictionary *JSONDictionary = [self JSONDictionaryFromModel:model error:error];
		if (JSONDictionary == nil) return nil;
		
		[JSONArray addObject:JSONDictionary];
	}
	
	return JSONArray;
}

#pragma mark Lifecycle

- (id)init {
	NSAssert(NO, @"%@ must be initialized with a model class", self.class);
	return nil;
}

+ (instancetype)adapterWithModelClass:(Class)modelClass {
	if ([MTLModel isFastMode]) {
		MTLJSONAdapter *adapter = objc_getAssociatedObject(modelClass, MTLModelAdapterCachedPropertyKeysKey);
		if (adapter == nil) {
			adapter = [[self alloc] initWithModelClass:modelClass];
			objc_setAssociatedObject(modelClass, MTLModelAdapterCachedPropertyKeysKey, adapter, OBJC_ASSOCIATION_RETAIN);
		}
		return adapter;
	} else {
		return [[self alloc] initWithModelClass:modelClass];
	}
}

- (instancetype)initWithModelClass:(Class)modelClass {
	NSParameterAssert(modelClass != nil);
	NSParameterAssert([modelClass conformsToProtocol:@protocol(MTLJSONSerializing)]);
	
	self = [super init];
	if (self == nil) return nil;
	
	_modelClass = modelClass;
	
	Class currentClass = modelClass;
	NSMutableDictionary *JSONKeyPathsByPropertyKey = [NSMutableDictionary dictionary];
	NSSet *propertyKeys = [self.modelClass propertyKeys];
	
	NSString * (^lowerCamelToUnderscore)(NSString *) = ^(NSString *propertyKey) {
		const char *propertyString = [propertyKey UTF8String];
		char *underscoreSplitString = malloc(2 * strlen(propertyString)+1);
		char *curChar = underscoreSplitString;
		
		size_t anchor = 0, cur = anchor, length = strlen(propertyString);
		bool firstWord = true;
		
		while (anchor < length) {
			while (cur < length && isupper(propertyString[cur])) ++cur;
			
			if (cur - anchor <= 1) {
				while(cur < length && !isupper(propertyString[cur])) ++cur;
				if (firstWord) {
					memcpy(curChar, propertyString+anchor, cur-anchor);
					curChar += cur-anchor;
				} else {
					*curChar++ = '_';
					*curChar++ = (char)tolower(*(propertyString+anchor));
					memcpy(curChar, propertyString+anchor+1, cur-anchor-1);
					curChar += cur-anchor-1;
				}
				anchor = cur;
			} else {
				if (!firstWord) {
					*curChar++ = '_';
				}
				if ( cur == length) {
					memcpy(curChar, propertyString+anchor, cur-anchor);
					curChar += cur-anchor;
					anchor = cur;
				} else {
					memcpy(curChar, propertyString+anchor, cur-anchor-1);
					curChar += cur-anchor-1;
					anchor = cur-1;
					cur = anchor;
				}
			}
			
			firstWord = false;
		}
		*curChar = '\0';
		NSString *retString = [NSString stringWithUTF8String:underscoreSplitString];
		free(underscoreSplitString);
		return retString;
	};
	
	BOOL automaticallyDefaultMapping = NO;
	if ([currentClass respondsToSelector:@selector(automaticallyDefaultMapping)]) {
		automaticallyDefaultMapping = [currentClass automaticallyDefaultMapping];
	}
	
	while (currentClass && [currentClass conformsToProtocol:@protocol(MTLJSONSerializing)]) {
		if ([currentClass methodForSelector:@selector(JSONKeyPathsByPropertyKey)] != [currentClass.superclass methodForSelector:@selector(JSONKeyPathsByPropertyKey)]) {
			NSDictionary *currentMapping = [currentClass JSONKeyPathsByPropertyKey];
			for (NSString *key in currentMapping) {
				if (![propertyKeys containsObject:key]) {
					NSAssert(NO, @"%@ is not a property of %@. Or the key is intentionally ignored", key, modelClass);
					return nil;
				}
				if (JSONKeyPathsByPropertyKey[key] == nil) {
					id value = currentMapping[key];
					if ([value isKindOfClass:NSArray.class]) {
						NSAssert(NO, @"Forked version of Mantle does not support array mapping");
						return nil;
					} else if (![value isKindOfClass:NSString.class]) {
						NSAssert(NO, @"%@ must either map to a JSON key path or a JSON array of key paths, got: %@.",key, value);
						return nil;
					} else {
						NSArray *keyPathArray = [value componentsSeparatedByString:@"."];
						if (keyPathArray.count != 1) {
							JSONKeyPathsByPropertyKey[key] = keyPathArray;
						} else {
							JSONKeyPathsByPropertyKey[key] = value;
						}
					}
				}
			}
		}
		
		if (automaticallyDefaultMapping) {
			for (NSString *propertyKey in [currentClass propertyKeysOfCurrentClass]) {
				if (JSONKeyPathsByPropertyKey[propertyKey] == nil) {
					JSONKeyPathsByPropertyKey[propertyKey] = lowerCamelToUnderscore(propertyKey);
				}
			}
		}
		
		if (JSONKeyPathsByPropertyKey.count != 0 && !automaticallyDefaultMapping) {
			break;
		}
		
		currentClass = currentClass.superclass;
	}
	
	_JSONKeyPathsByPropertyKey = [JSONKeyPathsByPropertyKey copy];
	
	_valueTransformersByPropertyKey = [self.class valueTransformersForModelClass:modelClass];
	
	_JSONAdaptersByModelClass = [NSMapTable strongToStrongObjectsMapTable];
	
	return self;
}

#pragma mark Serialization

- (NSDictionary *)JSONDictionaryFromModel:(id<MTLJSONSerializing>)model error:(NSError **)error {
	NSParameterAssert(model != nil);
	NSParameterAssert([model isKindOfClass:self.modelClass]);
	
	if (self.modelClass != model.class) {
		MTLJSONAdapter *otherAdapter;
		if ([MTLModel isFastMode]) {
			otherAdapter = [self.class adapterWithModelClass:model.class];
		} else {
			otherAdapter = [self JSONAdapterForModelClass:model.class error:error];
		}
		
		return [otherAdapter JSONDictionaryFromModel:model error:error];
	}
	
	NSSet *propertyKeysToSerialize = [self serializablePropertyKeys:[NSSet setWithArray:self.JSONKeyPathsByPropertyKey.allKeys] forModel:model];
	
	NSDictionary *dictionaryValue = [model.dictionaryValue dictionaryWithValuesForKeys:propertyKeysToSerialize.allObjects];
	NSMutableDictionary *JSONDictionary = [[NSMutableDictionary alloc] initWithCapacity:dictionaryValue.count];
	
	__block BOOL success = YES;
	__block NSError *tmpError = nil;
	
	[dictionaryValue enumerateKeysAndObjectsUsingBlock:^(NSString *propertyKey, id value, BOOL *stop) {
		id JSONKeyPaths = self.JSONKeyPathsByPropertyKey[propertyKey];
		
		if (JSONKeyPaths == nil) return;
		
		NSValueTransformer *transformer = self.valueTransformersByPropertyKey[propertyKey];
		if ([transformer.class allowsReverseTransformation]) {
			// Map NSNull -> nil for the transformer, and then back for the
			// dictionaryValue we're going to insert into.
			if ([value isEqual:NSNull.null]) value = nil;
			
			if ([transformer respondsToSelector:@selector(reverseTransformedValue:success:error:)]) {
				id<MTLTransformerErrorHandling> errorHandlingTransformer = (id)transformer;
				
				value = [errorHandlingTransformer reverseTransformedValue:value success:&success error:&tmpError];
				
				if (!success) {
					value = nil;
				}
			} else {
				value = [transformer reverseTransformedValue:value] ?: NSNull.null;
			}
		}
        
        if (value == nil) return;
        
        if ([JSONKeyPaths isKindOfClass:[NSString class]]) {
            [JSONDictionary setObject:value forKey:(NSString *)JSONKeyPaths];
        } else if ([JSONKeyPaths isKindOfClass:[NSArray class]]){
            __block NSMutableDictionary *tempDictionary = JSONDictionary;
            [(NSArray *)JSONKeyPaths enumerateObjectsUsingBlock:^(NSString *component, NSUInteger idx, BOOL * _Nonnull stop) {
                if (idx == ((NSArray *)JSONKeyPaths).count - 1) {
                    [tempDictionary setObject:value forKey:component];
                } else {
                    if ([tempDictionary valueForKey:component] == nil) {
                        // Insert an empty mutable dictionary at this spot so that we
                        // can set the whole key path afterward.
                        [tempDictionary setValue:[NSMutableDictionary dictionary] forKey:component];
                    }
                    tempDictionary = [tempDictionary objectForKey:component];
                }
            }];
        }
    }];
    
    if (success) {
		return JSONDictionary;
	} else {
		if (error != NULL) *error = tmpError;
		
		return nil;
	}
}

- (id)modelFromJSONDictionary:(NSDictionary *)JSONDictionary error:(NSError **)error {
	if ([self.modelClass respondsToSelector:@selector(classForParsingJSONDictionary:)]) {
		Class class = [self.modelClass classForParsingJSONDictionary:JSONDictionary];
		if (class == nil) {
			if (error != NULL) {
				NSDictionary *userInfo = @{
										   NSLocalizedDescriptionKey: NSLocalizedString(@"Could not parse JSON", @""),
										   NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"No model class could be found to parse the JSON dictionary.", @"")
										   };
				
				*error = [NSError errorWithDomain:MTLJSONAdapterErrorDomain code:MTLJSONAdapterErrorNoClassFound userInfo:userInfo];
			}
			
			return nil;
		}
		
		if (class != self.modelClass) {
			NSAssert([class conformsToProtocol:@protocol(MTLJSONSerializing)], @"Class %@ returned from +classForParsingJSONDictionary: does not conform to <MTLJSONSerializing>", class);
			MTLJSONAdapter *otherAdapter;
			if ([MTLModel isFastMode]) {
				otherAdapter = [self.class adapterWithModelClass:class];
			} else {
				otherAdapter = [self JSONAdapterForModelClass:class error:error];
			}
			
			return [otherAdapter modelFromJSONDictionary:JSONDictionary error:error];
		}
	}
	
	if (![JSONDictionary isKindOfClass:NSDictionary.class]) {
		if (error != NULL) {
			NSDictionary *userInfo = @{
				NSLocalizedDescriptionKey: NSLocalizedString(@"Missing JSON dictionary", @""),
				NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:NSLocalizedString(@"%@ could not be created because an invalid JSON dictionary was provided: %@", @""), NSStringFromClass(self.modelClass), JSONDictionary.class],
			};
			*error = [NSError errorWithDomain:MTLJSONAdapterErrorDomain code:MTLJSONAdapterErrorInvalidJSONDictionary userInfo:userInfo];
		}
		return nil;
	}
	
	NSMutableDictionary *dictionaryValue = [[NSMutableDictionary alloc] initWithCapacity:JSONDictionary.count];
	
	for (NSString *propertyKey in [self.modelClass propertyKeys]) {
		id JSONKeyPaths = self.JSONKeyPathsByPropertyKey[propertyKey];
		
		if (JSONKeyPaths == nil) continue;
		
		id value;
		
		if ([JSONKeyPaths isKindOfClass:NSArray.class]) {
			value = [JSONDictionary mtl_valueForJSONKeyPathArray:JSONKeyPaths];
		} else {
			value = JSONDictionary[JSONKeyPaths];
		}
		
		if (value == nil) continue;
		
		@try {
			NSValueTransformer *transformer = self.valueTransformersByPropertyKey[propertyKey];
			if (transformer != nil) {
				// Map NSNull -> nil for the transformer, and then back for the
				// dictionary we're going to insert into.
				if ([value isEqual:NSNull.null]) value = nil;
				
				if ([transformer respondsToSelector:@selector(transformedValue:success:error:)]) {
					id<MTLTransformerErrorHandling> errorHandlingTransformer = (id)transformer;
					
					BOOL success = YES;
					value = [errorHandlingTransformer transformedValue:value success:&success error:error];
					
					if (!success) {
						value = nil;
					}
				} else {
					value = [transformer transformedValue:value];
				}
			}
			dictionaryValue[propertyKey] = value;
		} @catch (NSException *ex) {
			NSLog(@"*** Caught exception %@ parsing JSON key path \"%@\" from: %@", ex, JSONKeyPaths, JSONDictionary);
			
			// Fail fast in Debug builds.
#if DEBUG
			@throw ex;
#else
			if (error != NULL) {
				NSDictionary *userInfo = @{
										   NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Caught exception parsing JSON key path \"%@\" for model class: %@", JSONKeyPaths, self.modelClass],
										   NSLocalizedRecoverySuggestionErrorKey: ex.description,
										   NSLocalizedFailureReasonErrorKey: ex.reason,
										   MTLJSONAdapterThrownExceptionErrorKey: ex
										   };
				
				*error = [NSError errorWithDomain:MTLJSONAdapterErrorDomain code:MTLJSONAdapterErrorExceptionThrown userInfo:userInfo];
			}
			
			return nil;
#endif
		}
	}
	
	id model = [self.modelClass modelWithDictionary:dictionaryValue error:error];
	
#if DEBUG
	return [model validate:error] ? model : nil;
#else
	return model;
#endif
}

+ (NSDictionary *)valueTransformersForModelClass:(Class)modelClass {
	NSParameterAssert(modelClass != nil);
	NSParameterAssert([modelClass conformsToProtocol:@protocol(MTLJSONSerializing)]);
	
	NSMutableDictionary *result = [NSMutableDictionary dictionary];
	
	for (NSString *key in [modelClass propertyKeys]) {
		SEL selector = MTLSelectorWithKeyPattern(key, "JSONTransformer");
		if ([modelClass respondsToSelector:selector]) {
			IMP imp = [modelClass methodForSelector:selector];
			NSValueTransformer * (*function)(id, SEL) = (__typeof__(function))imp;
			NSValueTransformer *transformer = function(modelClass, selector);
			
			if (transformer != nil) result[key] = transformer;
			
			continue;
		}
		
		if ([modelClass respondsToSelector:@selector(JSONTransformerForKey:)]) {
			NSValueTransformer *transformer = [modelClass JSONTransformerForKey:key];
			
			if (transformer != nil) {
				result[key] = transformer;
				continue;
			}
		}
		
		objc_property_t property = class_getProperty(modelClass, key.UTF8String);
		
		if (property == NULL) continue;
		
		mtl_propertyAttributes *attributes = mtl_copyPropertyAttributes(property);
		@onExit {
			free(attributes);
		};
		
		NSValueTransformer *transformer = nil;
		
		if (*(attributes->type) == *(@encode(id))) {
			Class propertyClass = attributes->objectClass;
			
			if (propertyClass != nil) {
				transformer = [self transformerForModelPropertiesOfClass:propertyClass];
			}
			
			
			// For user-defined MTLModel, try parse it with dictionaryTransformer.
			if (nil == transformer && [propertyClass conformsToProtocol:@protocol(MTLJSONSerializing)]) {
				transformer = [self dictionaryTransformerWithModelClass:propertyClass];
			}
			
			if ([propertyClass isSubclassOfClass:[NSArray class]] && attributes->deducedObjectClass && [attributes->deducedObjectClass conformsToProtocol:@protocol(MTLJSONSerializing)]) {
				transformer = [self arrayTransformerWithModelClass:attributes->deducedObjectClass];
			}
			
			if (transformer == nil) transformer = [NSValueTransformer mtl_validatingTransformerForClass:propertyClass ?: NSObject.class];
		} else {
			transformer = [self transformerForModelPropertiesOfObjCType:attributes->type] ?: [NSValueTransformer mtl_validatingTransformerForClass:NSValue.class];
		}
		
		if (transformer != nil) result[key] = transformer;
	}
	
	return result;
}

- (MTLJSONAdapter *)JSONAdapterForModelClass:(Class)modelClass error:(NSError **)error {
	NSParameterAssert(modelClass != nil);
	NSParameterAssert([modelClass conformsToProtocol:@protocol(MTLJSONSerializing)]);
	
	@synchronized(self) {
		MTLJSONAdapter *result = [self.JSONAdaptersByModelClass objectForKey:modelClass];
		
		if (result != nil) return result;
		
		result = [self.class adapterWithModelClass:modelClass];
		
		if (result != nil) {
			[self.JSONAdaptersByModelClass setObject:result forKey:modelClass];
		}
		
		return result;
	}
}

- (NSSet *)serializablePropertyKeys:(NSSet *)propertyKeys forModel:(id<MTLJSONSerializing>)model {
	return propertyKeys;
}

+ (NSValueTransformer *)transformerForModelPropertiesOfClass:(Class)modelClass {
	NSParameterAssert(modelClass != nil);
	
	SEL selector = MTLSelectorWithKeyPattern(NSStringFromClass(modelClass), "JSONTransformer");
	if (![self respondsToSelector:selector]) return nil;
	
	IMP imp = [self methodForSelector:selector];
	NSValueTransformer * (*function)(id, SEL) = (__typeof__(function))imp;
	NSValueTransformer *result = function(self, selector);
	
	return result;
}

+ (NSValueTransformer *)transformerForModelPropertiesOfObjCType:(const char *)objCType {
	NSParameterAssert(objCType != NULL);
	
	if (strcmp(objCType, @encode(BOOL)) == 0) {
		return [NSValueTransformer valueTransformerForName:MTLBooleanValueTransformerName];
	}
	
	return nil;
}

@end

@implementation MTLJSONAdapter (ValueTransformers)

+ (NSValueTransformer<MTLTransformerErrorHandling> *)dictionaryTransformerWithModelClass:(Class)modelClass {
	NSParameterAssert([modelClass conformsToProtocol:@protocol(MTLModel)]);
	NSParameterAssert([modelClass conformsToProtocol:@protocol(MTLJSONSerializing)]);
	//Original Mantle use this block variable to share initialized adapter among different blocks invocation.
	//It will not share this variable between threads, so no lock is needed.
	//Forked version share all adapter class for each class, so no block variable is needed.
	__block MTLJSONAdapter *adapter;
	
	return [MTLValueTransformer
			transformerUsingForwardBlock:^ id (id JSONDictionary, BOOL *success, NSError **error) {
				if (JSONDictionary == nil) return nil;
				
				if (![JSONDictionary isKindOfClass:NSDictionary.class]) {
					if (error != NULL) {
						NSDictionary *userInfo = @{
												   NSLocalizedDescriptionKey: NSLocalizedString(@"Could not convert JSON dictionary to model object", @""),
												   NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:NSLocalizedString(@"Expected an NSDictionary, got: %@", @""), JSONDictionary],
												   MTLTransformerErrorHandlingInputValueErrorKey : JSONDictionary
												   };
						
						*error = [NSError errorWithDomain:MTLTransformerErrorHandlingErrorDomain code:MTLTransformerErrorHandlingErrorInvalidInput userInfo:userInfo];
					}
					*success = NO;
					return nil;
				}
				id model = nil;
				if ([MTLModel isFastMode]) {
					model = [[self adapterWithModelClass:modelClass] modelFromJSONDictionary:JSONDictionary error:error];
				} else {
					if (!adapter) {
						adapter = [[self alloc] initWithModelClass:modelClass];
					}
					model = [adapter modelFromJSONDictionary:JSONDictionary error:error];
				}
				if (error && *error != nil) {
					*success = NO;
				}
				
				return model;
			}
			reverseBlock:^ NSDictionary * (id model, BOOL *success, NSError **error) {
				if (model == nil) return nil;
				
				if (![model conformsToProtocol:@protocol(MTLModel)] || ![model conformsToProtocol:@protocol(MTLJSONSerializing)]) {
					if (error != NULL) {
						NSDictionary *userInfo = @{
												   NSLocalizedDescriptionKey: NSLocalizedString(@"Could not convert model object to JSON dictionary", @""),
												   NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:NSLocalizedString(@"Expected a MTLModel object conforming to <MTLJSONSerializing>, got: %@.", @""), model],
												   MTLTransformerErrorHandlingInputValueErrorKey : model
												   };
						
						*error = [NSError errorWithDomain:MTLTransformerErrorHandlingErrorDomain code:MTLTransformerErrorHandlingErrorInvalidInput userInfo:userInfo];
					}
					*success = NO;
					return nil;
				}
				
				NSDictionary *result = nil;
				if ([MTLModel isFastMode]) {
					result = [[self adapterWithModelClass:modelClass] JSONDictionaryFromModel:model error:error];
				} else {
					if (!adapter) {
						adapter = [[self alloc] initWithModelClass:modelClass];
					}
					result = [adapter JSONDictionaryFromModel:model error:error];
				}
				
				if (error && *error != nil) {
					*success = NO;
				}
				
				return result;
			}];
}

+ (NSValueTransformer<MTLTransformerErrorHandling> *)arrayTransformerWithModelClass:(Class)modelClass {
	id<MTLTransformerErrorHandling> dictionaryTransformer = [self dictionaryTransformerWithModelClass:modelClass];
	
	return [MTLValueTransformer
			transformerUsingForwardBlock:^ id (NSArray *dictionaries, BOOL *success, NSError **error) {
				if (dictionaries == nil) return nil;
				
				if (![dictionaries isKindOfClass:NSArray.class]) {
					if (error != NULL) {
						NSDictionary *userInfo = @{
												   NSLocalizedDescriptionKey: NSLocalizedString(@"Could not convert JSON array to model array", @""),
												   NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:NSLocalizedString(@"Expected an NSArray, got: %@.", @""), dictionaries],
												   MTLTransformerErrorHandlingInputValueErrorKey : dictionaries
												   };
						
						*error = [NSError errorWithDomain:MTLTransformerErrorHandlingErrorDomain code:MTLTransformerErrorHandlingErrorInvalidInput userInfo:userInfo];
					}
					*success = NO;
					return nil;
				}
				
				NSMutableArray *models = [NSMutableArray arrayWithCapacity:dictionaries.count];
				for (id JSONDictionary in dictionaries) {
					if (JSONDictionary == NSNull.null) {
						continue;
					}
					
					if (![JSONDictionary isKindOfClass:NSDictionary.class]) {
						if (error != NULL) {
							NSDictionary *userInfo = @{
													   NSLocalizedDescriptionKey: NSLocalizedString(@"Could not convert JSON array to model array", @""),
													   NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:NSLocalizedString(@"Expected an NSDictionary or an NSNull, got: %@.", @""), JSONDictionary],
													   MTLTransformerErrorHandlingInputValueErrorKey : JSONDictionary
													   };
							
							*error = [NSError errorWithDomain:MTLTransformerErrorHandlingErrorDomain code:MTLTransformerErrorHandlingErrorInvalidInput userInfo:userInfo];
						}
						*success = NO;
						return nil;
					}
					
					id model = [dictionaryTransformer transformedValue:JSONDictionary success:success error:error];
					
					if (*success == NO) return nil;
					
					if (model == nil) continue;
					
					[models addObject:model];
				}
				
				return models;
			}
			reverseBlock:^ id (NSArray *models, BOOL *success, NSError **error) {
				if (models == nil) return nil;
				
				if (![models isKindOfClass:NSArray.class]) {
					if (error != NULL) {
						NSDictionary *userInfo = @{
												   NSLocalizedDescriptionKey: NSLocalizedString(@"Could not convert model array to JSON array", @""),
												   NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:NSLocalizedString(@"Expected an NSArray, got: %@.", @""), models],
												   MTLTransformerErrorHandlingInputValueErrorKey : models
												   };
						
						*error = [NSError errorWithDomain:MTLTransformerErrorHandlingErrorDomain code:MTLTransformerErrorHandlingErrorInvalidInput userInfo:userInfo];
					}
					*success = NO;
					return nil;
				}
				
				NSMutableArray *dictionaries = [NSMutableArray arrayWithCapacity:models.count];
				for (id model in models) {
					if (model == NSNull.null) {
						[dictionaries addObject:NSNull.null];
						continue;
					}
					
					if (![model isKindOfClass:MTLModel.class]) {
						if (error != NULL) {
							NSDictionary *userInfo = @{
													   NSLocalizedDescriptionKey: NSLocalizedString(@"Could not convert JSON array to model array", @""),
													   NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:NSLocalizedString(@"Expected a MTLModel or an NSNull, got: %@.", @""), model],
													   MTLTransformerErrorHandlingInputValueErrorKey : model
													   };
							
							*error = [NSError errorWithDomain:MTLTransformerErrorHandlingErrorDomain code:MTLTransformerErrorHandlingErrorInvalidInput userInfo:userInfo];
						}
						*success = NO;
						return nil;
					}
					
					NSDictionary *dict = [dictionaryTransformer reverseTransformedValue:model success:success error:error];
					
					if (*success == NO) return nil;
					
					if (dict == nil) continue;
					
					[dictionaries addObject:dict];
				}
				
				return dictionaries;
			}];
}

+ (NSValueTransformer *)NSURLJSONTransformer {
	return [NSValueTransformer valueTransformerForName:MTLURLValueTransformerName];
}

+ (NSValueTransformer *)NSUUIDJSONTransformer {
	return [NSValueTransformer valueTransformerForName:MTLUUIDValueTransformerName];
}

@end

@implementation MTLJSONAdapter (Deprecated)

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"

+ (NSArray *)JSONArrayFromModels:(NSArray *)models {
	return [self JSONArrayFromModels:models error:NULL];
}

+ (NSDictionary *)JSONDictionaryFromModel:(MTLModel<MTLJSONSerializing> *)model {
	return [self JSONDictionaryFromModel:model error:NULL];
}

#pragma clang diagnostic pop

@end
