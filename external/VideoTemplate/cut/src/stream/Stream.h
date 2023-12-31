//
// Created by zhangyeqi on 2019-12-10.
//

#ifndef CUTSAMEAPP_STREAM_H
#define CUTSAMEAPP_STREAM_H

#include <memory>

#include "StreamContext.h"
#include "StreamFunction.h"
#include "StreamSerialAndFunction.h"
#include "StreamParallelAndFunction.h"

using asve::StreamContext;
using asve::StreamFunction;
using asve::StreamSerialAndFunction;
using asve::StreamParallelAndFunction;

using namespace std::placeholders;
using std::shared_ptr;
using std::make_shared;

namespace asve {

    /**
     * 这个类只是为了方便使用 SerialStreamFunction
     *
     * @tparam IN IN
     * @tparam OUT OUT
     */
    template<typename IN, typename OUT>
    class Stream : public std::enable_shared_from_this<Stream<IN, OUT>> {
    public:

        static shared_ptr<Stream<IN, OUT>> with(shared_ptr<StreamContext> context);

        shared_ptr<Stream<IN, OUT>> begin(shared_ptr<StreamFunction<IN, OUT>> first);

        /**
         * 串行链接
         */
        template<typename OUT2>
        shared_ptr<Stream<IN, OUT2>> map(shared_ptr<StreamFunction<OUT, OUT2>> next);

        template<typename OUT2>
        shared_ptr<Stream<IN, OUT2>> mapParallel(
                shared_ptr<StreamFunction<OUT, OUT2>> first,
                shared_ptr<StreamFunction<OUT, OUT2>> second
                );

        shared_ptr<StreamFunction<IN, OUT>> end();

        Stream(shared_ptr<StreamContext> streamContext);

    private:
        shared_ptr<StreamContext> streamContext;
        shared_ptr<StreamFunction<IN, OUT>> streamFunction;
    };

    template<typename IN, typename OUT>
    shared_ptr<Stream<IN, OUT>> Stream<IN, OUT>::with(shared_ptr<StreamContext> context) {
        return make_shared<Stream<IN, OUT>>(context);
    }

    template<typename IN, typename OUT>
    Stream<IN, OUT>::Stream(shared_ptr<StreamContext> streamContext)
            : streamContext(std::move(streamContext)) {
    }

    template<typename IN, typename OUT>
    template<typename OUT2>
    shared_ptr<Stream<IN, OUT2>> Stream<IN, OUT>::map(shared_ptr<StreamFunction<OUT, OUT2>> next) {
        shared_ptr<Stream<IN, OUT2>> ret = make_shared<Stream<IN, OUT2>>(this->streamContext);
        shared_ptr<StreamSerialAndFunction<IN, OUT, OUT2>> combine =
                make_shared<StreamSerialAndFunction<IN, OUT, OUT2>>(this->streamFunction, next);
        ret->begin(combine);
        return ret;
    }

    template<typename IN, typename OUT>
    template<typename OUT2>
    shared_ptr<Stream<IN, OUT2>> Stream<IN, OUT>::mapParallel(
            shared_ptr<StreamFunction<OUT, OUT2>> nextFirst,
            shared_ptr<StreamFunction<OUT, OUT2>> nextSecond
            ) {
        shared_ptr<StreamFunction<OUT, OUT2>> parallel = nextFirst + nextSecond;
        return this->map(parallel);
    }

    template<typename IN, typename OUT>
    shared_ptr<StreamFunction<IN, OUT>> Stream<IN, OUT>::end() {
        return this->streamFunction;
    }

    template<typename IN, typename OUT>
    shared_ptr<Stream<IN, OUT>> Stream<IN, OUT>::begin(shared_ptr<StreamFunction<IN, OUT>> first) {
        this->streamFunction = std::move(first);
        this->streamFunction->setContext(streamContext);
        return this->shared_from_this();
    }
}

#endif //CUTSAMEAPP_STREAM_H
