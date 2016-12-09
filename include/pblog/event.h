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

/* Protobuf eventlog event helper functions */

#ifndef PBLOG_EVENT_H
#define PBLOG_EVENT_H

#include <stdlib.h>

#include <pblog/pblog.pb.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Encodes an event and writes it to the provided buffer.
   Returns: the encoded length in bytes or <0 on error. */
int event_encode(const pblog_Event *event, void *buf, size_t len);

/* Decodes an event and writes it to the provided event pointer.
   Returns: 0 on success, <0 on error. */
int event_decode(const void *buf, size_t len, pblog_Event *event);

/* Returns the encoded length of the event or <0 on error. */
int event_size(const pblog_Event *event);

/* Adds this extension type to list of extensions in event. Caller maintains
 * ownership of data and must free after calling pb_encode() (or use stack
 * allocated vars).
 *
 * Returns true if the extension type is successfully added, false if extension
 * type already exists or could not be added
 */
bool event_add_extension(pblog_Event *event,
                         const pb_extension_type_t *ext_type,
                         void *dest_struct);

/* Checks if the extension type was found when decoding this event. If the
 * extension was found, write out a pointer to the destination struct.
 */
bool event_has_extension(pblog_Event *event,
                         const pb_extension_type_t *ext_type,
                         void **dest_struct);

/* Initializes/destroys an event structure. */
void event_init(pblog_Event *event);
void event_free(pblog_Event *event);

/* Adds KV string data to an event. */
void event_add_kv_data(pblog_Event *event, const char *key, const char *value);

#ifdef __cplusplus
}  /* extern "C" */
#endif

#endif  /* PBLOG_EVENT_H */
