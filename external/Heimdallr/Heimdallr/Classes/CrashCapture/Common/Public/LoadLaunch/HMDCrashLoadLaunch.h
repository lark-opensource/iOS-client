
/*!@header HMDCrashLoadLaunch.h
   @author somebody
   @abstract Launch HMDCrashKit duration load, keep minimum work to do
    only call basic system function and do not call anything Objective-C method
    except when create BackgroundSession Task
 */

#import "HMDCrashLoadOption.h"
#import "HMDCrashLoadReport.h"

/*!@function HMDCrashLoadLaunch
   @abstract Launch Heimdallr Crash Detection duration load status
   @return report for this launch, or nil if report is not required to generated
 */
HMDCrashLoadReport * _Nullable
HMDCrashLoadLaunch(HMDCLoadOptionRef _Nonnull option);
