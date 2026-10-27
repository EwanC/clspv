// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// RUN: clspv %s -o %t.spv -O0
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// RUN: clspv %s -o %t.spv -arch=spir64 -physical-storage-buffers
// RUN: spirv-val --target-env vulkan1.2 %t.spv

// SROA splits the copies into an i64 access to the first two members of T and
// an i32 access to the last one.

// CHECK-DAG: [[uint:%[^ ]+]] = OpTypeInt 32 0
// CHECK-DAG: [[ulong:%[^ ]+]] = OpTypeInt 64 0
// CHECK-DAG: [[uint_0:%[^ ]+]] = OpConstant [[uint]] 0
// CHECK-DAG: [[uint_1:%[^ ]+]] = OpConstant [[uint]] 1
// CHECK-DAG: [[uint_2:%[^ ]+]] = OpConstant [[uint]] 2
// CHECK: [[gid:%[^ ]+]] = OpLoad [[uint]]
// CHECK: [[word:%[^ ]+]] = OpIAdd [[ulong]]
// CHECK: [[a:%[^ ]+]] = OpUConvert [[uint]] [[word]]
// CHECK: [[ptr_a:%[^ ]+]] = OpAccessChain {{%[^ ]+}} [[out:%[^ ]+]] [[uint_0]] [[gid]] [[uint_0]]
// CHECK: OpStore [[ptr_a]] [[a]]
// CHECK: [[shr:%[^ ]+]] = OpShiftRightLogical [[ulong]] [[word]]
// CHECK: [[b:%[^ ]+]] = OpUConvert [[uint]] [[shr]]
// CHECK: [[ptr_b:%[^ ]+]] = OpAccessChain {{%[^ ]+}} [[out]] [[uint_0]] [[gid]] [[uint_1]]
// CHECK: OpStore [[ptr_b]] [[b]]
// CHECK: [[ptr_c:%[^ ]+]] = OpAccessChain {{%[^ ]+}} [[out]] [[uint_0]] [[gid]] [[uint_2]]
// CHECK: OpStore [[ptr_c]]

typedef struct {
  uint a, b, c;
} T;

kernel void foo(global const T *in, global T *out) {
  size_t gid = get_global_id(0);
  T v = in[gid];
  ulong words[2] = {0, 0};
  __builtin_memcpy(words, &v, sizeof(T));
  words[0] += 1;
  __builtin_memcpy(&v, words, sizeof(T));
  out[gid] = v;
}
