//
//  BDMTLJSONAdapter.m
//  BDMantle
//
//  Created by Justin Spahr-Summers on 2013-02-12.
//  Copyright (c) 2013 GitHub. All rights reserved.
//

#import <objc/runtime.h>

#import "NSDictionary+BDMTLJSONKeyPath.h"

#import <BDEXTRuntimeExtensions.h>
#import <BDEXTScope.h>
#import "BDMTLJSONAdapter.h"
#import "BDMTLModel.h"
#import "BDMTLTransformerErrorHandling.h"
#import "BDMTLReflection.h"
#import "NSValueTransformer+BDMTLPredefinedTransformerAdditions.h"
#import "BDMTLValueTransformer.h"

NSString * const BDMTLJSONAdapterErrorDomain = @"BDMTLJSONAdapterErrorDomain";
const NSInteger BDMTLJSONAdapterErrorNoClassFound = 2;
const NSInteger BDMTLJSONAdapterErrorInvalidJSONDictionary = 3;
const NSInteger BDMTLJSONAdapterErrorInvalidJSONMapping = 4;

// An exception was thrown and caught.
const NSInteger BDMTLJSONAdapterErrorExceptionThrown = 1;

// Associated with the NSException that was caught.
NSString * const BDMTLJSONAdapterThrownExceptionErrorKey = @"BDMTLJSONAdapterThrownException";

@interface BDMTLJSONAdapter ()

// The BDMTLModel subclass being parsed, or the class of `model` if parsing has
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
//              to <BDMTLJSONSerializing>. This argument must not be nil.
// error -      If not NULL, this may be set to an error that occurs during
//              initializing the adapter.
//
// Returns a JSON adapter for modelClass, creating one of necessary. If no
// adapter could be created, nil is returned.
- (BDMTLJSONAdapter *)JSONAdapterForModelClass:(Class)modelClass error:(NSError **)error;

// Collect all value transformers needed for a given class.
//
// modelClass - The class from which to parse the JSON. This class must conform
//              to <BDMTLJSONSerializing>. This argument must not be nil.
//
// Returns a dictionary with the properties of modelClass that need
// transformation as keys and the value transformers as values.
+ (NSDictionary *)valueTransformersForModelClass:(Class)modelClass;

@end

@implementation BDMTLJSONAdapter

#pragma mark Convenience methods

+ (id)modelOfClass:(Class)modelClass fromJSONDictionary:(NSDictionary *)JSONDictionary error:(NSError **)error {
	BDMTLJSONAdapter *adapter = [[self alloc] initWithModelClass:modelClass];

	return [adapter modelFromJSONDictionary:JSONDictionary error:error];
}

+ (NSArray *)modelsOfClass:(Class)modelClass fromJSONArray:(NSArray *)JSONArray error:(NSError **)error {
	if (JSONArray == nil || ![JSONArray isKindOfClass:NSArray.class]) {
		if (error != NULL) {
			NSDictionary *userInfo = @{
				NSLocalizedDescriptionKey: NSLocalizedString(@"Missing JSON array", @""),
				NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:NSLocalizedString(@"%@ could not be created because an invalid JSON array was provided: %@", @""), NSStringFromClass(modelClass), JSONArray.class],
			};
			*error = [NSError errorWithDomain:BDMTLJSONAdapterErrorDomain code:BDMTLJSONAdapterErrorInvalidJSONDictionary userInfo:userInfo];
		}
		return nil;
	}

	NSMutableArray *models = [NSMutableArray arrayWithCapacity:JSONArray.count];
	for (NSDictionary *JSONDictionary in JSONArray){
		BDMTLModel *model = [self modelOfClass:modelClass fromJSONDictionary:JSONDictionary error:error];

		if (model == nil) return nil;

		[models addObject:model];
	}

	return models;
}

+ (NSDictionary *)JSONDictionaryFromModel:(id<BDMTLJSONSerializing>)model error:(NSError **)error {
	BDMTLJSONAdapter *adapter = [[self alloc] initWithModelClass:model.class];

	return [adapter JSONDictionaryFromModel:model error:error];
}

