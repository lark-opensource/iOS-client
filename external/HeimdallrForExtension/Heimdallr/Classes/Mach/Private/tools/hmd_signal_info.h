//
//  hmd_signal_info.h
//
//
//  Heimdallr
//
//  Created by 谢俊逸 on 2019/2/19.
//

/* Information about the signals we are interested in for a crash reporter.
 */

#ifndef HDR_HMDSignalInfo_h
#define HDR_HMDSignalInfo_h

#ifdef __cplusplus
extern "C" {
#endif

#include <stdint.h>

/** Get the name of a signal.
 *
 * @param signal The signal.
 *
 * @return The signal's name or NULL if not found.
 */
const char* hmdsignal_signalName(int signal);

/** Get the name of a signal's subcode.
 *
 * @param signal The signal.
 *
 * @param code The signal's code.
 *
 * @return The code's name or NULL if not found.
 */
const char* hmdsignal_signalCodeName(int signal, int code);

/** Get a list of fatal signals.
 *
 * @return A list of fatal signals.
 */
const int* hmdsignal_fatalSignals(void);

/** Get the size of the fatal signals list.
 *
 * @return The size of the fatal signals list.
 */
int hmdsignal_numFatalSignals(void);

#ifdef __cplusplus
}
#endif

#endif  // HDR_HMDSignalInfo_h
