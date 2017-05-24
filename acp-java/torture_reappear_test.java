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
import static java.lang.Math.toIntExact;

public class torture_reappear_test implements client_profile {
  public boolean do_test(client cli) {
    try {
      if (!do_simple_test(cli))
        return false;
    } catch (Exception e) {
      cli.after_request(false);
      /*
      System.out.printf("client_profile exception. id=%d exception=%s\n", 
                        cli.id, e.toString());
      */
      if (cli.conf.print_stack_trace)
        e.printStackTrace();
      //System.exit(0);
    }
    return true;
  }

  public boolean do_simple_test(client cli) throws Exception {
    // Do one set and one get.  The same key.
    // Pick a key
    long base_kvsize = 56 + 8 + 2; /*sizeof(hash_item) + cas + "\r\n"*/
    long value_size;
    int value_length;
    boolean ok = true;

    String key = cli.ks.get_reappearkey();

    value_size = cli.vset.getvalsize(key);

    value_length = toIntExact(value_size - base_kvsize) - key.length();
    byte[] val; //= cli.vset.get_value(value_length);

    /* get!! */
    if (!cli.before_request())
      return false;
    Future<byte[]> f = cli.next_ac.asyncGet(key, raw_transcoder.raw_tc);
    val = f.get(cli.conf.client_timeout, TimeUnit.MILLISECONDS);
    //ok = true;
    //if (val == null) {
      //ok = false;
    //}
    if (!cli.after_request(ok))
      return false;

    /* set operation is executed only when the get operation fails */
    if (val == null) {
      if (!cli.before_request())
        return false;
      val = cli.vset.get_value(value_length);
      Future<Boolean> fb;

      if (key.contains("1section") || key.contains("2section")) {
        fb = cli.next_ac.set(key, cli.conf.client_exptime, val, raw_transcoder.raw_tc);
      } else if (key.contains("3section") || key.contains("4section")) { /* expired time 2400 */
        fb = cli.next_ac.set(key, 2400, val, raw_transcoder.raw_tc);
      } else { /* expired time 1200 5section, 6section */
        fb = cli.next_ac.set(key, 1200, val, raw_transcoder.raw_tc);
      }

      ok = fb.get(cli.conf.client_timeout, TimeUnit.MILLISECONDS);
      if (!ok) {
        System.out.printf("set failed. id=%d key=%s\n", cli.id, key);
      }
      if (!cli.after_request(ok))
        return false;
      if (!ok)
        return true;
    }

    return true;
  }
}
