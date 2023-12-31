// Copyright 2019 The Lynx Authors. All rights reserved.
#ifndef QUICKJS_DEBUGGER_QUEUE_H
#define QUICKJS_DEBUGGER_QUEUE_H

#ifdef __cplusplus
extern "C" {
#endif

#define LENTH 10240

#include <stdlib.h>
#include <string.h>
/**
 * queue need by debugger to save protocol messages
 */
struct node {
  char *content;
  struct node *p_next;
};

struct queue {
  struct node *p_head;
  struct node *p_tail;
};

struct node *InitNode(const char *content);

void PushBackQueue(struct queue *q,
                   const char *content);  // put message to the queue

struct queue *InitQueue(void);  // init message queue

void PopFrontQueue(
    struct queue *q);  // get message from the queue, and pop the front

char *GetFrontQueue(struct queue *q);  // get message from the queue

void DeleteQueue(struct queue *q);  // delete the queue

bool QueueIsEmpty(struct queue *q);  // return if the queue is empty

#ifdef __cplusplus
}
#endif

#endif