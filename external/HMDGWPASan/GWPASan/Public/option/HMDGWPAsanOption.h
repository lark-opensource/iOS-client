//
//  HMDGWPAsanOption.h
//  HMDGWPAsanOption
//
//  Created by someone at yesterday
//

#import <malloc/malloc.h>
#import <Foundation/Foundation.h>

#import "HMDGWPAsanPublicDefine.h"

@interface HMDGWPAsanOption : NSObject

@property(nonatomic, nullable) HMDGWPAsanReplaceZoneFunc replaceZone;

@property(nonatomic) uint32_t maxAllocation;

@property(nonatomic) uint32_t sampleRate;

@property(nonatomic, getter=isDebugMode) BOOL debugMode;

@property(nonatomic) BOOL useNewAsan;

@end
