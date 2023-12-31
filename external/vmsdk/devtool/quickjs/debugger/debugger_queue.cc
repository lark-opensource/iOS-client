// Copyright 2019 The Lynx Authors. All rights reserved.

#include "devtool/quickjs/debugger/debugger_queue.h"

struct node *InitNode(const char *content) {
  struct node *new_node;
  if (content && (new_node = (struct node *)(malloc(sizeof(struct node))))) {
    new_node->content = (char *)malloc(sizeof(char) * (strlen(content) + 1));
    if (new_node->content) {
      strcpy(new_node->content, content);
      new_node->p_next = nullptr;
      return new_node;
    }
  }
  return nullptr;
}

void DeleteQueue(struct queue *q) {
  struct node *head_node = q->p_head;
  while (head_node) {
    struct node *node = head_node;
    head_node = head_node->p_next;
    free(node->content);
    free(node);
  }
  free(q);
}

struct queue *InitQueue() {
  struct queue *q;
  q = (struct queue *)malloc(sizeof(struct queue));
  if (q) {
    q->p_head = NULL;
    q->p_tail = NULL;
  }
  return q;
};

void PushBackQueue(struct queue *q, const char *content) {
  struct node *new_node;
  new_node = InitNode(content);
  if (q->p_head == NULL) {
    q->p_head = new_node;
    q->p_tail = new_node;
  } else {
    q->p_tail->p_next = new_node;
    q->p_tail = new_node;
  }
}

char *GetFrontQueue(struct queue *q) {
  char *content = NULL;
  if (q->p_head == NULL) {
    content = nullptr;
  } else {
    content = q->p_head->content;
  }
  return content;
}

void PopFrontQueue(struct queue *q) {
  if (q->p_head) {
    struct node *head_node = q->p_head;
    q->p_head = q->p_head->p_next;
    free(head_node);
  }
}

bool QueueIsEmpty(struct queue *q) { return !(q->p_head); }