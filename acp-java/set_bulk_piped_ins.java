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

public class set_bulk_piped_ins implements client_profile {

  String DEFAULT_PREFIX = "arcustest-";
  int KeyLen = 20;
  char[] dummystring = 
    ("1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ" +
     "abcdefghijlmnopqrstuvwxyz").toCharArray();
  Random random = new Random(); // repeatable is okay

  String gen_key(String name) {
    if (name == null)
	  name = "unknown";
      String prefix = DEFAULT_PREFIX;
	  String key = generateData(KeyLen);
	  return prefix + name + ":" + key;
  }

  String generateData(int length) {
    String ret = "";
	for (int loop = 0; loop < length; loop++) {
	  int randomInt = random.nextInt(60);
	  char tempchar = dummystring[randomInt];
	  ret = ret + tempchar;
	}
	return ret;
  }

  public boolean do_test(client cli) {
    try {
      if (!do_set_test(cli))
	    return false;
	} catch (Exception e) {
      System.out.printf("client_profile exception. id=%d exception=%s\n",
					                              cli.id, e.toString());
	  e.printStackTrace();
	}
	return true;
  }

  public boolean do_set_test(client cli) throws Exception {
    // Prepare Key 
	String key = gen_key("Collection_Set");

	CollectionAttributes attr = new CollectionAttributes();
	attr.setExpireTime(ExpireTime);

	String[] workloads = { chunk_values[1],
			               chunk_values[1],
			               chunk_values[2],
			               chunk_values[2],
			               chunk_values[3] };

	// SopInsert Bulk (Piped)
	{
      List<Object> elements = new LinkedList<Object>();
	  for (int i = 0; i < 100; i++) {
        elements.add(Integer.toString(i) + "_" + workloads[0]);
	  }
	  if (!cli.before_request())
	    return false;
	  CollectionFuture<Map<Integer, CollectionOperationStatus>> f = 
	    cli.next_ac.asyncLopPipedInsertBulk(key_list.get(0), -1, elements,
						                    new CollectionAttributes());
	  Map<Integer, CollectionOperationStatus> status_map = 
			  f.get(1000L, TimeUnit.MILLISECONDS);
	  Iterator<CollectionOperationStatus> status_iter =
			  status_map.values().iterator();
	  while (status_iter.hasNext()) {
        CollectionOperationStatus status = status_iter.next();
		CollectionResponse resp = status.getResponse();
		if (resp != CollectionResponse.STORED) {
          System.out.printf("Collection Set: SopPipedInsertBulk failed." +
						  " id=%d key=%s response=%s\n", cli.id,
						                            key_list.get(0), resp);
		}
	  }
	  if (!cli.after_request(true))
	    return false;
	}

	return true;
  }
}






































