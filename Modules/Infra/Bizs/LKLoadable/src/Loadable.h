//
//  Loadable.h
//  BootManager
//
//  Created by sniperj on 2021/4/28.
//

#ifndef Loadable_h
#define Loadable_h

#define LoadableSegmentName "__DATA"
#define LoadableMain "LoadableMain"
#define LoadableDidFinishLaunch "LoadableDF"
#define LoadableRunloopIdle "LoadableRI"
#define LoadableAfterFirstRender "LoadableAF"

#define ATTRIBUTE(segName)\
__attribute((used, no_sanitize_address, section(LoadableSegmentName "," segName )))

typedef int (*LoadableFunctionCallback)(const char *);
typedef void (*LoadableFunctionTemplate)(LoadableFunctionCallback);

#define FunctionBegin(functionName) \
static void loadableFunc##functionName(LoadableFunctionCallback callback){ \
    static dispatch_once_t onceToken;\
    dispatch_once(&onceToken, ^{\
    if(0 != callback(#functionName)) return;

#define FunctionEnd(functionName, loadableState) \
});} \
static LoadableFunctionTemplate varLoadableFunc##functionName ATTRIBUTE(loadableState) = loadableFunc##functionName;

#define LoadableMainFuncBegin(functionName) FunctionBegin(functionName##main)
#define LoadableMainFuncEnd(functionName) FunctionEnd(functionName##main, LoadableMain)

#define LoadableDidFinishLaunchFuncBegin(functionName) FunctionBegin(functionName##DF)
#define LoadableDidFinishLaunchFuncEnd(functionName) FunctionEnd(functionName##DF, LoadableDidFinishLaunch)

#define LoadableRunloopIdleFuncBegin(functionName) FunctionBegin(functionName##RI)
#define LoadableRunloopIdleFuncEnd(functionName) FunctionEnd(functionName##RI, LoadableRunloopIdle)

#define LoadableAfterFirstRenderFuncBegin(functionName) FunctionBegin(functionName##AF)
#define LoadableAfterFirstRenderFuncEnd(functionName) FunctionEnd(functionName##AF, LoadableAfterFirstRender)


#endif /* Loadable_h */
