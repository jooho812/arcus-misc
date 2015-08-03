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

public class simple_append implements client_profile {
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

	long not_used = 100L;

	if (!cli.before_request())
	  return false;

	// Pick a key
	String key = cli.ks.get_key();
	byte[] val = cli.vset.get_value();

	// ADD
	if (!cli.before_request())
	  return false;
	Future<Boolean> f = cli.next_ac.add(key, cli.conf.client_exptime, val);
	boolean ok = f.get(1000L, TimeUnit.MILLISECONDS);
	if (!ok) {
      System.out.printf("add failed. id=%d key=%s\n", cli.id, key);
	}
    if (!cli.after_request(ok))
	  return false;
	
	// Append 100 times.
	for (int i = 0; i < 100; i++) {
      if (!cli.before_request())
	    return false;

	  Future<Boolean> fb = cli.next_ac.append(not_used, key, val);
	  ok = fb.get(1000L, TimeUnit.MILLISECONDS);
	  if (!ok) {
        System.out.printf("append failed. id=%d key=%s\n", cli.id, key);
	  }
	  if (!cli.after_request(ok))
	    return false;
	}

	return true;


  }


}