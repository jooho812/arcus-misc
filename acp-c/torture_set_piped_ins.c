/*
 * acp-c : Arcus C Client Performance benchmark program
 * Copyright 2017 JaM2in Co., Ltd.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <netinet/in.h>
#include <assert.h>

#include "libmemcached/memcached.h"
#include "common.h"
#include "keyset.h"
#include "valueset.h"
#include "client_profile.h"
#include "client.h"

static int
do_set_test(struct client *cli)
{
  int ok, i, keylen, base;
  const char *key;
  uint32_t flags = 20;
  int32_t exptime = 100;
  uint32_t maxcount = MEMCACHED_COLL_MAX_PIPED_CMD_SIZE; /* 500 */

  memcached_coll_create_attrs_st attr;
  memcached_return rc;
  memcached_return piped_rc;
  memcached_return results[MEMCACHED_COLL_MAX_PIPED_CMD_SIZE];

  char **values = (char **)malloc(sizeof(char *) * MEMCACHED_COLL_MAX_PIPED_CMD_SIZE);
  size_t valuelengths[MEMCACHED_COLL_MAX_PIPED_CMD_SIZE];

  for (i=0; i<maxcount; i++) {
    valuelengths[i] = valueset_get_value(cli->vs, (uint8_t **)&values[i]);
    assert(values[i] != NULL && valuelengths[i] > 0 && valuelengths[i] <= 4096);
  }

  // Pick a key
  key = keyset_get_key(cli->ks, &base);
  keylen = strlen(key);
  
  // Create a set item
  if (0 != client_before_request(cli))
    return -1;
  
  memcached_coll_create_attrs_init(&attr, flags, exptime, maxcount);
  rc = memcached_sop_create(cli->next_mc, key, keylen, &attr);
  ok = (rc == MEMCACHED_SUCCESS);
  if (!ok) {
    print_log("sop create failed. id=%d key=%s rc=%d(%s)", cli->id, key,
      rc, memcached_strerror(NULL, rc));
  }
  if (0 != client_after_request(cli, ok))
    return -1;
  
  // Insert piped elements
  if (0 != client_before_request(cli))
    return -1;
    
  rc = memcached_sop_piped_insert(cli->next_mc, key, keylen,
                            MEMCACHED_COLL_MAX_PIPED_CMD_SIZE,
                            (const char * const *)values, valuelengths,
                            NULL, results, &piped_rc);

  for (i=0; i<maxcount; i++)
  {
    valueset_return_value(cli->vs, (uint8_t *)values[i]);
  }
  free((void*)values);

  ok = (rc == MEMCACHED_SUCCESS && piped_rc == MEMCACHED_ALL_SUCCESS);
  for (i=0; i<maxcount; i++) {
    if (results[i] != MEMCACHED_STORED) {
      ok = results[i];
      break;
    }
  }
  if (!ok) {
    print_log("sop piped insert failed. id=%d key=%s rc=%d(%s)",
      cli->id, key, rc, memcached_strerror(NULL, results[i]));
  }
  if (0 != client_after_request(cli, ok))
    return -1;
  
  return 0;
}

static int
do_test(struct client *cli)
{
  if (0 != do_set_test(cli))
    return -1; // Stop the test
  
  return 0; // Do another test
}

static struct client_profile default_profile = {
  .do_test = do_test,
};

struct client_profile *
torture_set_piped_ins_init(void)
{
  return &default_profile;
}
