/*
 * Copyright 2014-2016 Google Inc. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/* In-memory operations support */

#ifndef PBLOG_MEM_H
#define PBLOG_MEM_H

#include <stddef.h>
#include <stdint.h>

#include <pblog/flash.h>

#ifdef __cplusplus
extern "C" {
#endif

extern struct pblog_flash_ops pblog_mem_ops;

#ifdef __cplusplus
}  /* extern "C" */
#endif

#endif  /* PBLOG_MEM_H */
