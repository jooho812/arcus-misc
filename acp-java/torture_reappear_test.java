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
import java.util.Random;

public class torture_reappear_test implements client_profile {
  int[] insert_ratio;
  int[] insert_range;
  String prefix;
  byte start_byte;

  Random random;

  public torture_reappear_test() {
      random = new Random();
      insert_ratio = new int[6];
      insert_range = new int[6];
      prefix = "reappear:";
      start_byte = 0;

      insert_ratio[0] = 500  - 1;  /* 50   % */
      insert_ratio[1] = 964  - 1;  /* 46.4 % */
      insert_ratio[2] = 984  - 1;  /*  2   % */
      insert_ratio[3] = 994  - 1;  /*  1   % */
      insert_ratio[4] = 999  - 1;  /*  0.5 % */
      insert_ratio[5] = 1000 - 1;  /*  0.1 % */

      insert_range[0] = 6000000;  /* 6,000,000 */
      insert_range[1] = 6000000;  /* 6,000,000 */
      insert_range[2] = 500000;   /* 500,000   */
      insert_range[3] = 200000;   /* 200,000   */
      insert_range[4] = 100000;   /* 100,000   */
      insert_range[5] = 20000;    /* 20,000    */
  }

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
    boolean ok = true;

    String key = get_key();

    byte[] val;

    /* get!! */
    if (!cli.before_request())
      return false;

    Future<byte[]> f = cli.next_ac.asyncGet(key, raw_transcoder.raw_tc);
    val = f.get(cli.conf.client_timeout, TimeUnit.MILLISECONDS);

    if (!cli.after_request(ok))
      return false;

    /* set operation is executed only when the get operation fails */
    if (val == null) {
      if (!cli.before_request())
        return false;
      val = get_value(get_valuesize(key));
      Future<Boolean> fb;

      if (key.contains("1section") || key.contains("2section")) {
        fb = cli.next_ac.set(key, 0, val, raw_transcoder.raw_tc);
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
    }

    return true;
  }

  private String get_key() {
    int rd = random.nextInt(1000);

    /* random approach */
    if (rd <= insert_ratio[0]) {
      return "1section" + prefix + "testkey-" + random.nextInt(insert_range[0]);
    } else if (rd <= insert_ratio[1]) {
      return "2section" + prefix + "testkey-" + random.nextInt(insert_range[1]);
    } else if (rd <= insert_ratio[2]) {
      return "3section" + prefix + "testkey-" + random.nextInt(insert_range[2]);
    } else if (rd <= insert_ratio[3]) {
      return "4section" + prefix + "testkey-" + random.nextInt(insert_range[3]);
    } else if (rd <= insert_ratio[4]) {
      return "5section" + prefix + "testkey-" + random.nextInt(insert_range[4]);
    //} else if (rd <= insert_ratio[5]) {
    } else {
      return "6section" + prefix + "testkey-" + random.nextInt(insert_range[5]);
    }

  }

  private int get_valuesize(String keyset) {
    int nsize = 0;
    if(keyset.contains("1section")) { /* value 20 ~ 50 */
      nsize = 20 + random.nextInt(30);
    } else if (keyset.contains("2section")) { /* value 51 ~ 100 */
      nsize = 51 + random.nextInt(50);
    } else if (keyset.contains("3section")) { /* value 101 ~ 1000 */
      nsize = 101 + random.nextInt(900);
    } else if (keyset.contains("4section")) { /* value 1001 ~ 3000 */
      nsize = 1001 + random.nextInt(2000);
    } else if (keyset.contains("5section")) { /* value 3001 ~ 7000 */
      nsize = 3001 + random.nextInt(4000);
    } else if (keyset.contains("6section")) { /* value 7001 ~ 15000 */
      nsize = 7001 + random.nextInt(8000);
    }
    return nsize;
  }

  public byte[] get_value(int value_length) {
      byte b;
      synchronized(this) {
          b = start_byte++;
      }

      byte[] val = new byte[value_length];
      for (int i = 0; i < val.length; i++)
          val[i] = b++;

      return val;
  }
}
