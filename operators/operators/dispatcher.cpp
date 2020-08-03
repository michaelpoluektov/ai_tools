// Copyright (c) 2020, XMOS Ltd, All rights reserved
#include "operators/dispatcher.h"

#include <cassert>
#include <cstdlib>
#include <cstring>
#include <iostream>

#include "operators/planning.h"
#include "tensorflow/lite/c/common.h"

namespace xcore {

static Dispatcher *kDispatcher = nullptr;

void SetDispatcher(Dispatcher *dispatcher) { kDispatcher = dispatcher; }

Dispatcher *GetDispatcher() {
  assert(kDispatcher);
  return kDispatcher;
}

#ifdef XCORE

// xCORE Dispatcher implementation.
// Uses a threadgroup_t to dispatch tasks to threads.
Dispatcher::Dispatcher(tflite::ErrorReporter *reporter, bool use_current_core)
    : use_current_thread_(use_current_core), reporter_(reporter) {
  group_ = thread_group_alloc();
  tasks_.size = 0;
}

Dispatcher::~Dispatcher() { thread_group_free(group_); }

TfLiteStatus Dispatcher::JoinTasks() {
  if (tasks_.size == 0) return kTfLiteOk;

  int begin = 0;

  if (use_current_thread_) {
    (tasks_.function)(tasks_.arguments[begin]);
    begin++;
  }

  int remaining_tasks = tasks_.size - begin;

  if (remaining_tasks > 0) {
    size_t stack_offset = 0;
    size_t stack_words = tasks_.stack_size / kBytesPerStackword;
    for (int i = begin; i < tasks_.size; i++) {
      thread_group_add(group_, tasks_.function, tasks_.arguments[i],
                       stack_base(&tasks_.stack[stack_offset], stack_words));
      stack_offset += tasks_.stack_size;
    }

    thread_group_start(group_);
    thread_group_wait(group_);
  }

  tasks_.size = 0;

  return kTfLiteOk;
}

#else

// x86 Dispatcher implementation.
// Uses a std::vector of std::thread to dispatch tasks to threads.
Dispatcher::Dispatcher(tflite::ErrorReporter *reporter, bool use_current_core)
    : use_current_thread_(use_current_core), reporter_(reporter) {
  tasks_.size = 0;
}

Dispatcher::~Dispatcher() {}

TfLiteStatus Dispatcher::JoinTasks() {
  if (tasks_.size == 0) return kTfLiteOk;

  int begin = 0;

  if (use_current_thread_) {
    (tasks_.function)(tasks_.arguments[begin]);
    begin++;
  }

  // Start threads
  for (int i = begin; i < tasks_.size; i++) {
    group_.push_back(std::thread(tasks_.function, tasks_.arguments[i]));
  }

  // Join threads
  for (auto &thread : group_) {
    thread.join();
  }
  group_.clear();
  tasks_.size = 0;

  return kTfLiteOk;
}

#endif  // XCORE

//**************************************
//**************************************
//**************************************
// Dispatcher methods common to
//   XCORE & x86
//**************************************
//**************************************
//**************************************

tflite::ErrorReporter *Dispatcher::GetReporter() { return reporter_; }

TfLiteStatus Dispatcher::Reset() {
  tasks_.size = 0;

  return kTfLiteOk;
}

TfLiteStatus Dispatcher::InitializeTasks(thread_function_t function,
                                         char *stack, size_t stack_size) {
  tasks_.function = function;
  tasks_.stack_size = stack_size;
  tasks_.size = 0;
  tasks_.stack = stack;

  return kTfLiteOk;
}

TfLiteStatus Dispatcher::AddTask(void *argument) {
  assert(tasks_.size < kMaxThreads);

  if (tasks_.size < kMaxThreads) {
    tasks_.arguments[tasks_.size] = argument;
    tasks_.size++;

    return kTfLiteOk;
  }

  return kTfLiteError;
}

void Dispatcher::FetchBuffer(int8_t **dest, int8_t const *src, size_t size) {
  if (IS_RAM(src)) {
    *dest = (int8_t *)src;
  } else {
    memload((void **)dest, (void *)src, size);
  }
}

void Dispatcher::FetchWeights(int8_t **dest, int8_t const *src, size_t size,
                              ChannelGroup const &changrp) {
  size_t changrp_bytes = size / changrp_len;

  if (IS_RAM(src)) {
    *dest = (int8_t *)&src[changrp.start * changrp_bytes];
  } else {
    size_t load_size;
    if ((changrp.index == 0) && (changrp.size < changrp_len))
      load_size = size;  // only one channel group so load everything
    else
      load_size = changrp.size * changrp_bytes;

    memcpy((void *)*dest, (void *)&src[changrp.start * changrp_bytes],
           load_size);
  }
}

void Dispatcher::FetchBiases(int16_t **dest, int16_t const *src, size_t size,
                             ChannelGroup const &changrp) {
  if (IS_RAM(src)) {
    *dest = (int16_t *)&src[changrp.index * bso_changrp_len];
  } else {
    memload((void **)dest, (void *)&src[changrp.index * bso_changrp_len], size);
  }
}

}  // namespace xcore