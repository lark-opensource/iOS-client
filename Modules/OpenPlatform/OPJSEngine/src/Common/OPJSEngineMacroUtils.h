//
//  OPJSEngineMacroUtils.h
//  OPJSEngine
//
//  Created by yi on 2021/12/23.
//

#if DEBUG
#define OPDebugNSLog( s, ... ) NSLog(s, ##__VA_ARGS__)
#else
#define OPDebugNSLog( s, ... )
#endif
