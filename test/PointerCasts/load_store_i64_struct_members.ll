; RUN: clspv-opt %s -o %t.ll --passes=replace-pointer-bitcast
; RUN: FileCheck %s < %t.ll

; The i64 load and store access the first two members of a struct which size
; is not a multiple of the size of i64.

; CHECK-LABEL: @struct12
; CHECK: [[gep:%[^ ]+]] = getelementptr %struct.T12, ptr addrspace(1) %src, i32 0
; CHECK: [[ld:%[^ ]+]] = load %struct.T12, ptr addrspace(1) [[gep]], align 4
; CHECK: [[a:%[^ ]+]] = extractvalue %struct.T12 [[ld]], 0
; CHECK: [[b:%[^ ]+]] = extractvalue %struct.T12 [[ld]], 1
; CHECK: [[a64:%[^ ]+]] = zext i32 [[a]] to i64
; CHECK: [[b64:%[^ ]+]] = zext i32 [[b]] to i64
; CHECK: [[shl:%[^ ]+]] = shl i64 [[b64]], 32
; CHECK: [[val:%[^ ]+]] = or i64 [[a64]], [[shl]]
; CHECK: [[add:%[^ ]+]] = add i64 [[val]], 1
; CHECK: [[lo:%[^ ]+]] = trunc i64 [[add]] to i32
; CHECK: [[gep_a:%[^ ]+]] = getelementptr %struct.T12, ptr addrspace(1) %dst, i32 0, i32 0
; CHECK: store i32 [[lo]], ptr addrspace(1) [[gep_a]], align 4
; CHECK: [[lshr:%[^ ]+]] = lshr i64 [[add]], 32
; CHECK: [[hi:%[^ ]+]] = trunc i64 [[lshr]] to i32
; CHECK: [[gep_b:%[^ ]+]] = getelementptr %struct.T12, ptr addrspace(1) %dst, i32 0, i32 1
; CHECK: store i32 [[hi]], ptr addrspace(1) [[gep_b]], align 4
; CHECK: [[gep_c:%[^ ]+]] = getelementptr %struct.T12, ptr addrspace(1) %out, i32 %i, i32 2
; CHECK: store i32 %c, ptr addrspace(1) [[gep_c]], align 4

; The i64 store covers an i32 and a float member. The struct must not be
; downgraded to i64, which would lose the offset of the struct and of its third
; member.

; CHECK-LABEL: @mixed
; CHECK: [[dst:%[^ ]+]] = getelementptr %struct.M, ptr addrspace(1) %out, i32 %i
; CHECK: [[lo:%[^ ]+]] = trunc i64 %ab to i32
; CHECK: [[gep_a:%[^ ]+]] = getelementptr %struct.M, ptr addrspace(1) [[dst]], i32 0, i32 0
; CHECK: store i32 [[lo]], ptr addrspace(1) [[gep_a]], align 4
; CHECK: [[lshr:%[^ ]+]] = lshr i64 %ab, 32
; CHECK: [[hi:%[^ ]+]] = trunc i64 [[lshr]] to i32
; CHECK: [[b:%[^ ]+]] = bitcast i32 [[hi]] to float
; CHECK: [[gep_b:%[^ ]+]] = getelementptr %struct.M, ptr addrspace(1) [[dst]], i32 0, i32 1
; CHECK: store float [[b]], ptr addrspace(1) [[gep_b]], align 4
; CHECK: [[gep_c:%[^ ]+]] = getelementptr %struct.M, ptr addrspace(1) %out, i32 %i, i32 2
; CHECK: store i32 %c, ptr addrspace(1) [[gep_c]], align 4

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spirv32-unknown-vulkan"

%struct.T12 = type { i32, i32, i32 }
%struct.M = type { i32, float, i32 }

define spir_kernel void @struct12(ptr addrspace(1) %in, ptr addrspace(1) %out, i32 %i) {
entry:
  %src = getelementptr %struct.T12, ptr addrspace(1) %in, i32 %i
  %ab = load i64, ptr addrspace(1) %src, align 4
  %src_c = getelementptr %struct.T12, ptr addrspace(1) %in, i32 %i, i32 2
  %c = load i32, ptr addrspace(1) %src_c, align 4
  %add = add i64 %ab, 1
  %dst = getelementptr %struct.T12, ptr addrspace(1) %out, i32 %i
  store i64 %add, ptr addrspace(1) %dst, align 4
  %dst_c = getelementptr %struct.T12, ptr addrspace(1) %out, i32 %i, i32 2
  store i32 %c, ptr addrspace(1) %dst_c, align 4
  ret void
}

define spir_kernel void @mixed(ptr addrspace(1) %out, i32 %i, i64 %ab, i32 %c) {
entry:
  %dst = getelementptr %struct.M, ptr addrspace(1) %out, i32 %i
  store i64 %ab, ptr addrspace(1) %dst, align 4
  %dst_c = getelementptr %struct.M, ptr addrspace(1) %out, i32 %i, i32 2
  store i32 %c, ptr addrspace(1) %dst_c, align 4
  ret void
}
