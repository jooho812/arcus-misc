/* -*- Mode: Java; tab-width: 2; c-basic-offset: 2; indent-tabs-mode: nil -*- */
/*
 * acp-java : Arcus Java Client Performance benchmark program
 * Copyright 2013-2014 NAVER Corp.
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
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;

import net.spy.memcached.collection.CollectionAttributes;
import net.spy.memcached.collection.CollectionOverflowAction;
import net.spy.memcached.collection.ElementValueType;
import net.spy.memcached.internal.CollectionFuture;

public class tiny_btree implements client_profile {
  public boolean do_test(client cli) {
    try {
      if (!do_btree_test(cli))
        return false;
    } catch (Exception e) {
      System.out.printf("client_profile exception. id=%d exception=%s\n", 
                        cli.id, e.toString());
      if (cli.conf.print_stack_trace)
        e.printStackTrace();
    }
    return true;
  }

  // 4-element btree
  
  public boolean do_btree_test(client cli) throws Exception {
    // Pick a key
    String key = cli.ks.get_key();

    String[] temp = key.split("-");
    long base = Long.parseLong(temp[1]);
    base = base * 64*1024;

    // Create a btree item
    if (!cli.before_request())
      return false;
    ElementValueType vtype = ElementValueType.BYTEARRAY;
    CollectionAttributes attr = 
      new CollectionAttributes(10000, new Long(10),
                               CollectionOverflowAction.smallest_trim);
    CollectionFuture<Boolean> fb = cli.next_ac.asyncBopCreate(key, vtype, attr);
    boolean ok = fb.get(cli.conf.client_timeout, TimeUnit.MILLISECONDS);
    if (!ok) {
      System.out.printf("bop create failed. id=%d key=%s: %s\n", cli.id,
                        key, fb.getOperationStatus().getResponse());
    }
    if (!cli.after_request(ok))
      return false;
    if (!ok)
      return true;

    // Insert elements
    for (long bkey = base; bkey < base + 4; bkey++) {
      if (!cli.before_request())
        return false;
      byte[] val = cli.vset.get_value();
      assert(val.length <= 4096);
      fb = cli.next_ac.asyncBopInsert(key, bkey, null /* eflag */,
                                      val,
                                      null /* Do not auto-create item */);
      ok = fb.get(cli.conf.client_timeout, TimeUnit.MILLISECONDS);
      if (!ok) {
        System.out.printf("bop insert failed. id=%d key=%s bkey=%d: %s\n",
                          cli.id, key, bkey,
                          fb.getOperationStatus().getResponse());
      }
      if (!cli.after_request(ok))
        return false;
      if (!ok)
        return true;
    }

    return true;
  }
}
