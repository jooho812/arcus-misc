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
import java.util.Iterator;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;
import java.util.Random;

import net.spy.memcached.collection.BTreeGetResult;
import net.spy.memcached.collection.ByteArrayBKey;
import net.spy.memcached.collection.CollectionAttributes;
import net.spy.memcached.collection.CollectionOverflowAction;
import net.spy.memcached.collection.CollectionResponse;
import net.spy.memcached.collection.Element;
import net.spy.memcached.collection.ElementFlagFilter;
import net.spy.memcached.collection.ElementFlagUpdate;
import net.spy.memcached.collection.ElementValueType;
import net.spy.memcached.collection.SMGetElement;
import net.spy.memcached.internal.CollectionFuture;
import net.spy.memcached.internal.CollectionGetBulkFuture;
import net.spy.memcached.internal.SMGetFuture;
import net.spy.memcached.ops.CollectionOperationStatus;

public class btree_bulk_piped_ins implements client_profile {

  int KeyLen = 20;
  int ExpireTime = 600;
  String DEFAULT_PREFIX = "arcustest-";
  char[] dummystring = 
    ("1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ" +
     "abcdefghijlmnopqrstuvwxyz").toCharArray();
  Random random = new Random(); // repeatable is okay
  int[] chunk_sizes = {
    96, 120, 152, 192, 240, 304, 384, 480, 600, 752, 944, 1184, 1480, 1856,
    2320, 2904, 3632, 4544, 5680, 7104, 8880, 11104, 13880, 17352, 21696,
    27120, 33904, 42384, 52984, 66232, 82792, 103496, 129376, 161720, 202152,
    252696, 315872, 394840, 493552, 1048576
  };
  String[] chunk_values;

  String generateData(int length) {
    String ret = "";
    for (int loop = 0; loop < length; loop++) {
      int randomInt = random.nextInt(60);
      char tempchar = dummystring[randomInt];
      ret = ret + tempchar;
    }
    return ret;
  }

  // Generates a key with given name and postfix
  String gen_key(String name) {
    if (name == null)
      name = "unknown";
    String prefix = DEFAULT_PREFIX;
    String key = generateData(KeyLen);
    return prefix + name + ":" + key;
  }
  
  // Generates a string workload with specific size.
  String gen_workload(boolean is_collection) {
    if (is_collection) {
      // random.choice(chunk_values[0:17]);
      // Why 0 index?  chunk_values[0] is "Not_a_slab_class"?
      return chunk_values[random.nextInt(17+1)];
    }
    else {
      return chunk_values[random.nextInt(chunk_values.length)];
    }
  }

  public boolean do_test(client cli) {
    try {
	  if (!do_btree_test(cli))
		return false;
	} catch (Exception e) {
      System.out.printf("client_profile exception. id=%d exception=%s\n",
					    cli.id, e.toString());
	  e.printStackTrace();
	}
	return true;
  }

  public boolean do_btree_test(client cli) throws Exception {
    int loop_cnt = 10;
    
    // Pick a key
	String key = gen_key("Collection_Btree");
	List<String> key_list = new LinkedList<String>();
	for (int i = 0; i < loop_cnt; i++) 
	  key_list.add(key + i);

	String bkeyBASE = "bkey_byteArry";

	byte[] eflag = ("EFLAG").getBytes();
	ElementFlagFilter filter = 
	  new ElementFlagFilter(ElementFlagFilter.CompOperands.Equal,
					        ("EFLAG").getBytes());
	CollectionAttributes attr = new CollectionAttributes();
	attr.setExpireTime(ExpireTime);

	String[] workloads = { chunk_values[1],
			               chunk_values[1],
			               chunk_values[2],
			               chunk_values[2],
			               chunk_values[3] };

	// Create a btree item
	for (int i = 0; i < loop_cnt; i++) {
	  if (!cli.before_request())
	    return false;

	  ElementValueType vtype = ElementValueType.BYTEARRAY;
	  CollectionAttributes attr = 
	    new CollectionAttributes(10000L, new Long(10),
					             CollectionOverflowAction.smallest_trim);
	  CollectionFuture<Boolean> fb = cli.next_ac.asyncBopCreate(key, vtype, attr);
	  boolean ok = fb.get(1000L, TimeUnit.MILLISECONDS);
	  if (!ok) {
        System.out.printf("bop create failed. id=%d key=%s: %s\n", cli.id,
					      key, fb.getOperationStatus().getResponse());
	  }
	  if (!cli.after_request(ok))
	    return false;
	}

	
	// Bop Bulk Insert (Piped Insert)
	{
      List<Element<Object>> elements = new LinkedList<Element<Object>>
	  for (int i = 0; i < 50; i++) {
        String bk = bkeyBASE + "0" + Integer.toString(i) + "bulk";
		elements.add(new Element<Object>(bk.getBytes(), worksloads[0], eFlag));
	  }

	  if (!cli.before_request())
	    return false;
	  CollectionFuture<Map<Integer, CollectionOperationStatus>> f = 
	    cli.next_ac.asyncBopPipedInsertBulk(key_list.get(0), elements,
						                    new CollectionAttributes());
	  Map<Integer, CollectionOperationStatus> status_map = 
	    f.get(1000L, TimeUnit.MILLISECONDS);
	  Iterator<CollectionOperationStatus> status_iter = 
	    status_map.values().iterator();
	  while (status_iter.hasNext()) {
        CollectionOperationStatus status = status_iter.next();
		CollectionResponse resp = status.getResponse();
		if (resp != CollectionResponse.STORED) {
          System.out.printf("Collection_Btree: BopPipedInsertBulk failed." +
						    " id=%d key=%s response\n", cli.id, 
							key_list.get(0), resp);
		}
	  }
	  if (!cli.after_request(true))
	    return false;
	}

	return true;
  }
}
