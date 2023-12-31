//
//  BDMantle.h
//  BDMantle
//
//  Created by Justin Spahr-Summers on 2012-09-04.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

#import <Foundation/Foundation.h>

//! Project version number for BDMantle.
FOUNDATION_EXPORT double BDMantleVersionNumber;

//! Project version string for BDMantle.
FOUNDATION_EXPORT const unsigned char BDMantleVersionString[];

#import "BDMTLJSONAdapter.h"
#import "BDMTLModel.h"
#import "BDMTLModel+NSCoding.h"
#import "BDMTLValueTransformer.h"
#import "BDMTLTransformerErrorHandling.h"
#import "NSArray+BDMTLManipulationAdditions.h"
#import "NSDictionary+BDMTLManipulationAdditions.h"
#import "NSDictionary+BDMTLMappingAdditions.h"
#import "NSObject+BDMTLComparisonAdditions.h"
#import "NSValueTransformer+BDMTLInversionAdditions.h"
#import "NSValueTransformer+BDMTLPredefinedTransformerAdditions.h"
