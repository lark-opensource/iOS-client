//
//  TSPKFishhookUtils.m
//  Musically
//
//  Created by admin on 2022/4/18.
//

#import "TSPKFishhookUtils.h"
#import "TSPKConfigs.h"

void tspk_remove_target_value(struct bd_rebinding rebindings[], size_t rebindings_nel, size_t targrt_index) {
    for(size_t index = targrt_index; index < rebindings_nel - 1; index++) {
        rebindings[index] = rebindings[index + 1];
    }
}

int tspk_rebind_symbols(struct bd_rebinding rebindings[], size_t rebindings_nel) {
    for (size_t index = 0; index < rebindings_nel; index++) {
        NSNumber *needHook = [[TSPKConfigs sharedConfig] isApiEnable:@(rebindings[index].name)];
        if (needHook != nil && ![needHook boolValue]) {
            tspk_remove_target_value(rebindings, rebindings_nel, index);
            rebindings_nel -= 1;
        }
    }
    
    if (rebindings_nel == 0) {
        return -1;
    }
    
    return bd_rebind_symbols(rebindings, rebindings_nel);
}