+ (NSArray *)JSONArrayFromModels:(NSArray *)models error:(NSError **)error {
	NSParameterAssert(models != nil);
	NSParameterAssert([models isKindOfClass:NSArray.class]);

	NSMutableArray *JSONArray = [NSMutableArray arrayWithCapacity:models.count];
	for (BDMTLModel<BDMTLJSONSerializing> *model in models) {
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

- (id)initWithModelClass:(Class)modelClass {
	NSParameterAssert(modelClass != nil);
	NSParameterAssert([modelClass conformsToProtocol:@protocol(BDMTLJSONSerializing)]);

	self = [super init];
	if (self == nil) return nil;

	_modelClass = modelClass;

	_JSONKeyPathsByPropertyKey = [modelClass JSONKeyPathsByPropertyKey];

	NSSet *propertyKeys = [self.modelClass propertyKeys];

	for (NSString *mappedPropertyKey in _JSONKeyPathsByPropertyKey) {
		if (![propertyKeys containsObject:mappedPropertyKey]) {
			NSAssert(NO, @"%@ is not a property of %@.", mappedPropertyKey, modelClass);
			return nil;
		}

		id value = _JSONKeyPathsByPropertyKey[mappedPropertyKey];

		if ([value isKindOfClass:NSArray.class]) {
			for (NSString *keyPath in value) {
				if ([keyPath isKindOfClass:NSString.class]) continue;

				NSAssert(NO, @"%@ must either map to a JSON key path or a JSON array of key paths, got: %@.", mappedPropertyKey, value);
				return nil;
			}
		} else if (![value isKindOfClass:NSString.class]) {
			NSAssert(NO, @"%@ must either map to a JSON key path or a JSON array of key paths, got: %@.",mappedPropertyKey, value);
			return nil;
		}
	}

	_valueTransformersByPropertyKey = [self.class valueTransformersForModelClass:modelClass];

	_JSONAdaptersByModelClass = [NSMapTable strongToStrongObjectsMapTable];

	return self;
}

#pragma mark Serialization

- (NSDictionary *)JSONDictionaryFromModel:(id<BDMTLJSONSerializing>)model error:(NSError **)error {
	NSParameterAssert(model != nil);
	NSParameterAssert([model isKindOfClass:self.modelClass]);

	if (self.modelClass != model.class) {
		BDMTLJSONAdapter *otherAdapter = [self JSONAdapterForModelClass:model.class error:error];

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
				id<BDMTLTransformerErrorHandling> errorHandlingTransformer = (id)transformer;

				value = [errorHandlingTransformer reverseTransformedValue:value success:&success error:&tmpError];

				if (!success) {
					*stop = YES;
					return;
				}
			} else {
				value = [transformer reverseTransformedValue:value] ?: NSNull.null;
			}
		}

		void (^createComponents)(id, NSString *) = ^(id obj, NSString *keyPath) {
			NSArray *keyPathComponents = [keyPath componentsSeparatedByString:@"."];

			// Set up dictionaries at each step of the key path.
			for (NSString *component in keyPathComponents) {
				if ([obj valueForKey:component] == nil) {
					// Insert an empty mutable dictionary at this spot so that we
					// can set the whole key path afterward.
					[obj setValue:[NSMutableDictionary dictionary] forKey:component];
				}

				obj = [obj valueForKey:component];
			}
		};

		if ([JSONKeyPaths isKindOfClass:NSString.class]) {
			createComponents(JSONDictionary, JSONKeyPaths);

			[JSONDictionary setValue:value forKeyPath:JSONKeyPaths];
		}

		if ([JSONKeyPaths isKindOfClass:NSArray.class]) {
			for (NSString *JSONKeyPath in JSONKeyPaths) {
				createComponents(JSONDictionary, JSONKeyPath);

				[JSONDictionary setValue:value[JSONKeyPath] forKeyPath:JSONKeyPath];
			}
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

				*error = [NSError errorWithDomain:BDMTLJSONAdapterErrorDomain code:BDMTLJSONAdapterErrorNoClassFound userInfo:userInfo];
			}

			return nil;
		}

		if (class != self.modelClass) {
			NSAssert([class conformsToProtocol:@protocol(BDMTLJSONSerializing)], @"Class %@ returned from +classForParsingJSONDictionary: does not conform to <BDMTLJSONSerializing>", class);

			BDMTLJSONAdapter *otherAdapter = [self JSONAdapterForModelClass:class error:error];

			return [otherAdapter modelFromJSONDictionary:JSONDictionary error:error];
		}
	}

	if (JSONDictionary == nil || ![JSONDictionary isKindOfClass:NSDictionary.class]) {
		if (error != NULL) {
			NSDictionary *userInfo = @{
				NSLocalizedDescriptionKey: NSLocalizedString(@"Missing JSON dictionary", @""),
				NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:NSLocalizedString(@"%@ could not be created because an invalid JSON dictionary was provided: %@", @""), NSStringFromClass(self.modelClass), JSONDictionary.class],
			};
			*error = [NSError errorWithDomain:BDMTLJSONAdapterErrorDomain code:BDMTLJSONAdapterErrorInvalidJSONDictionary userInfo:userInfo];
		}
		return nil;
	}

	NSMutableDictionary *dictionaryValue = [[NSMutableDictionary alloc] initWithCapacity:JSONDictionary.count];

	for (NSString *propertyKey in [self.modelClass propertyKeys]) {
		id JSONKeyPaths = self.JSONKeyPathsByPropertyKey[propertyKey];

		if (JSONKeyPaths == nil) continue;

		id value;

		if ([JSONKeyPaths isKindOfClass:NSArray.class]) {
			NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];

			for (NSString *keyPath in JSONKeyPaths) {
				BOOL success = NO;
				id value = [JSONDictionary mtl_valueForJSONKeyPath:keyPath success:&success error:error];

				if (!success) return nil;

				if (value != nil) dictionary[keyPath] = value;
			}

			value = dictionary;
		} else {
			BOOL success = NO;
			value = [JSONDictionary mtl_valueForJSONKeyPath:JSONKeyPaths success:&success error:error];

			if (!success) return nil;
		}

		if (value == nil) continue;

		@try {
			NSValueTransformer *transformer = self.valueTransformersByPropertyKey[propertyKey];
			if (transformer != nil) {
				// Map NSNull -> nil for the transformer, and then back for the
				// dictionary we're going to insert into.
				if ([value isEqual:NSNull.null]) value = nil;

				if ([transformer respondsToSelector:@selector(transformedValue:success:error:)]) {
					id<BDMTLTransformerErrorHandling> errorHandlingTransformer = (id)transformer;

					BOOL success = YES;
					value = [errorHandlingTransformer transformedValue:value success:&success error:error];

					if (!success) return nil;
				} else {
					value = [transformer transformedValue:value];
				}

				if (value == nil) value = NSNull.null;
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
					BDMTLJSONAdapterThrownExceptionErrorKey: ex
				};

				*error = [NSError errorWithDomain:BDMTLJSONAdapterErrorDomain code:BDMTLJSONAdapterErrorExceptionThrown userInfo:userInfo];
			}

			return nil;
			#endif
		}
	}

	id model = [self.modelClass modelWithDictionary:dictionaryValue error:error];

	return [model validate:error] ? model : nil;
}

