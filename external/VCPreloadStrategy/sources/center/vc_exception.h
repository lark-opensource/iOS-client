//
// Created by 黄清 on 1/8/21.
//

#ifndef VIDEOENGINE_VC_EXCEPTION_H
#define VIDEOENGINE_VC_EXCEPTION_H
#pragma once

#include "vc_base.h"
#include <string>
VC_NAMESPACE_BEGIN

class VCException : public std::exception {
public:
    VCException(std::string msg);
    ~VCException() noexcept override;
    char const *what() const noexcept override;

protected:
    std::string mMsg;
};

class VCRuntimeError : public VCException {
public:
    VCRuntimeError(std::string const &msg);
};

class VCLogicError : public VCException {
public:
    VCLogicError(std::string const &msg);
};

/// used internally
void VCThrowRuntimeError(std::string const &msg);
/// used internally
void VCThrowLogicError(std::string const &msg);

VC_NAMESPACE_END

#endif // VIDEOENGINE_VC_EXCEPTION_H