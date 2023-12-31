//
//  BDPMorePanelManager.h
//  Timor
//
//  Created by 王浩宇 on 2019/11/22.
//

#import <Foundation/Foundation.h>
#import <OPFoundation/BDPUniqueID.h>
#import <OPFoundation/BDPMorePanelItem.h>

@interface BDPMorePanelManager : NSObject

+ (void)openMorePanelWithUniqueID:(BDPUniqueID *)uniqueID;

@end

