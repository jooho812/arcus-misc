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
do_btree_test(struct client *cli)
{
  int ok, i, base;
  uint32_t flags = 20;
  int32_t exptime = 100;
  uint32_t maxcount = MEMCACHED_COLL_MAX_PIPED_CMD_SIZE; /* 500 */

  memcached_coll_create_attrs_st attr;
  memcached_return rc;
  memcached_return piped_rc;
  memcached_return results[MEMCACHED_COLL_MAX_PIPED_CMD_SIZE];

  const char **keys = (const char **)malloc(sizeof(char *) * MEMCACHED_COLL_MAX_PIPED_CMD_SIZE);
  size_t key_length[MEMCACHED_COLL_MAX_PIPED_CMD_SIZE];
  uint64_t bkey = 1;
  const char *value = "value";
  size_t value_length = 5;

  uint32_t eflag = 0;

  // Pick a key
  for (i=0; i<maxcount; i++) {
    keys[i] = keyset_get_key(cli->ks, &base);
    key_length[i] = strlen(keys[i]);
  }
  
  // Create a btree item
  if (0 != client_before_request(cli))
    return -1;
  
  memcached_coll_create_attrs_init(&attr, flags, exptime, maxcount);
  memcached_coll_create_attrs_set_overflowaction(&attr,
    OVERFLOWACTION_SMALLEST_TRIM);

  int exist_count = maxcount * 0.99;
  /* Create a btree item, 1% is not exist */
  for (i=0; i<exist_count; i++) {
    rc = memcached_bop_create(cli->next_mc, keys[i], key_length[i], &attr);
    ok = (rc == MEMCACHED_SUCCESS);
    if (!ok) {
      print_log("bop create failed. id=%d key=%s rc=%d(%s)", cli->id, keys[i],
        rc, memcached_strerror(NULL, rc));
    }
  }
  if (0 != client_after_request(cli, ok))
    return -1;
  
  // Insert piped bulk
  if (0 != client_before_request(cli))
    return -1;
    
  rc = memcached_bop_piped_insert_bulk(cli->next_mc, keys, key_length,
                                    MEMCACHED_COLL_MAX_PIPED_CMD_SIZE,
                                    bkey, (const unsigned char*)&eflag, sizeof(eflag),
                                    value, value_length,
                                    NULL, results, &piped_rc);

  ok = (rc == MEMCACHED_SUCCESS && piped_rc == MEMCACHED_SOME_SUCCESS);
  do {
    if (!ok) break;
    for (i=0; i<exist_count; i++) {
      ok = (results[i] == MEMCACHED_STORED);
      if (ok != 1) {
        print_log("bop piped insert bulk failed. id=%d key=%s bkey=%llu rc=%d(%s)",
                   cli->id, keys[i], (long long unsigned)bkey,
                   piped_rc, memcached_strerror(NULL, results[i]));
        break;
      }
    }
    if (!ok) break;
    for(; i<maxcount; i++) {
      ok = (results[i] == MEMCACHED_NOTFOUND);
      if (ok != 1) {
        print_log("bop piped insert bulk not_found failed. id=%d key=%s bkey=%llu rc=%d(%s)",
                   cli->id, keys[i], (long long unsigned)bkey,
                   piped_rc, memcached_strerror(NULL, results[i]));
        break;
      }
    }
  } while(0);

  free((void*)keys);

  if (0 != client_after_request(cli, ok))
    return -1;
  
  return 0;
}

static int
do_test(struct client *cli)
{
  if (0 != do_btree_test(cli))
    return -1; // Stop the test
  
  return 0; // Do another test
}

static struct client_profile default_profile = {
  .do_test = do_test,
};

struct client_profile *
torture_btree_piped_ins_bulk_init(void)
{
  return &default_profile;
}