+ (NSDictionary *)valueTransformersForModelClass:(Class)modelClass {
	NSParameterAssert(modelClass != nil);
	NSParameterAssert([modelClass conformsToProtocol:@protocol(BDMTLJSONSerializing)]);

	NSMutableDictionary *result = [NSMutableDictionary dictionary];

	for (NSString *key in [modelClass propertyKeys]) {
		SEL selector = BDMTLSelectorWithKeyPattern(key, "JSONTransformer");
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


			// For user-defined BDMTLModel, try parse it with dictionaryTransformer.
			if (nil == transformer && [propertyClass conformsToProtocol:@protocol(BDMTLJSONSerializing)]) {
				transformer = [self dictionaryTransformerWithModelClass:propertyClass];
			}
			
			if (transformer == nil) transformer = [NSValueTransformer mtl_validatingTransformerForClass:propertyClass ?: NSObject.class];
		} else {
			transformer = [self transformerForModelPropertiesOfObjCType:attributes->type] ?: [NSValueTransformer mtl_validatingTransformerForClass:NSValue.class];
		}

		if (transformer != nil) result[key] = transformer;
	}

	return result;
}

- (BDMTLJSONAdapter *)JSONAdapterForModelClass:(Class)modelClass error:(NSError **)error {
	NSParameterAssert(modelClass != nil);
	NSParameterAssert([modelClass conformsToProtocol:@protocol(BDMTLJSONSerializing)]);

	@synchronized(self) {
		BDMTLJSONAdapter *result = [self.JSONAdaptersByModelClass objectForKey:modelClass];

		if (result != nil) return result;

		result = [[self.class alloc] initWithModelClass:modelClass];

		if (result != nil) {
			[self.JSONAdaptersByModelClass setObject:result forKey:modelClass];
		}

		return result;
	}
}

