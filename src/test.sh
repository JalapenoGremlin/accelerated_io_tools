#!/bin/bash

iquery -anq "remove(zero_to_255)"                > /dev/null 2>&1
iquery -anq "remove(minus_128_to_127)"           > /dev/null 2>&1
iquery -anq "remove(zero_to_65536)"              > /dev/null 2>&1
iquery -anq "remove(minus_32768_to_32767)"       > /dev/null 2>&1
iquery -anq "remove(big_n_wild)"                 > /dev/null 2>&1

iquery -anq "store( build( <val:string> [x=0:65535999,100000,0],  string(x % 256) ), zero_to_255 )"                       > /dev/null 2>&1
iquery -anq "store( build( <val:string> [x=0:65535999,100000,0],  ' ' + string(x % 256 - 128) + ' ' ), minus_128_to_127 )"            > /dev/null 2>&1
iquery -anq "store( build( <val:string> [x=0:65535999,100000,0],  string(x % 65536) + ' ' ), zero_to_65536 )"                   > /dev/null 2>&1
iquery -anq "store( build( <val:string> [x=0:65535999,100000,0],  ' ' + string(x % 65536 - 32768) ), minus_32768_to_32767 )"    > /dev/null 2>&1
iquery -anq "
store(
 build( <val:string null> [x=0:59999999, 100000, 0],
   iif( x % 6 = 0, string(x / 6 * 100) + ' ',
   iif( x % 6 = 1, ' ' + string(uint64(x) * 200000000000),
   iif( x % 6 = 2, '   ' + string(double(x) / 123.4) + ' ', 
   iif( x % 6 = 3, string(x) + '_abc',
   iif( x % 6 = 4, iif( x % 4 = 0, ' true', 'FalSe '),
                   string(null))))))
 ),
 big_n_wild
)"                                                                                                                        > /dev/null 2>&1

iquery -aq "build(<val:double null> [x=0:0,1,0], dcast('127',  int8(null)))"                                           >  test.out
iquery -aq "build(<val:double null> [x=0:0,1,0], dcast('128',  int8(null)))"                                           >> test.out
iquery -aq "build(<val:double null> [x=0:0,1,0], dcast('-128', int8(null)))"                                           >> test.out
iquery -aq "build(<val:double null> [x=0:0,1,0], dcast('-129', int8(null)))"                                           >> test.out

iquery -aq "build(<val:double null> [x=0:0,1,0], dcast('255', uint8(null)))"                                           >> test.out
iquery -aq "build(<val:double null> [x=0:0,1,0], dcast('256', uint8(null)))"                                           >> test.out
iquery -aq "build(<val:double null> [x=0:0,1,0], dcast('0',   uint8(null)))"                                           >> test.out
iquery -aq "build(<val:double null> [x=0:0,1,0], dcast('-1',  uint8(null)))"                                           >> test.out

iquery -aq "build(<val:double null> [x=0:0,1,0], dcast('32767',  int16(null)))"                                        >> test.out
iquery -aq "build(<val:double null> [x=0:0,1,0], dcast('32768',  int16(null)))"                                        >> test.out
iquery -aq "build(<val:double null> [x=0:0,1,0], dcast('-32768', int16(null)))"                                        >> test.out
iquery -aq "build(<val:double null> [x=0:0,1,0], dcast('-32769', int16(null)))"                                        >> test.out

iquery -aq "build(<val:double null> [x=0:0,1,0], dcast('65535',  uint16(null)))"                                       >> test.out
iquery -aq "build(<val:double null> [x=0:0,1,0], dcast('65536',  uint16(null)))"                                       >> test.out
iquery -aq "build(<val:double null> [x=0:0,1,0], dcast('0',      uint16(null)))"                                       >> test.out
iquery -aq "build(<val:double null> [x=0:0,1,0], dcast('-1',     uint16(null)))"                                       >> test.out

iquery -aq "build(<val:double null> [x=0:0,1,0], dcast('2147483647', int32(null)))"                                    >> test.out
iquery -aq "build(<val:double null> [x=0:0,1,0], dcast('2147483648', int32(null)))"                                    >> test.out
iquery -aq "build(<val:double null> [x=0:0,1,0], dcast('-2147483648', int32(null)))"                                   >> test.out
iquery -aq "build(<val:double null> [x=0:0,1,0], dcast('-2147483649', int32(null)))"                                   >> test.out

iquery -aq "build(<val:double null> [x=0:0,1,0], dcast('4294967295', uint32(null)))"                                   >> test.out
iquery -aq "build(<val:double null> [x=0:0,1,0], dcast('4294967296', uint32(null)))"                                   >> test.out
iquery -aq "build(<val:double null> [x=0:0,1,0], dcast('0',          uint32(null)))"                                   >> test.out
iquery -aq "build(<val:double null> [x=0:0,1,0], dcast('-1',         uint32(null)))"                                   >> test.out

