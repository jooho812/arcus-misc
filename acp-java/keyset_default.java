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
// Default key set.
import java.util.Random;

class keyset_default implements keyset {
  String[] set;
  int next_idx;
  String[] set1;
  String[] set2;
  String[] set3;
  String[] set4;
  String[] set5;
  String[] set6;

  Random random;
  int[] idx;
  int[] insert_ratio;

  public keyset_default(int num, String prefix) {


    /* reappear test */
    if (prefix.contains("reappear")) {
      int[] setnum = new int[6];
      idx = new int[6];
      insert_ratio = new int[6];

      setnum[0] = num;
      setnum[1] = num;
      setnum[2] = num/12;
      setnum[3] = num/30;
      setnum[4] = num/60;
      setnum[5] = num/300;

      insert_ratio[0] = 500  - 1;  /* 50 */
      insert_ratio[1] = 964  - 1;  /* 46.4 */
      insert_ratio[2] = 984  - 1;  /* 2 */
      insert_ratio[3] = 994  - 1;  /* 1 */
      insert_ratio[4] = 999  - 1;  /* 0.5 */
      insert_ratio[5] = 1000 - 1;  /* 0.1*/

      set1 = new String[setnum[0]];
      set2 = new String[setnum[1]];
      set3 = new String[setnum[2]];
      set4 = new String[setnum[3]];
      set5 = new String[setnum[4]];
      set6 = new String[setnum[5]];

      for (int i = 0; i < setnum[0]; i++) {
        set1[i] = "testkey-" + i;
        if (prefix != null)
          set1[i] = "1section" + prefix + set1[i];
      }
      for (int i = 0; i < setnum[1]; i++) {
        set2[i] = "testkey-" + i;
        if (prefix != null)
          set2[i] = "2section" + prefix + set2[i];
      }
      for (int i = 0; i < setnum[2]; i++) {
        set3[i] = "testkey-" + i;
        if (prefix != null)
          set3[i] = "3section" + prefix + set3[i];
      }
      for (int i = 0; i < setnum[3]; i++) {
        set4[i] = "testkey-" + i;
        if (prefix != null)
          set4[i] = "4section" + prefix + set4[i];
      }
      for (int i = 0; i < setnum[4]; i++) {
        set5[i] = "testkey-" + i;
        if (prefix != null)
          set5[i] = "5section" + prefix + set5[i];
      }
      for (int i = 0; i < setnum[5]; i++) {
        set6[i] = "testkey-" + i;
        if (prefix != null)
          set6[i] = "6section" + prefix + set6[i];
      }
      reappear_reset();
    } else {
      set = new String[num];
      for (int i = 0; i < num; i++) {
        set[i] = "testkey-" + i;
        if (prefix != null)
          set[i] = prefix + set[i];
      }
      reset();
    }
  }

  public void reset() {
    next_idx = 0;
  }

  public void reappear_reset() {
    for (int i=0; i < idx.length ; i++)
      idx[i] = 0;
    random = new Random();
  }

  synchronized public String get_key() {
    int idx = next_idx++;
    if (next_idx >= set.length)
      next_idx = 0;
    return set[idx];
  }

  synchronized public String get_reappearkey() {
    int rd = random.nextInt(1000);

    /* random approach */
    if (rd <= insert_ratio[0]) {
      idx[0] = random.nextInt(set1.length);
      return set1[idx[0]];
    } else if (rd <= insert_ratio[1]) {
      idx[1] = random.nextInt(set2.length);
      return set2[idx[1]];
    } else if (rd <= insert_ratio[2]) {
      idx[2] = random.nextInt(set3.length);
      return set3[idx[2]];
    } else if (rd <= insert_ratio[3]) {
      idx[3] = random.nextInt(set4.length);
      return set4[idx[3]];
    } else if (rd <= insert_ratio[4]) {
      idx[4] = random.nextInt(set5.length);
      return set5[idx[4]];
    //} else if (rd <= insert_ratio[5]) {
    } else {
      idx[5] = random.nextInt(set6.length);
      return set6[idx[5]];
    }
  }
}