- (NSSet *)serializablePropertyKeys:(NSSet *)propertyKeys forModel:(id<BDMTLJSONSerializing>)model {
	return propertyKeys;
}

+ (NSValueTransformer *)transformerForModelPropertiesOfClass:(Class)modelClass {
	NSParameterAssert(modelClass != nil);

	SEL selector = BDMTLSelectorWithKeyPattern(NSStringFromClass(modelClass), "JSONTransformer");
	if (![self respondsToSelector:selector]) return nil;
	
	IMP imp = [self methodForSelector:selector];
	NSValueTransformer * (*function)(id, SEL) = (__typeof__(function))imp;
	NSValueTransformer *result = function(self, selector);
	
	return result;
}

+ (NSValueTransformer *)transformerForModelPropertiesOfObjCType:(const char *)objCType {
	NSParameterAssert(objCType != NULL);

	if (strcmp(objCType, @encode(BOOL)) == 0) {
		return [NSValueTransformer valueTransformerForName:BDMTLBooleanValueTransformerName];
	}

	return nil;
}

@end

@implementation BDMTLJSONAdapter (ValueTransformers)

+ (NSValueTransformer<BDMTLTransformerErrorHandling> *)dictionaryTransformerWithModelClass:(Class)modelClass {
	NSParameterAssert([modelClass conformsToProtocol:@protocol(BDMTLModel)]);
	NSParameterAssert([modelClass conformsToProtocol:@protocol(BDMTLJSONSerializing)]);
	__block BDMTLJSONAdapter *adapter;
	
	return [BDMTLValueTransformer
		transformerUsingForwardBlock:^ id (id JSONDictionary, BOOL *success, NSError **error) {
			if (JSONDictionary == nil) return nil;
			
			if (![JSONDictionary isKindOfClass:NSDictionary.class]) {
				if (error != NULL) {
					NSDictionary *userInfo = @{
						NSLocalizedDescriptionKey: NSLocalizedString(@"Could not convert JSON dictionary to model object", @""),
						NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:NSLocalizedString(@"Expected an NSDictionary, got: %@", @""), JSONDictionary],
						BDMTLTransformerErrorHandlingInputValueErrorKey : JSONDictionary
					};
					
					*error = [NSError errorWithDomain:BDMTLTransformerErrorHandlingErrorDomain code:BDMTLTransformerErrorHandlingErrorInvalidInput userInfo:userInfo];
				}
				*success = NO;
				return nil;
			}

			if (!adapter) {
				adapter = [[self alloc] initWithModelClass:modelClass];
			}
			id model = [adapter modelFromJSONDictionary:JSONDictionary error:error];
			if (model == nil) {
				*success = NO;
			}

			return model;
		}
		reverseBlock:^ NSDictionary * (id model, BOOL *success, NSError **error) {
			if (model == nil) return nil;
			
			if (![model conformsToProtocol:@protocol(BDMTLModel)] || ![model conformsToProtocol:@protocol(BDMTLJSONSerializing)]) {
				if (error != NULL) {
					NSDictionary *userInfo = @{
						NSLocalizedDescriptionKey: NSLocalizedString(@"Could not convert model object to JSON dictionary", @""),
						NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:NSLocalizedString(@"Expected a BDMTLModel object conforming to <BDMTLJSONSerializing>, got: %@.", @""), model],
						BDMTLTransformerErrorHandlingInputValueErrorKey : model
					};
					
					*error = [NSError errorWithDomain:BDMTLTransformerErrorHandlingErrorDomain code:BDMTLTransformerErrorHandlingErrorInvalidInput userInfo:userInfo];
				}
				*success = NO;
				return nil;
			}

			if (!adapter) {
				adapter = [[self alloc] initWithModelClass:modelClass];
			}
			NSDictionary *result = [adapter JSONDictionaryFromModel:model error:error];
			if (result == nil) {
				*success = NO;
			}

			return result;
		}];
}