iquery -aq "build(<val:double null> [x=0:0,1,0], dcast('4294967295', uint32(null)))"                                   >> test.out
iquery -aq "build(<val:double null> [x=0:0,1,0], dcast('4294967296', uint32(null)))"                                   >> test.out
iquery -aq "build(<val:double null> [x=0:0,1,0], dcast('0',          uint32(null)))"                                   >> test.out
iquery -aq "build(<val:double null> [x=0:0,1,0], dcast('-1',         uint32(null)))"                                   >> test.out

iquery -aq "build(<val:double null> [x=0:0,1,0], dcast('9223372036854775807',  int64(null)))"                          >> test.out
iquery -aq "build(<val:double null> [x=0:0,1,0], dcast('9223372036854775808',  int64(null)))"                          >> test.out
iquery -aq "build(<val:double null> [x=0:0,1,0], dcast('-9223372036854775808', int64(null)))"                          >> test.out
iquery -aq "build(<val:double null> [x=0:0,1,0], dcast('-9223372036854775809', int64(null)))"                          >> test.out

iquery -aq "build(<val:double null> [x=0:0,1,0], dcast('18446744073709551615', uint64(null)))"                         >> test.out
iquery -aq "build(<val:double null> [x=0:0,1,0], dcast('18446744073709551616', uint64(null)))"                         >> test.out
iquery -aq "build(<val:double null> [x=0:0,1,0], dcast('0', uint64(null)))"                                            >> test.out
iquery -aq "build(<val:double null> [x=0:0,1,0], dcast('-1', uint64(null)))"                                           >> test.out

time iquery -aq "aggregate(apply(zero_to_255, v2, dcast(val, uint8(null))), avg(v2), count(v2), count(*))"             >> test.out
time iquery -aq "aggregate(apply(zero_to_255, v2, dcast(val, int8(null))), avg(v2), count(v2), count(*))"              >> test.out
time iquery -aq "aggregate(apply(minus_128_to_127, v2, dcast(val, uint8(null))), avg(v2), count(v2), count(*))"        >> test.out
time iquery -aq "aggregate(apply(minus_128_to_127, v2, dcast(val, int8(null))), avg(v2), count(v2), count(*))"         >> test.out

time iquery -aq "aggregate(apply(zero_to_65536, v2, dcast(val, uint16(null))), avg(v2), count(v2), count(*))"          >> test.out
time iquery -aq "aggregate(apply(zero_to_65536, v2, dcast(val, int16(null))), avg(v2), count(v2), count(*))"           >> test.out
time iquery -aq "aggregate(apply(minus_32768_to_32767, v2, dcast(val, uint16(null))), avg(v2), count(v2), count(*))"   >> test.out
time iquery -aq "aggregate(apply(minus_32768_to_32767, v2, dcast(val, int16(null))), avg(v2), count(v2), count(*))"    >> test.out

time iquery -aq "aggregate(apply(big_n_wild, v2, dcast(val, uint8(null))), avg(v2), count(v2), count(*))"              >> test.out   
time iquery -aq "aggregate(apply(big_n_wild, v2, dcast(val, int8(null))), avg(v2), count(v2), count(*))"               >> test.out
time iquery -aq "aggregate(apply(big_n_wild, v2, dcast(val, int16(null))), avg(v2), count(v2), count(*))"              >> test.out
time iquery -aq "aggregate(apply(big_n_wild, v2, dcast(val, uint16(null))), avg(v2), count(v2), count(*))"             >> test.out
time iquery -aq "aggregate(apply(big_n_wild, v2, dcast(val, int32(null))), avg(v2), count(v2), count(*))"              >> test.out
time iquery -aq "aggregate(apply(big_n_wild, v2, dcast(val, uint32(null))), avg(v2), count(v2), count(*))"             >> test.out
time iquery -aq "aggregate(apply(big_n_wild, v2, dcast(val, int64(null))), avg(v2), count(v2), count(*))"              >> test.out
time iquery -aq "aggregate(apply(big_n_wild, v2, dcast(val, uint64(null))), avg(v2), count(v2), count(*))"             >> test.out
time iquery -aq "aggregate(apply(big_n_wild, v2, dcast(val, float(null))), avg(v2), count(v2), count(*))"              >> test.out
time iquery -aq "aggregate(apply(big_n_wild, v2, dcast(val, double(null))), avg(v2), count(v2), count(*))"             >> test.out

time iquery -aq "aggregate(apply(filter(apply(big_n_wild, v2, dcast(val, bool(null))), v2 is not null), v3, iif(v2, 1, 0)), sum(v3), count(*))" >> test.out
diff test.out test.expected
