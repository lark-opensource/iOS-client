//
//  cme_graph.h
//  mammon_engine
//

#ifndef mammon_engine_cme_graph_h
#define mammon_engine_cme_graph_h

#include <stddef.h>
#include <stdint.h>
#include <stdbool.h>
#include "cme_nodes.h"

#ifdef __cplusplus
extern "C" {
#endif

typedef struct CMEAudioGraphImpl CMEAudioGraph;

typedef size_t CMENodeID;
typedef size_t CMEPortID;

typedef struct
{
    CMENodeID node;
    CMEPortID oport;
    CMEPortID iport;
} CMESignalPath;

/// Generally create graph by GraghManager not yourself
void mammon_graph_create(CMEAudioGraph **inoutGraph);

void mammon_graph_destroy(CMEAudioGraph **inoutGraph);

void mammon_graph_addNode(CMEAudioGraph *graph, CMENodeRef node);

void mammon_graph_addSinkNode(CMEAudioGraph *graph, CMENodeRef sink_node);

void mammon_graph_addDeviceInputSourceNode(CMEAudioGraph *graph, CMENodeRef device_input_src_node);

bool mammon_graph_deleteNode(CMEAudioGraph *graph, CMENodeRef node);

bool mammon_graph_deleteNodeByID(CMEAudioGraph *graph, CMENodeID node_id);

/// Get the Node object
CMENodeRef mammon_graph_getNode(CMEAudioGraph *graph, CMENodeID node_id);

bool mammon_graph_hasNode(CMEAudioGraph *graph, CMENodeID node_id);

void mammon_graph_addEdge(CMEAudioGraph *graph, CMESignalPath path, CMENodeID dest_node_id);

void mammon_graph_deleteEdge(CMEAudioGraph *graph, CMESignalPath path, CMENodeID dest_node_id);

bool mammon_graph_hasPath(CMEAudioGraph *graph, CMENodeID src_node_id, CMENodeID dest_node_id);

bool mammon_graph_hasEdge(CMEAudioGraph *graph, CMESignalPath path, CMENodeID dest_node_id);

/// DFS graph visiting,
void mammon_graph_DFSVisit(CMEAudioGraph *graph, CMENodeID node_id, void(*visitor)(CMENodeRef));

/// stringify the graph
/// @param graph graph instance to stringify
/// @param outStringRef inout dynamic allocated string reference
/// @param outSize the output string size, including the terminating char '\0'
/// @note outString is a piece of heap buffer, you have to free it yourself
void mammon_graph_toString(CMEAudioGraph *graph, char **outStringRef, size_t *outSize);

CMENodeRef mammon_graph_getSinkNode(CMEAudioGraph *graph);

// TODO: complete me
// CMEAudioGraphExecutor* mammon_graph_getExecutor(CMEAudioGraph *graph);
// void mammon_graph_setExecutor(CMEAudioGraph *graph, CMEAudioGraphExecutor* executor);
// mammon_graph_getDeviceInputNodes(CMEAudioGraph *graph);

#ifdef __cplusplus
}
#endif

#endif /* mammon_engine_cme_graph_h */
