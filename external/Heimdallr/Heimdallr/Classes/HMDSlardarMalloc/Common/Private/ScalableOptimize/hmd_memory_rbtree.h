/*
 * Copyright (c) 2009-2019 Apple Inc. All rights reserved.
 *
 * @APPLE_OSREFERENCE_LICENSE_HEADER_START@
 *
 * This file contains Original Code and/or Modifications of Original Code
 * as defined in and that are subject to the Apple Public Source License
 * Version 2.0 (the 'License'). You may not use this file except in
 * compliance with the License. The rights granted to you under the License
 * may not be used to create, or enable the creation or redistribution of,
 * unlawful or unlicensed copies of an Apple operating system, or to
 * circumvent, violate, or enable the circumvention or violation of, any
 * terms of an Apple operating system software license agreement.
 *
 * Please obtain a copy of the License at
 * http://www.opensource.apple.com/apsl/ and read it before using this file.
 *
 * The Original Code and all software distributed under the License are
 * distributed on an 'AS IS' basis, WITHOUT WARRANTY OF ANY KIND, EITHER
 * EXPRESS OR IMPLIED, AND APPLE HEREBY DISCLAIMS ALL SUCH WARRANTIES,
 * INCLUDING WITHOUT LIMITATION, ANY WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE, QUIET ENJOYMENT OR NON-INFRINGEMENT.
 * Please see the License for the specific language governing rights and
 * limitations under the License.
 *
 * @APPLE_OSREFERENCE_LICENSE_HEADER_END@
 */

#ifndef file_fragment_rbtree_h
#define file_fragment_rbtree_h

/*
 * This file defines data structures for red-black trees.
 *
 * A red-black tree is a binary search tree with the node color as an
 * extra attribute.  It fulfills a set of conditions:
 *    - every search path from the root to a leaf consists of the
 *      same number of black nodes,
 *    - each red node (except for the root) has a black parent,
 *    - each leaf node is black.
 *
 * Every operation on a red-black tree is bounded as O(lg n).
 * The maximum height of a red-black tree is 2lg (n+1).
 */

#define RB_HEAD(name, type)                                             \
struct name {                                                           \
    struct type *rbh_root; /* root of the tree */                   \
}

#define RB_INITIALIZER(root)                                            \
    { NULL }

#define RB_INIT(root) do {                                              \
    (root)->rbh_root = NULL;                                        \
} while ( /*CONSTCOND*/ 0)

#define RB_BLACK        0
#define RB_RED          1
#define RB_PLACEHOLDER  NULL
#define RB_ENTRY(type)                                                  \
struct {                                                                \
    struct type *rbe_left;          /* left element */              \
    struct type *rbe_right;         /* right element */             \
    struct type *rbe_parent;        /* parent element */            \
}

#define RB_COLOR_MASK                   (uintptr_t)0x1
#define RB_LEFT(elm, field)             (elm)->field.rbe_left
#define RB_RIGHT(elm, field)            (elm)->field.rbe_right
#define _RB_PARENT(elm, field)          (elm)->field.rbe_parent
#define RB_ROOT(head)                   (head)->rbh_root
#define RB_EMPTY(head)                  (RB_ROOT(head) == NULL)

#define RB_SET(name, elm, parent, field) do {                                   \
    name##_RB_SETPARENT(elm, parent);                                       \
    RB_LEFT(elm, field) = RB_RIGHT(elm, field) = NULL;              \
    name##_RB_SETCOLOR(elm, RB_RED);                                \
} while ( /*CONSTCOND*/ 0)

#define RB_SET_BLACKRED(name, black, red, field) do {                           \
    name##_RB_SETCOLOR(black,  RB_BLACK);                           \
    name##_RB_SETCOLOR(red, RB_RED);                                        \
} while ( /*CONSTCOND*/ 0)

#ifndef RB_AUGMENT
#define RB_AUGMENT(x) (void)(x)
#endif

