//
//  cme_io_manager.h
//  mammon_engine
//

#ifndef mammon_engine_cme_io_manager_h
#define mammon_engine_cme_io_manager_h

#include <stdint.h>
#include <stddef.h>

#include "cme_type_defs.h"
#include "cme_graph.h"
#include "cme_audio_backend.h"

#ifdef __cplusplus
extern "C" {
#endif

typedef struct CMEIOManagerImpl CMEIOManager;


/// create IO manager instance
/// @param max_queue_size use at least 4
void mammon_iomanager_create(CMEIOManager**inout_mgr_inst, CMEAudioGraph *graph, CMEAudioBackend *backend, size_t max_queue_size);

void mammon_iomanager_destroy(CMEIOManager**inout_mgr_inst);

void mammon_iomanager_startIOLoop(CMEIOManager* io_mgr);

void mammon_iomanager_stopIOLoop(CMEIOManager* io_mgr);

void mammon_iomanager_play(CMEIOManager* io_mgr);

void mammon_iomanager_stop(CMEIOManager* io_mgr);

void mammon_iomanager_pause(CMEIOManager* io_mgr);

void mammon_iomanager_setRecordingState(CMEIOManager* io_mgr, bool state);

void mammon_iomanager_switchGraph(CMEIOManager* io_mgr, CMEAudioGraph *graph);

void mammon_iomanager_switchBackend(CMEIOManager* io_mgr, CMEAudioBackend *backend);

CMEAudioGraph * mammon_iomanager_getGraph(CMEIOManager* io_mgr);

CMEAudioBackend * mammon_iomanager_getCurrentBackend(CMEIOManager* io_mgr);

CMETransportState mammon_iomanager_state(CMEIOManager* io_mgr);

/// TODO: complete me
//bool mammon_iomanager_waitForStateChange(CMEIOManager* io_mgr, CMETransportState expected, CMETransportState desired, size_t timeout_ms);

#ifdef __cplusplus
}
#endif

#endif /* mammon_engine_cme_io_manager_h */


