//
//  cme_graph_manager.h
//  mammon_engine
//

#ifndef mammon_engine_cme_graph_manager_h
#define mammon_engine_cme_graph_manager_h

#include <stddef.h>
#include <stdint.h>
#include <stdbool.h>

#include "cme_nodes.h"
#include "cme_graph.h"
#include "cme_type_defs.h"
#include "cme_file_source.h"
#include "cme_audio_stream.h"
#include "ae_effect.h"

#ifdef __cplusplus
extern "C" {
#endif

typedef struct CMEGraphManagerImpl CMEGraphManager;

void mammon_graph_manager_create(CMEGraphManager **inout_mgr_inst);

void mammon_graph_manager_destroy(CMEGraphManager **inout_mgr_inst);

/// Create a new audio graph
/// @param inoutGraphRef to store the old graph instance, it's nullable
/// @note if inoutGraphRef is NOT null, the old graph will hold on it
///       and you have to destroy the old graph yourself
void mammon_graph_manager_createNewGraph(CMEGraphManager *graph_mgr, CMEAudioGraph **inoutGraphRef);

CMEAudioGraph * mammon_graph_manager_getCurrentGraph(CMEGraphManager *graph_mgr);

CMENodeRef mammon_graph_manager_getNode(CMEGraphManager *graph_mgr, CMENodeID node_id);

bool mammon_graph_manager_hasNode(CMEGraphManager *graph_mgr, CMENodeID node_id);

bool mammon_graph_manager_deleteNode(CMEGraphManager *graph_mgr, CMENodeID node_id);

CMENodeRef mammon_graph_manager_createBufferSourceNode(CMEGraphManager *graph_mgr, CMEAudioStream *data);

CMENodeRef mammon_graph_manager_createPositionalBufferSourceNode(CMEGraphManager *graph_mgr, CMEAudioStream *data, CMETransportTime position);

CMENodeRef mammon_graph_manager_createMixerNode(CMEGraphManager *graph_mgr);

CMENodeRef mammon_graph_manager_createSinkNode(CMEGraphManager *graph_mgr);

CMENodeRef mammon_graph_manager_createAudioEffectNode(CMEGraphManager *graph_mgr, CAEEffect *effect);

CMENodeRef mammon_graph_manager_createFileSourceNode(CMEGraphManager *graph_mgr, CMEFileSource *source);

CMENodeRef mammon_graph_manager_createPositionalFileSourceNode(CMEGraphManager *graph_mgr, CMEFileSource *source, CMETransportTime pos);

CMENodeRef mammon_graph_manager_createOscillatorNode(CMEGraphManager *graph_mgr);

CMENodeRef mammon_graph_manager_createNoiseNode(CMEGraphManager *graph_mgr);

CMENodeRef mammon_graph_manager_createADSRNode(CMEGraphManager *graph_mgr);

CMENodeRef mammon_graph_manager_createAmbisonicBinauralDecoderNode(CMEGraphManager *graph_mgr, int order, const char *sh_hrir_filename);

CMENodeRef mammon_graph_manager_createAmbisonicEncoderNode(CMEGraphManager *graph_mgr, int order);

CMENodeRef mammon_graph_manager_createDeviceInputSourceNode(CMEGraphManager *graph_mgr, size_t device_id);

CMENodeRef mammon_graph_manager_createTriggerNode(CMEGraphManager *graph_mgr, bool async);

#if defined(USE_SAMI)
CMENodeRef mammon_graph_manager_createSamiEffectorNode(CMEGraphManager *graph_mgr, int effector_type, size_t block_size);
#endif

CMENodeRef mammon_graph_manager_createRecorderNode(CMEGraphManager *graph_mgr, const CMEEncoderFormat format, bool async);

/// TODO: complete me

//CMENodeRef mammon_graph_manager_createExtractorNode(CMEGraphManager *graph_mgr, std::shared_ptr<Extractor>);

// int mammon_graph_manager_loadGraph(istream);

// int mammon_graph_manager_saveGraph(ostream);

#ifdef __cplusplus
}
#endif

#endif /* mammon_engine_cme_graph_manager_h */
