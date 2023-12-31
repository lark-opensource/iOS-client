//
//  BDTuringMacro.h
//  BDTuring
//
//  Created by bob on 2019/8/26.
//

#ifndef BDTuringMacro_h
#define BDTuringMacro_h

#define BDTuringWeakSelf __weak typeof(self) wself = self
#define BDTuringStrongSelf __strong typeof(wself) self = wself

#endif /* BDTuringMacro_h */