#define RB_ROTATE_LEFT(name, head, elm, tmp, field) do {                        \
    (tmp) = RB_RIGHT(elm, field);                                   \
    if ((RB_RIGHT(elm, field) = RB_LEFT(tmp, field)) != NULL) {     \
            name##_RB_SETPARENT(RB_LEFT(tmp, field),(elm));         \
    }                                                               \
    RB_AUGMENT(elm);                                                \
    if (name##_RB_SETPARENT(tmp, name##_RB_GETPARENT(elm)) != NULL) {       \
            if ((elm) == RB_LEFT(name##_RB_GETPARENT(elm), field))  \
                    RB_LEFT(name##_RB_GETPARENT(elm), field) = (tmp);       \
            else                                                    \
                    RB_RIGHT(name##_RB_GETPARENT(elm), field) = (tmp);      \
    } else                                                          \
            (head)->rbh_root = (tmp);                               \
    RB_LEFT(tmp, field) = (elm);                                    \
    name##_RB_SETPARENT(elm, (tmp));                                        \
    RB_AUGMENT(tmp);                                                \
    if ((name##_RB_GETPARENT(tmp)))                                 \
            RB_AUGMENT(name##_RB_GETPARENT(tmp));                   \
} while ( /*CONSTCOND*/ 0)

#define RB_ROTATE_RIGHT(name, head, elm, tmp, field) do {                       \
    (tmp) = RB_LEFT(elm, field);                                    \
    if ((RB_LEFT(elm, field) = RB_RIGHT(tmp, field)) != NULL) {     \
            name##_RB_SETPARENT(RB_RIGHT(tmp, field), (elm));               \
    }                                                               \
    RB_AUGMENT(elm);                                                \
    if (name##_RB_SETPARENT(tmp, name##_RB_GETPARENT(elm)) != NULL) {       \
            if ((elm) == RB_LEFT(name##_RB_GETPARENT(elm), field))  \
                    RB_LEFT(name##_RB_GETPARENT(elm), field) = (tmp);       \
            else                                                    \
                    RB_RIGHT(name##_RB_GETPARENT(elm), field) = (tmp);      \
    } else                                                          \
            (head)->rbh_root = (tmp);                               \
    RB_RIGHT(tmp, field) = (elm);                                   \
    name##_RB_SETPARENT(elm, tmp);                                  \
    RB_AUGMENT(tmp);                                                \
    if ((name##_RB_GETPARENT(tmp)))                                 \
            RB_AUGMENT(name##_RB_GETPARENT(tmp));                   \
} while ( /*CONSTCOND*/ 0)

/* Generates prototypes and inline functions */
#define RB_PROTOTYPE(name, type, field, cmp)                            \
void name##_RB_INSERT_COLOR(struct name *, struct type *);      \
void name##_RB_REMOVE_COLOR(struct name *, struct type *, struct type *);\
struct type *name##_RB_REMOVE(struct name *, struct type *);            \
struct type *name##_RB_INSERT(struct name *, struct type *);            \
struct type *name##_RB_FIND(struct name *, struct type *);              \
struct type *name##_RB_NFIND(struct name *, struct type *);             \
struct type *name##_RB_NEXT(struct type *);                             \
struct type *name##_RB_MINMAX(struct name *, int);                      \
struct type *name##_RB_GETPARENT(struct type*);                         \
struct type *name##_RB_SETPARENT(struct type*, struct type*);           \
int name##_RB_GETCOLOR(struct type*);                                   \
void name##_RB_SETCOLOR(struct type*,int);

/* Generates prototypes (with storage class) and inline functions */
#define RB_PROTOTYPE_SC(_sc_, name, type, field, cmp)                   \
_sc_ void name##_RB_INSERT_COLOR(struct name *, struct type *);         \
_sc_ void name##_RB_REMOVE_COLOR(struct name *, struct type *, struct type *); \
_sc_ struct type *name##_RB_REMOVE(struct name *, struct type *);       \
_sc_ struct type *name##_RB_INSERT(struct name *, struct type *);       \
_sc_ struct type *name##_RB_FIND(struct name *, struct type *);         \
_sc_ struct type *name##_RB_NFIND(struct name *, struct type *);        \
_sc_ struct type *name##_RB_NEXT(struct type *);                        \
_sc_ struct type *name##_RB_MINMAX(struct name *, int);                 \
_sc_ struct type *name##_RB_GETPARENT(struct type*);                    \
_sc_ struct type *name##_RB_SETPARENT(struct type*, struct type*);                      \
_sc_ int name##_RB_GETCOLOR(struct type*);                      \
_sc_ void name##_RB_SETCOLOR(struct type*,int)


/* Main rb operation.
 * Moves node close to the key of elm to top
 */
#define RB_GENERATE(name, type, field, cmp)                             \
struct type *name##_RB_GETPARENT(struct type *elm) {                            \
    struct type *parent = _RB_PARENT(elm, field);                   \
    if( parent != NULL) {                                           \
            parent = (struct type*)((uintptr_t)parent & ~RB_COLOR_MASK);\
            return( (struct type*) ( (parent == (struct type*) RB_PLACEHOLDER) ? NULL: parent));\
    }                                                               \
    return((struct type*)NULL);                                     \
}                                                                       \
int name##_RB_GETCOLOR(struct type *elm) {                                      \
    int color = 0;                                                  \
    color = (int)((uintptr_t)_RB_PARENT(elm,field) & RB_COLOR_MASK);\
    return(color);                                                  \
}                                                                       \
void name##_RB_SETCOLOR(struct type *elm,int color) {                           \
    struct type *parent = name##_RB_GETPARENT(elm);                 \
    if(parent == (struct type*)NULL)                                \
            parent = (struct type*) RB_PLACEHOLDER;                 \
    _RB_PARENT(elm, field) = (struct type*)((uintptr_t)parent | (unsigned int)color);\
}                                                                       \
struct type *name##_RB_SETPARENT(struct type *elm, struct type *parent) {       \
    int color = name##_RB_GETCOLOR(elm);                                    \
    _RB_PARENT(elm, field) = parent;                                \
    if(color) name##_RB_SETCOLOR(elm, color);                               \
    return(name##_RB_GETPARENT(elm));                                       \
}                                                                       \
                                                                        \
void                                                                    \
name##_RB_INSERT_COLOR(struct name *head, struct type *elm)             \
{                                                                       \
    struct type *parent, *gparent, *tmp;                            \
    while ((parent = name##_RB_GETPARENT(elm)) != NULL &&           \
        name##_RB_GETCOLOR(parent) == RB_RED) {                     \
            gparent = name##_RB_GETPARENT(parent);                  \
            if (parent == RB_LEFT(gparent, field)) {                \
                    tmp = RB_RIGHT(gparent, field);                 \
                    if (tmp && name##_RB_GETCOLOR(tmp) == RB_RED) { \
                            name##_RB_SETCOLOR(tmp,  RB_BLACK);     \
                            RB_SET_BLACKRED(name, parent, gparent, field);\
                            elm = gparent;                          \
                            continue;                               \
                    }                                               \
                    if (RB_RIGHT(parent, field) == elm) {           \
                            RB_ROTATE_LEFT(name, head, parent, tmp, field);\
                            tmp = parent;                           \
                            parent = elm;                           \
                            elm = tmp;                              \
                    }                                               \
                    RB_SET_BLACKRED(name, parent, gparent, field);  \
                    RB_ROTATE_RIGHT(name,head, gparent, tmp, field);        \
            } else {                                                \
                    tmp = RB_LEFT(gparent, field);                  \
                    if (tmp && name##_RB_GETCOLOR(tmp) == RB_RED) { \
                            name##_RB_SETCOLOR(tmp,  RB_BLACK);     \
                            RB_SET_BLACKRED(name, parent, gparent, field);\
                            elm = gparent;                          \
                            continue;                               \
                    }                                               \
                    if (RB_LEFT(parent, field) == elm) {            \
                            RB_ROTATE_RIGHT(name, head, parent, tmp, field);\
                            tmp = parent;                           \
                            parent = elm;                           \
                            elm = tmp;                              \
                    }                                               \
                    RB_SET_BLACKRED(name, parent, gparent, field);  \
                    RB_ROTATE_LEFT(name, head, gparent, tmp, field);        \
            }                                                       \
    }                                                               \
    name##_RB_SETCOLOR(head->rbh_root,  RB_BLACK);                  \
}                                                                       \
                                                                        \
void                                                                    \
name##_RB_REMOVE_COLOR(struct name *head, struct type *parent, struct type *elm) \
{                                                                       \
    struct type *tmp;                                               \
    while ((elm == NULL || name##_RB_GETCOLOR(elm) == RB_BLACK) &&  \
        elm != RB_ROOT(head)) {                                     \
            if (RB_LEFT(parent, field) == elm) {                    \
                    tmp = RB_RIGHT(parent, field);                  \
                    if (name##_RB_GETCOLOR(tmp) == RB_RED) {                \
                            RB_SET_BLACKRED(name, tmp, parent, field);      \
                            RB_ROTATE_LEFT(name, head, parent, tmp, field);\
                            tmp = RB_RIGHT(parent, field);          \
                    }                                               \
                    if ((RB_LEFT(tmp, field) == NULL ||             \
                        name##_RB_GETCOLOR(RB_LEFT(tmp, field)) == RB_BLACK) &&\
                        (RB_RIGHT(tmp, field) == NULL ||            \
                        name##_RB_GETCOLOR(RB_RIGHT(tmp, field)) == RB_BLACK)) {\
                            name##_RB_SETCOLOR(tmp,  RB_RED);               \
                            elm = parent;                           \
                            parent = name##_RB_GETPARENT(elm);              \
                    } else {                                        \
                            if (RB_RIGHT(tmp, field) == NULL ||     \
                                name##_RB_GETCOLOR(RB_RIGHT(tmp, field)) == RB_BLACK) {\
                                    struct type *oleft;             \
                                    if ((oleft = RB_LEFT(tmp, field)) \
                                        != NULL)                    \
                                            name##_RB_SETCOLOR(oleft,  RB_BLACK);\
                                    name##_RB_SETCOLOR(tmp, RB_RED);        \
                                    RB_ROTATE_RIGHT(name, head, tmp, oleft, field);\
                                    tmp = RB_RIGHT(parent, field);  \
                            }                                       \
                            name##_RB_SETCOLOR(tmp, (name##_RB_GETCOLOR(parent)));\
                            name##_RB_SETCOLOR(parent, RB_BLACK);   \
                            if (RB_RIGHT(tmp, field))               \
                                    name##_RB_SETCOLOR(RB_RIGHT(tmp, field),RB_BLACK);\
                            RB_ROTATE_LEFT(name, head, parent, tmp, field);\
                            elm = RB_ROOT(head);                    \
                            break;                                  \
                    }                                               \
            } else {                                                \
                    tmp = RB_LEFT(parent, field);                   \
                    if (name##_RB_GETCOLOR(tmp) == RB_RED) {                \
                            RB_SET_BLACKRED(name, tmp, parent, field);      \
                            RB_ROTATE_RIGHT(name, head, parent, tmp, field);\
                            tmp = RB_LEFT(parent, field);           \
                    }                                               \
                    if ((RB_LEFT(tmp, field) == NULL ||             \
                        name##_RB_GETCOLOR(RB_LEFT(tmp, field)) == RB_BLACK) &&\
                        (RB_RIGHT(tmp, field) == NULL ||            \
                        name##_RB_GETCOLOR(RB_RIGHT(tmp, field)) == RB_BLACK)) {\
                            name##_RB_SETCOLOR(tmp, RB_RED);                \
                            elm = parent;                           \
                            parent = name##_RB_GETPARENT(elm);              \
                    } else {                                        \
                            if (RB_LEFT(tmp, field) == NULL ||      \
                                name##_RB_GETCOLOR(RB_LEFT(tmp, field)) == RB_BLACK) {\
                                    struct type *oright;            \
                                    if ((oright = RB_RIGHT(tmp, field)) \
                                        != NULL)                    \
                                            name##_RB_SETCOLOR(oright,  RB_BLACK);\
                                    name##_RB_SETCOLOR(tmp,  RB_RED);       \
                                    RB_ROTATE_LEFT(name, head, tmp, oright, field);\
                                    tmp = RB_LEFT(parent, field);   \
                            }                                       \
                            name##_RB_SETCOLOR(tmp,(name##_RB_GETCOLOR(parent)));\
                            name##_RB_SETCOLOR(parent, RB_BLACK);   \
                            if (RB_LEFT(tmp, field))                \
                                    name##_RB_SETCOLOR(RB_LEFT(tmp, field), RB_BLACK);\
                            RB_ROTATE_RIGHT(name, head, parent, tmp, field);\
                            elm = RB_ROOT(head);                    \
                            break;                                  \
                    }                                               \
            }                                                       \
    }                                                               \
    if (elm)                                                        \
            name##_RB_SETCOLOR(elm,  RB_BLACK);                     \
}                                                                       \
                                                                        \
struct type *                                                           \
name##_RB_REMOVE(struct name *head, struct type *elm)                   \
{                                                                       \
    struct type *child, *parent, *old = elm;                        \
    int color;                                                      \
    if (RB_LEFT(elm, field) == NULL)                                \
            child = RB_RIGHT(elm, field);                           \
    else if (RB_RIGHT(elm, field) == NULL)                          \
            child = RB_LEFT(elm, field);                            \
    else {                                                          \
            struct type *left;                                      \
            elm = RB_RIGHT(elm, field);                             \
            while ((left = RB_LEFT(elm, field)) != NULL)            \
                    elm = left;                                     \
            child = RB_RIGHT(elm, field);                           \
            parent = name##_RB_GETPARENT(elm);                              \
            color = name##_RB_GETCOLOR(elm);                                \
            if (child)                                              \
                    name##_RB_SETPARENT(child, parent);             \
            if (parent) {                                           \
                    if (RB_LEFT(parent, field) == elm)              \
                            RB_LEFT(parent, field) = child;         \
                    else                                            \
                            RB_RIGHT(parent, field) = child;        \
                    RB_AUGMENT(parent);                             \
            } else                                                  \
                    RB_ROOT(head) = child;                          \
            if (name##_RB_GETPARENT(elm) == old)                    \
                    parent = elm;                                   \
            (elm)->field = (old)->field;                            \
            if (name##_RB_GETPARENT(old)) {                         \
                    if (RB_LEFT(name##_RB_GETPARENT(old), field) == old)\
                            RB_LEFT(name##_RB_GETPARENT(old), field) = elm;\
                    else                                            \
                            RB_RIGHT(name##_RB_GETPARENT(old), field) = elm;\
                    RB_AUGMENT(name##_RB_GETPARENT(old));           \
            } else                                                  \
                    RB_ROOT(head) = elm;                            \
            name##_RB_SETPARENT(RB_LEFT(old, field), elm);          \
            if (RB_RIGHT(old, field))                               \
                    name##_RB_SETPARENT(RB_RIGHT(old, field), elm); \
            if (parent) {                                           \
                    left = parent;                                  \
                    do {                                            \
                            RB_AUGMENT(left);                       \
                    } while ((left = name##_RB_GETPARENT(left)) != NULL); \
            }                                                       \
            goto color;                                             \
    }                                                               \
    parent = name##_RB_GETPARENT(elm);                                      \
    color = name##_RB_GETCOLOR(elm);                                        \
    if (child)                                                      \
            name##_RB_SETPARENT(child, parent);                     \
    if (parent) {                                                   \
            if (RB_LEFT(parent, field) == elm)                      \
                    RB_LEFT(parent, field) = child;                 \
            else                                                    \
                    RB_RIGHT(parent, field) = child;                \
            RB_AUGMENT(parent);                                     \
    } else                                                          \
            RB_ROOT(head) = child;                                  \
color:                                                                  \
    if (color == RB_BLACK)                                          \
            name##_RB_REMOVE_COLOR(head, parent, child);            \
    return (old);                                                   \
}                                                                       \
                                                                        \
/* Inserts a node into the RB tree */                                   \
struct type *                                                           \
name##_RB_INSERT(struct name *head, struct type *elm)                   \
{                                                                       \
    struct type *tmp;                                               \
    struct type *parent = NULL;                                     \
    int comp = 0;                                                   \
    tmp = RB_ROOT(head);                                            \
    while (tmp) {                                                   \
            parent = tmp;                                           \
            comp = (cmp)(elm, parent);                              \
            if (comp < 0)                                           \
                    tmp = RB_LEFT(tmp, field);                      \
            else                                                    \
                    tmp = RB_RIGHT(tmp, field);                     \
            /*else if (comp > 0)                                      \
                    tmp = RB_RIGHT(tmp, field);                     \
            else                                                    \
                    return (tmp);*/                                 \
    }                                                               \
    RB_SET(name, elm, parent, field);                                       \
    if (parent != NULL) {                                           \
            if (comp < 0)                                           \
                    RB_LEFT(parent, field) = elm;                   \
            else                                                    \
                    RB_RIGHT(parent, field) = elm;                  \
            RB_AUGMENT(parent);                                     \
    } else                                                          \
            RB_ROOT(head) = elm;                                    \
    name##_RB_INSERT_COLOR(head, elm);                              \
    return (NULL);                                                  \
}                                                                       \
                                                                        \
/* Finds the node with the same key as elm */                           \
struct type *                                                           \
name##_RB_FIND(struct name *head, struct type *elm)                     \
{                                                                       \
    struct type *tmp = RB_ROOT(head);                               \
    int comp;                                                       \
    while (tmp) {                                                   \
            comp = cmp(elm, tmp);                                   \
            if (comp < 0)                                           \
                    tmp = RB_LEFT(tmp, field);                      \
            else if (comp > 0)                                      \
                    tmp = RB_RIGHT(tmp, field);                     \
            else                                                    \
                    return (tmp);                                   \
    }                                                               \
    return (NULL);                                                  \
}                                                                       \
                                                                        \
/* Finds the first node greater than or equal to the search key */      \
__attribute__((unused))                                                 \
struct type *                                                           \
name##_RB_NFIND(struct name *head, struct type *elm)                    \
{                                                                       \
    struct type *tmp = RB_ROOT(head);                               \
    struct type *res = NULL;                                        \
    int comp;                                                       \
    while (tmp) {                                                   \
            comp = cmp(elm, tmp);                                   \
            if (comp < 0) {                                         \
                    res = tmp;                                      \
                    tmp = RB_LEFT(tmp, field);                      \
            }                                                       \
            else if (comp > 0)                                      \
                    tmp = RB_RIGHT(tmp, field);                     \
            else                                                    \
                    return (tmp);                                   \
    }                                                               \
    return (res);                                                   \
}                                                                       \
                                                                        \
/* ARGSUSED */                                                          \
struct type *                                                           \
name##_RB_NEXT(struct type *elm)                                        \
{                                                                       \
    if (RB_RIGHT(elm, field)) {                                     \
            elm = RB_RIGHT(elm, field);                             \
            while (RB_LEFT(elm, field))                             \
                    elm = RB_LEFT(elm, field);                      \
    } else {                                                        \
            if (name##_RB_GETPARENT(elm) &&                         \
                (elm == RB_LEFT(name##_RB_GETPARENT(elm), field)))  \
                    elm = name##_RB_GETPARENT(elm);                 \
            else {                                                  \
                    while (name##_RB_GETPARENT(elm) &&                      \
                        (elm == RB_RIGHT(name##_RB_GETPARENT(elm), field)))\
                            elm = name##_RB_GETPARENT(elm);         \
                    elm = name##_RB_GETPARENT(elm);                 \
            }                                                       \
    }                                                               \
    return (elm);                                                   \
}                                                                       \
                                                                        \
struct type *                                                           \
name##_RB_MINMAX(struct name *head, int val)                            \
{                                                                       \
    struct type *tmp = RB_ROOT(head);                               \
    struct type *parent = NULL;                                     \
    while (tmp) {                                                   \
            parent = tmp;                                           \
            if (val < 0)                                            \
                    tmp = RB_LEFT(tmp, field);                      \
            else                                                    \
                    tmp = RB_RIGHT(tmp, field);                     \
    }                                                               \
    return (parent);                                                \
}


#define RB_PROTOTYPE_PREV(name, type, field, cmp)                       \
    RB_PROTOTYPE(name, type, field, cmp)                            \
struct type *name##_RB_PREV(struct type *);


#define RB_PROTOTYPE_SC_PREV(_sc_, name, type, field, cmp)              \
    RB_PROTOTYPE_SC(_sc_, name, type, field, cmp);                  \
_sc_ struct type *name##_RB_PREV(struct type *)

#define RB_GENERATE_PREV(name, type, field, cmp)                        \
    RB_GENERATE(name, type, field, cmp);                            \
struct type *                                                           \
name##_RB_PREV(struct type *elm)                                        \
{                                                                       \
    if (RB_LEFT(elm, field)) {                                      \
            elm = RB_LEFT(elm, field);                              \
            while (RB_RIGHT(elm, field))                            \
                    elm = RB_RIGHT(elm, field);                     \
    } else {                                                        \
            if (name##_RB_GETPARENT(elm) &&                         \
                (elm == RB_RIGHT(name##_RB_GETPARENT(elm), field))) \
                    elm = name##_RB_GETPARENT(elm);                 \
            else {                                                  \
                    while (name##_RB_GETPARENT(elm) &&              \
                        (elm == RB_LEFT(name##_RB_GETPARENT(elm), field)))\
                            elm = name##_RB_GETPARENT(elm);         \
                    elm = name##_RB_GETPARENT(elm);                 \
            }                                                       \
    }                                                               \
    return (elm);                                                   \
}                                                                       \

#define RB_NEGINF       -1
#define RB_INF  1

#define RB_INSERT(name, x, y)   name##_RB_INSERT(x, y)
#define RB_REMOVE(name, x, y)   name##_RB_REMOVE(x, y)
#define RB_FIND(name, x, y)     name##_RB_FIND(x, y)
#define RB_NFIND(name, x, y)    name##_RB_NFIND(x, y)
#define RB_NEXT(name, x, y)     name##_RB_NEXT(y)
#define RB_PREV(name, x, y)     name##_RB_PREV(y)
#define RB_MIN(name, x)         name##_RB_MINMAX(x, RB_NEGINF)
#define RB_MAX(name, x)         name##_RB_MINMAX(x, RB_INF)

#define RB_FOREACH(x, name, head)                                       \
    for ((x) = RB_MIN(name, head);                                  \
         (x) != NULL;                                               \
         (x) = name##_RB_NEXT(x))

#define RB_FOREACH_FROM(x, name, y)                                     \
    for ((x) = (y);                                                 \
        ((x) != NULL) && ((y) = name##_RB_NEXT(x), (x) != NULL);    \
        (x) = (y))

#define RB_FOREACH_REVERSE_FROM(x, name, y)                             \
    for ((x) = (y);                                                 \
        ((x) != NULL) && ((y) = name##_RB_PREV(x), (x) != NULL);    \
         (x) = (y))

#define RB_FOREACH_SAFE(x, name, head, y)                               \
    for ((x) = RB_MIN(name, head);                                  \
        ((x) != NULL) && ((y) = name##_RB_NEXT(x), (x) != NULL);    \
         (x) = (y))


#endif /* file_fragment_rbtree_h */
