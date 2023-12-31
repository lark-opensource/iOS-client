//
// Created by bytedance on 2021/6/25.
//
#include "IdGenerator.h"

davinci::executor::IDGenerator &davinci::executor::IDGenerator::get() {
    static IDGenerator m_pInstance;
    return m_pInstance;
}

int64_t davinci::executor::IDGenerator::generateId() {
    return idGenerator++;
}
