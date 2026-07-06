// Copyright 2018 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

#include "go_asm.h"
#include "textflag.h"

TEXT ·Compare<ABIInternal>(SB),NOSPLIT|NOFRAME,$0-56
	// R2 = a_base
	// R3 = a_len
	// R4 = a_cap (unused)
	// R5 = b_base (want in R4)
	// R6 = b_len (want in R5)
	// R7 = b_cap (unused)
	MOVD	R5, R4
	MOVD	R6, R5
	BR	cmpbody<>(SB)

TEXT runtime·cmpstring<ABIInternal>(SB),NOSPLIT|NOFRAME,$0-40
	// R2 = a_base
	// R3 = a_len
	// R4 = b_base
	// R5 = b_len

	BR	cmpbody<>(SB)

// input:
//   R2 = a
//   R3 = alen
//   R4 = b
//   R5 = blen
//   For regabiargs output value( -1/0/1 ) stored in R2
//   For !regabiargs address of output word( stores -1/0/1 ) stored in R6



TEXT cmpbody<>(SB),NOSPLIT|NOFRAME,$0-0
        CMPBEQ  R2, R4, cmplengths
        MOVD    R3, R7
        CMPBLE  R3, R5, amin
        MOVD    R5, R7
amin:
        CMPBEQ  R7, $0, cmplengths
        MOVD    $0, R6
        CMPBGT  R7, $16,gt17to32

Lremain:
        ADD     $-1, R7
        VLL     R7, (R2), V16
        VLL     R7, (R4), V17
        VFENEB  V16, V17, V18
        VLGVB   $7, V18, R8
	MOVD    $0, R6
        CMPBLE  R8, R7, Lfound2
cmplengths:
        CMP     R3, R5
        BEQ     eq
        BLT     lt
gt:
        MOVD    $1, R2
        RET
lt:
        MOVD    $-1, R2
        RET
eq:
        MOVD    $0, R2
        RET

Lfound:
        VLGVB   $7, V18, R8
Lfound2:
        VL    (R6)(R2), V16
        VL    (R6)(R4), V17
        VLGVB  R8, V17, R1
        VLGVB  R8, V16, R8
        CMPW   R8, R1
//      BEQ    eq
        MOVD   $1, R2
        MOVD   $-1,R1
        LOCGR  $4, R1, R2
        RET

gt17to32:
	CMPBGT R7,$32,gtL33to64

Lloop17to32:
        VL        (R6)(R2), V16
        VL        (R6)(R4), V17
        VFENEBS   V16, V17, V18
        BRC       $6, Lfound
        MOVD    R7, R8
        SUB     $16, R8
        ADD     R8, R6
        VL        (R6)(R2), V16
        VL        (R6)(R4), V17
        VFENEBS   V16, V17, V18
        BRC       $6, Lfound
        BRC     $15,cmplengths


gtL33to64:
        CMPBGT  R7, $64, gtL65to128

Lloop33to64:
        VL        (R6)(R2), V16
        VL        (R6)(R4), V17
        VL        16(R6)(R2), V19
        VL        16(R6)(R4), V20

        VFENEBS   V16, V17, V18
        BRC       $6, Lfound
	
	ADD	$16, R6
        VFENEBS   V19, V20, V18
        BRC       $6, Lfound

        MOVD    R7, R8
        SUB     $48, R8
        ADD     R8, R6
        VL        (R6)(R2), V21
        VL        (R6)(R4), V22
        VL        16(R6)(R2), V23
        VL        16(R6)(R4), V24

        VFENEBS   V21, V22, V18
        BRC       $6, Lfound

	ADD	$16, R6
        VFENEBS   V23, V24, V18
        BRC       $6, Lfound
	BRC     $15, cmplengths


gtL65to128:
        //CMPBGT  R7, $65, gtL33to64
	CMP R7, $128
	BGT	gtL129to256
	
Lloop65to128:
        VL        (R6)(R2), V16
        VL        (R6)(R4), V17
        VL        16(R6)(R2), V19
        VL        16(R6)(R4), V20
        VL        32(R6)(R2), V21
        VL        32(R6)(R4), V22
        VL        48(R6)(R2), V23
        VL        48(R6)(R4), V24

        VFENEBS   V16, V17, V18
        BRC       $6, Lfound

	ADD	$16, R6
        VFENEBS   V19, V20, V18
        BRC       $6, Lfound

	ADD	$16, R6
        VFENEBS   V21, V22, V18
        BRC       $6, Lfound

	ADD	$16, R6
        VFENEBS   V23, V24, V18
        BRC       $6, Lfound

        MOVD    R7, R8
        SUB     $112, R8	//64-Bytes from 4 sets vector and as R6 update to a offset of 48 bytes, 64+48=112
        ADD     R8, R6
	
        VL        (R6)(R2), V16
        VL        (R6)(R4), V17
        VL        16(R6)(R2), V19
        VL        16(R6)(R4), V20
        VL        32(R6)(R2), V21
        VL        32(R6)(R4), V22
        VL        48(R6)(R2), V23
        VL        48(R6)(R4), V24

        VFENEBS   V16, V17, V18
        BRC       $6, Lfound

	ADD	$16, R6
        VFENEBS   V19, V20, V18
        BRC       $6, Lfound

	ADD	$16, R6
        VFENEBS   V21, V22, V18
        BRC       $6, Lfound

	ADD	$16, R6
        VFENEBS   V23, V24, V18
        BRC       $6, Lfound
	BRC     $15, cmplengths



