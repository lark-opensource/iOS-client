//
//  cme_node.h
//  mammon_engine
//

#ifndef mammon_engine_cme_nodes_h
#define mammon_engine_cme_nodes_h

#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>

#include "cme_type_defs.h"

#ifdef __cplusplus
extern "C" {
#endif

/// 节点类型
typedef void * CMENodeRef;


//////////////////// Node base APIs ////////////////////

int mammon_node_getId(CMENodeRef node);

int mammon_node_getType(CMENodeRef node);

size_t mammon_node_getLatency(CMENodeRef node);

size_t mammon_node_getMaxLatency(CMENodeRef node);

/// connect two nodes，from src_node->pout(0) to dest_node->pin(0)
void mammon_node_connectNodes(CMENodeRef src_node, CMENodeRef dest_node);

/// connect two nodes，from src_node->pout(oport) to dest_node->pin(iport)
void mammon_node_connectPorts(CMENodeRef src_node, size_t oport, CMENodeRef dest_node, size_t iport);


//////////////////// Source Node APIs ////////////////////

void mammon_source_node_start(CMENodeRef node);

void mammon_source_node_stop(CMENodeRef node);

bool mammon_source_node_getLoop(CMENodeRef node);

void mammon_source_node_setLoop(CMENodeRef node, bool loop);

CMETransportTime mammon_positional_buffer_source_node_getPosition(CMENodeRef node);

void mammon_positional_buffer_source_node_setPosition(CMENodeRef node, CMETransportTime position);

CMETransportTime mammon_positional_file_source_node_getPosition(CMENodeRef node);

void mammon_positional_file_source_node_setPosition(CMENodeRef node, CMETransportTime position);


//////////////////// SamiEffectorNode APIs ////////////////////
#if defined(USE_SAMI)
 void mammon_SamiEffectorNode_pushMidiEvent(CMENodeRef sami_effector_node, int port_index, int midi_type, int channel, int second_byte, int third_byte);

void mammon_SamiEffectorNode_pushParameter(CMENodeRef sami_effector_node, int port_number, int parameter_index, float value);
#endif

#ifdef __cplusplus
}
#endif

#endif /* mammon_engine_cme_nodes_h */