+ (NSValueTransformer<BDMTLTransformerErrorHandling> *)arrayTransformerWithModelClass:(Class)modelClass {
	id<BDMTLTransformerErrorHandling> dictionaryTransformer = [self dictionaryTransformerWithModelClass:modelClass];
	
	return [BDMTLValueTransformer
		transformerUsingForwardBlock:^ id (NSArray *dictionaries, BOOL *success, NSError **error) {
			if (dictionaries == nil) return nil;
			
			if (![dictionaries isKindOfClass:NSArray.class]) {
				if (error != NULL) {
					NSDictionary *userInfo = @{
						NSLocalizedDescriptionKey: NSLocalizedString(@"Could not convert JSON array to model array", @""),
						NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:NSLocalizedString(@"Expected an NSArray, got: %@.", @""), dictionaries],
						BDMTLTransformerErrorHandlingInputValueErrorKey : dictionaries
					};
					
					*error = [NSError errorWithDomain:BDMTLTransformerErrorHandlingErrorDomain code:BDMTLTransformerErrorHandlingErrorInvalidInput userInfo:userInfo];
				}
				*success = NO;
				return nil;
			}
			
			NSMutableArray *models = [NSMutableArray arrayWithCapacity:dictionaries.count];
			for (id JSONDictionary in dictionaries) {
				if (JSONDictionary == NSNull.null) {
					[models addObject:NSNull.null];
					continue;
				}
				
				if (![JSONDictionary isKindOfClass:NSDictionary.class]) {
					if (error != NULL) {
						NSDictionary *userInfo = @{
							NSLocalizedDescriptionKey: NSLocalizedString(@"Could not convert JSON array to model array", @""),
							NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:NSLocalizedString(@"Expected an NSDictionary or an NSNull, got: %@.", @""), JSONDictionary],
							BDMTLTransformerErrorHandlingInputValueErrorKey : JSONDictionary
						};
						
						*error = [NSError errorWithDomain:BDMTLTransformerErrorHandlingErrorDomain code:BDMTLTransformerErrorHandlingErrorInvalidInput userInfo:userInfo];
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
						BDMTLTransformerErrorHandlingInputValueErrorKey : models
					};
					
					*error = [NSError errorWithDomain:BDMTLTransformerErrorHandlingErrorDomain code:BDMTLTransformerErrorHandlingErrorInvalidInput userInfo:userInfo];
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
				
				if (![model isKindOfClass:BDMTLModel.class]) {
					if (error != NULL) {
						NSDictionary *userInfo = @{
							NSLocalizedDescriptionKey: NSLocalizedString(@"Could not convert JSON array to model array", @""),
							NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:NSLocalizedString(@"Expected a BDMTLModel or an NSNull, got: %@.", @""), model],
							BDMTLTransformerErrorHandlingInputValueErrorKey : model
						};
						
						*error = [NSError errorWithDomain:BDMTLTransformerErrorHandlingErrorDomain code:BDMTLTransformerErrorHandlingErrorInvalidInput userInfo:userInfo];
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
	return [NSValueTransformer valueTransformerForName:BDMTLURLValueTransformerName];
}

+ (NSValueTransformer *)NSUUIDJSONTransformer {
	return [NSValueTransformer valueTransformerForName:BDMTLUUIDValueTransformerName];
}

@end

@implementation BDMTLJSONAdapter (Deprecated)

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"

+ (NSArray *)JSONArrayFromModels:(NSArray *)models {
	return [self JSONArrayFromModels:models error:NULL];
}

+ (NSDictionary *)JSONDictionaryFromModel:(BDMTLModel<BDMTLJSONSerializing> *)model {
	return [self JSONDictionaryFromModel:model error:NULL];
}

#pragma clang diagnostic pop

@end
