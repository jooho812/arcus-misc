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
import java.util.Map;
import java.util.List;
import java.util.LinkedList;
import java.util.Random;

import net.spy.memcached.ops.CollectionOperationStatus;

public class simple_get_bulk implements client_profile {
  
  public simple_get_bulk() {
    int next_val_idx = 0;
	chunk_values = new String[chunk_sizes.length+1];
	chunk_values[next_val_idx++] = "Not_a_slab_class";
    String lowercase = "abcdefghijlmnopqrstuvwxyz";
	
    for (int s : chunk_sizes) {
      int len = s*2/3;
      char[] raw = new char[len];
      for (int i = 0; i < len; i++) {
        raw[i] = lowercase.charAt(random.nextInt(lowercase.length()));
      }
      chunk_values[next_val_idx++] = new String(raw);
    }
  }

  String DEFAULT_PREFIX = "arcustest-";
  int KeyLen = 20;
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
      if (!do_simple_test(cli))
	    return false;
	} catch (Exception e) {
	  cli.after_request(false);
	}
	return true;
  }

  public boolean do_simple_test(client cli) throws Exception {
    int loop_cnt = 100; 
 
	// Prepare Key list
	String key = gen_key("Collection_Simple");
	byte[] val = cli.vset.get_value();

	String[] workloads = { chunk_values[1],
						   chunk_values[1],
						   chunk_values[2],
				           chunk_values[2],
			               chunk_values[3] };

	// SET
	List<String> key_list = new LinkedList<String>();
	for (int i = 0; i < loop_cnt; i++) {
	  key_list.add(Integer.toString(i) + "_" + workloads[0]);

	  if (!cli.before_request())
	    return false;
	  Future<Boolean> fb = 
	    cli.next_ac.set(key, cli.conf.client_exptime, val);
	  boolean ok = fb.get(1000L, TimeUnit.MILLISECONDS);
	  if (!ok) {
        System.out.printf("add failed. id=%d key=%s\n", cli.id, key);
	  }
	  if (!cli.after_request(ok))
	    return false;
	}

	// getBulk
	if (!cli.before_request())
	  return false;

	Map<String, Object> m = cli.next_ac.getBulk(key_list);
	if (m == null) {
      System.out.printf("get bulk failed. id=%d\n", cli.id);
	}

	if (!cli.after_request(true))
	  return false;
    
	return true;
  }
}