gtL129to256:
        CMP     R7, $255
        BGT     gtL256
Lloop129to256:
        VL        (R6)(R2), V15
        VL        (R6)(R4), V16
        VL        16(R6)(R2), V17
        VL        16(R6)(R4), V19
        VL        32(R6)(R2), V20
        VL        32(R6)(R4), V21
        VL        48(R6)(R2), V22
        VL        48(R6)(R4), V23
        VL        64(R6)(R2), V24
        VL        64(R6)(R4), V25
        VL        80(R6)(R2), V26
        VL        80(R6)(R4), V27
        VL        96(R6)(R2), V28
        VL        96(R6)(R4), V29
        VL        112(R6)(R2), V30
        VL        112(R6)(R4), V31


        VFENEBS   V15, V16, V18
        BRC       $6, Lfound

	ADD	$16, R6
        VFENEBS   V17, V19, V18
        BRC       $6, Lfound

	ADD	$16, R6
        VFENEBS   V20, V21, V18
        BRC       $6, Lfound

	ADD	$16, R6
        VFENEBS   V22, V23, V18
        BRC       $6, Lfound

	ADD	$16, R6
        VFENEBS   V24, V25, V18
        BRC       $6, Lfound

	ADD	$16, R6
        VFENEBS   V26, V27, V18
        BRC       $6, Lfound

	ADD	$16, R6
        VFENEBS   V28, V29, V18
        BRC       $6, Lfound

	ADD	$16, R6
        VFENEBS   V30, V31, V18
        BRC       $6, Lfound

        //ADD     $128, R6
        MOVD    R7, R8
        SUB     $240, R8
        ADD     R8, R6

        VL        (R6)(R2), V15
        VL        (R6)(R4), V16
        VL        16(R6)(R2), V17
        VL        16(R6)(R4), V19
        VL        32(R6)(R2), V20
        VL        32(R6)(R4), V21
        VL        48(R6)(R2), V22
        VL        48(R6)(R4), V23
        VL        64(R6)(R2), V24
        VL        64(R6)(R4), V25
        VL        80(R6)(R2), V26
        VL        80(R6)(R4), V27
        VL        96(R6)(R2), V28
        VL        96(R6)(R4), V29
        VL        112(R6)(R2), V30
        VL        112(R6)(R4), V31
       

        VFENEBS   V15, V16, V18
        BRC       $6, Lfound

	ADD	$16, R6
        VFENEBS   V17, V19, V18
        BRC       $6, Lfound

	ADD	$16, R6
        VFENEBS   V20, V21, V18
        BRC       $6, Lfound

	ADD	$16, R6
        VFENEBS   V22, V23, V18
        BRC       $6, Lfound

	ADD	$16, R6
        VFENEBS   V24, V25, V18
        BRC       $6, Lfound

	ADD	$16, R6
        VFENEBS   V26, V27, V18
        BRC       $6, Lfound

	ADD	$16, R6
        VFENEBS   V28, V29, V18
        BRC       $6, Lfound

	ADD	$16, R6
        VFENEBS   V30, V31, V18
        BRC       $6, Lfound
        BRC     $15, cmplengths


gtL256:
        CMP     R7, $2048
        BGT     gtL2048
Lpreloop256to2048:
        SRD     $8, R7, R1
Lloop256:
        CLC     $256, 0(R2), 0(R4)
        BGT     gt
        BLT     lt
        MOVD    $256(R2), R2
        MOVD    $256(R4), R4
        //ADD     $256, R6
        BRCTG   R1, Lloop256

        MOVWZ   R7, R7
        AND     $255, R7    //Get Reamining Bytes
        BEQ     cmplengths
        CMP     R7, $128
        BGT     Lloop129to256
        //CMPBGT  R7, $128, Lpreloop129to256
        CMPBGT  R7, $64, Lloop65to128
        CMPBGT  R7, $32, Lloop33to64
        CMPBGT  R7, $16, Lloop17to32
        BRC     $15, Lremain

gtL2048:
        SRD     $11, R7, R1
Lloop2048:
        CLC     $256, 0(R2), 0(R4)
        BGT     gt
        BLT     lt
        CLC     $256, 256(R2), 256(R4)
        BGT     gt
        BLT     lt
        CLC     $256, 512(R2), 512(R4)
        BGT     gt
        BLT     lt
        CLC     $256, 768(R2), 768(R4)
        BGT     gt
        BLT     lt
        CLC     $256, 1024(R2), 1024(R4)
        BGT     gt
        BLT     lt
        CLC     $256, 1280(R2), 1280(R4)
        BGT     gt
        BLT     lt
        CLC     $256, 1536(R2), 1536(R4)
        BGT     gt
        BLT     lt
        CLC     $256, 1792(R2), 1792(R4)
        BGT     gt
        BLT     lt
        MOVD    $2048(R2), R2
        MOVD    $2048(R4), R4
        BRCTG   R1, Lloop2048
        MOVWZ   R7, R7
        AND     $2047, R7    //Get Reamining Bytes
        BEQ     cmplengths
        CMP     R7, $255
        BGT     Lpreloop256to2048
        CMP     R7, $128
        BGT     Lloop129to256
        //CMPBGT  R7, $128, Lpreloop129to256
        CMPBGT  R7, $64, Lloop65to128
        CMPBGT  R7, $32, Lloop33to64
        CMPBGT  R7, $16, Lloop17to32
        BRC     $15, Lremain

