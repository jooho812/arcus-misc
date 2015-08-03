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
import java.util.Random;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;
import java.util.Map;
import java.util.LinkedList;
import java.util.List;

import net.spy.memcached.ops.CollectionOperationStatus;

public class simple_set_bulk implements client_profile {
		
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

	List<String> key_list = new LinkedList<String>();
	for (int i = 0; i < loop_cnt; i++) {
      key_list.add(key + i);
	}

	// Set Bulk
    if (!cli.before_request())	
	  return false;

	Future<Map<String, CollectionOperationStatus>> f = 
	  cli.next_ac.asyncSetBulk(key_list, 600, val);
	Map<String, CollectionOperationStatus> result =
	  f.get(1000L, TimeUnit.MILLISECONDS);

	if (!cli.after_request(true))
	  return false;

    return true;
  }

}
