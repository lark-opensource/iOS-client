//
//  TSPKAspectTrampolinePage.h
//  iOS15PhotoDemo
//
//  Created by bytedance on 2021/11/23.
//

#import <Foundation/Foundation.h>
#include "TSPKAspectDefines.h"

PNS_EXTERN _Nullable IMP PnSInstallTrampolineForIMP(SEL _Nullable oriCmd, IMP _Nullable originalImp, IMP _Nullable onMyEntry, IMP _Nullable onMyExit, BOOL returnsAStructValue, BOOL shareMode);
PNS_EXTERN void PnSTrampolinePageDealloc(void);
