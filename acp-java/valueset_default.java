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
class valueset_default implements valueset {
  int min;
  int max;
  int next_size;
  byte start_byte;

  Random random;
  long nsize;
  long base_kvsize;

  public valueset_default(int min, int max) {
    this.min = min;
    this.max = max;    
    reset();
  }

  public void reset() {
    next_size = min;
    start_byte = 0;
    random = new Random();
  }

  public byte[] get_value() {
    int size;
    byte b;
    synchronized(this) {
      size = next_size;
      // FIXME
      next_size += 10;
      if (next_size >= max)
        next_size = min;
      b = start_byte++;
    }

    // Don't worry about performance here.  Allocate, copy, fill would
    // take many cycles.  But then we only need to achieve 1Gbps.
    byte[] val = new byte[size];
    for (int i = 0; i < val.length; i++)
      val[i] = b++;
    
    // FIXME.  Is there any way to share the underly storage?
    return val;
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

  /* must modify keyset_default.java together */
  public long getvalsize(String keyset) {
      synchronized(this) {
          if(keyset.contains("1section")) { /* value 20(110) ~ 50(140) + sizeof(hash_item) + cas + \r\n + keylength(about 20) */
              nsize = (long)(110 + random.nextInt(31));
          } else if (keyset.contains("2section")) { /* value 51(141) ~ 100(190) */
              nsize = (long)(141 + random.nextInt(50));
          } else if (keyset.contains("3section")) { /* value 101(191) ~ 1000(1090) */
              nsize = (long)(191 + random.nextInt(900));
          } else if (keyset.contains("4section")) { /* value 1001(1091) ~ 3000(3090) */
              nsize = (long)(1091 + random.nextInt(2000));
          } else if (keyset.contains("5section")) { /* value 3001(3091) ~ 7000(7090) */
              nsize = (long)(3091 + random.nextInt(4000));
          } else if (keyset.contains("6section")) { /* value 7001(7091) ~ 15000(15090) */
              nsize = (long)(7091 + random.nextInt(8000));
          }
      }
      return nsize;
  }
}
