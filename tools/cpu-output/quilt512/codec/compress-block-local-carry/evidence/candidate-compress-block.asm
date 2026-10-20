
/pool/wrf-experiment/wrf-cpu/kernels/compress-block-local-carry-native-hpc04-r1/output/build/libz.so.1.3.1.zlib-ng:     file format elf64-x86-64


Disassembly of section .init:

Disassembly of section .plt:

Disassembly of section .plt.got:

Disassembly of section .text:

000000000000f220 <compress_block>:
    f220:	push   %r15
    f222:	mov    %rdi,%rax
    f225:	push   %r14
    f227:	push   %r13
    f229:	push   %r12
    f22b:	push   %rbp
    f22c:	push   %rbx
    f22d:	mov    0x1740(%rdi),%ebp
    f233:	mov    %rsi,%rbx
    f236:	mov    0x1778(%rdi),%r10
    f23d:	mov    0x1780(%rdi),%edi
    f243:	test   %ebp,%ebp
    f245:	je     f398 <compress_block+0x178>
    f24b:	mov    %rdx,-0x8(%rsp)
    f250:	mov    0x1730(%rax),%r14
    f257:	xor    %esi,%esi
    f259:	mov    0x1738(%rax),%r13
    f260:	jmp    f2ad <compress_block+0x8d>
    f262:	nopw   0x0(%rax,%rax,1)
    f268:	mov    (%rbx,%rcx,4),%edx
    f26b:	movzwl %dx,%r9d
    f26f:	shr    $0x10,%edx
    f272:	lea    (%rdx,%rdi,1),%r11d
    f276:	mov    %edx,%ecx
    f278:	cmp    $0x3f,%r11d
    f27c:	ja     f430 <compress_block+0x210>
    f282:	cmp    $0x3f,%edi
    f285:	ja     f410 <compress_block+0x1f0>
    f28b:	mov    %edi,%ecx
    f28d:	mov    %r11d,%edi
    f290:	shl    %cl,%r9
    f293:	or     %r9,%r10
    f296:	cs nopw 0x0(%rax,%rax,1)
    f2a0:	add    $0x1,%rsi
    f2a4:	cmp    %rbp,%rsi
    f2a7:	je     f398 <compress_block+0x178>
    f2ad:	movzwl (%r14,%rsi,2),%edx
    f2b2:	movzbl 0x0(%r13,%rsi,1),%ecx
    f2b8:	test   %edx,%edx
    f2ba:	je     f268 <compress_block+0x48>
    f2bc:	movzbl %cl,%ecx
    f2bf:	lea    0x1677a(%rip),%r11        # 25a40 <zng_length_code>
    f2c6:	movzbl (%r11,%rcx,1),%r9d
    f2cb:	mov    %rcx,%r8
    f2ce:	lea    0x1706b(%rip),%r11        # 26340 <extra_lbits>
    f2d5:	lea    0x101(%r9),%ecx
    f2dc:	mov    (%r11,%r9,4),%r11d
    f2e0:	movslq %ecx,%rcx
    f2e3:	mov    (%rbx,%rcx,4),%ecx
    f2e6:	movzwl %cx,%r12d
    f2ea:	shr    $0x10,%ecx
    f2ed:	test   %r11d,%r11d
    f2f0:	je     f306 <compress_block+0xe6>
    f2f2:	lea    0x166c7(%rip),%r15        # 259c0 <base_length>
    f2f9:	sub    (%r15,%r9,4),%r8d
    f2fd:	shl    %cl,%r8
    f300:	add    %r11d,%ecx
    f303:	or     %r8,%r12
    f306:	sub    $0x1,%edx
    f309:	cmp    $0xff,%edx
    f30f:	ja     f3e8 <compress_block+0x1c8>
    f315:	mov    %edx,%r8d
    f318:	lea    0x16821(%rip),%r15        # 25b40 <zng_dist_code>
    f31f:	movzbl (%r15,%r8,1),%r11d
    f324:	mov    -0x8(%rsp),%r15
    f329:	movzbl %r11b,%r8d
    f32d:	mov    (%r15,%r8,4),%r8d
    f331:	movzwl %r8w,%r9d
    f335:	shr    $0x10,%r8d
    f339:	shl    %cl,%r9
    f33c:	add    %r8d,%ecx
    f33f:	lea    0x16f7a(%rip),%r8        # 262c0 <extra_dbits>
    f346:	mov    (%r8,%r11,4),%r8d
    f34a:	or     %r12,%r9
    f34d:	test   %r8d,%r8d
    f350:	je     f366 <compress_block+0x146>
    f352:	lea    0x165e7(%rip),%r15        # 25940 <base_dist>
    f359:	sub    (%r15,%r11,4),%edx
    f35d:	shl    %cl,%rdx
    f360:	add    %r8d,%ecx
    f363:	or     %rdx,%r9
    f366:	lea    (%rcx,%rdi,1),%edx
    f369:	cmp    $0x3f,%edx
    f36c:	ja     f470 <compress_block+0x250>
    f372:	cmp    $0x3f,%edi
    f375:	ja     f410 <compress_block+0x1f0>
    f37b:	mov    %edi,%ecx
    f37d:	add    $0x1,%rsi
    f381:	mov    %edx,%edi
    f383:	shl    %cl,%r9
    f386:	or     %r9,%r10
    f389:	cmp    %rbp,%rsi
    f38c:	jne    f2ad <compress_block+0x8d>
    f392:	nopw   0x0(%rax,%rax,1)
    f398:	mov    0x400(%rbx),%edx
    f39e:	movzwl %dx,%esi
    f3a1:	shr    $0x10,%edx
    f3a4:	lea    (%rdx,%rdi,1),%r8d
    f3a8:	cmp    $0x3f,%r8d
    f3ac:	ja     f4b0 <compress_block+0x290>
    f3b2:	cmp    $0x3f,%edi
    f3b5:	jbe    f4f0 <compress_block+0x2d0>
    f3bb:	mov    0x1c(%rax),%ecx
    f3be:	mov    0x8(%rax),%r9
    f3c2:	mov    %r10,(%r9,%rcx,1)
    f3c6:	addl   $0x8,0x1c(%rax)
    f3ca:	pop    %rbx
    f3cb:	pop    %rbp
    f3cc:	mov    %edx,0x1780(%rax)
    f3d2:	pop    %r12
    f3d4:	pop    %r13
    f3d6:	mov    %rsi,0x1778(%rax)
    f3dd:	pop    %r14
    f3df:	pop    %r15
    f3e1:	ret
    f3e2:	nopw   0x0(%rax,%rax,1)
    f3e8:	mov    %edx,%r8d
    f3eb:	lea    0x1674e(%rip),%r15        # 25b40 <zng_dist_code>
    f3f2:	shr    $0x7,%r8d
    f3f6:	add    $0x100,%r8d
    f3fd:	movzbl (%r15,%r8,1),%r11d
    f402:	jmp    f324 <compress_block+0x104>
    f407:	nopw   0x0(%rax,%rax,1)
    f410:	mov    0x1c(%rax),%r8d
    f414:	mov    0x8(%rax),%r12
    f418:	mov    %r10,(%r12,%r8,1)
    f41c:	mov    %ecx,%edi
    f41e:	mov    %r9,%r10
    f421:	addl   $0x8,0x1c(%rax)
    f425:	jmp    f2a0 <compress_block+0x80>
    f42a:	nopw   0x0(%rax,%rax,1)
    f430:	mov    0x1c(%rax),%r8d
    f434:	mov    0x8(%rax),%r12
    f438:	lea    (%r12,%r8,1),%rdx
    f43c:	cmp    $0x3f,%edi
    f43f:	ja     f418 <compress_block+0x1f8>
    f441:	mov    %edi,%ecx
    f443:	mov    %r9,%r8
    f446:	shl    %cl,%r8
    f449:	mov    %r8,%rcx
    f44c:	or     %r10,%rcx
    f44f:	mov    %r9,%r10
    f452:	mov    %rcx,(%rdx)
    f455:	mov    $0x40,%ecx
    f45a:	sub    %edi,%ecx
    f45c:	addl   $0x8,0x1c(%rax)
    f460:	lea    -0x40(%r11),%edi
    f464:	shr    %cl,%r10
    f467:	jmp    f2a0 <compress_block+0x80>
    f46c:	nopl   0x0(%rax)
    f470:	mov    0x1c(%rax),%r8d
    f474:	mov    0x8(%rax),%r12
    f478:	lea    (%r12,%r8,1),%r11
    f47c:	cmp    $0x3f,%edi
    f47f:	ja     f418 <compress_block+0x1f8>
    f481:	mov    %edi,%ecx
    f483:	mov    %r9,%r8
    f486:	shl    %cl,%r8
    f489:	mov    %r8,%rcx
    f48c:	or     %r10,%rcx
    f48f:	mov    %r9,%r10
    f492:	mov    %rcx,(%r11)
    f495:	mov    $0x40,%ecx
    f49a:	sub    %edi,%ecx
    f49c:	addl   $0x8,0x1c(%rax)
    f4a0:	lea    -0x40(%rdx),%edi
    f4a3:	shr    %cl,%r10
    f4a6:	jmp    f2a0 <compress_block+0x80>
    f4ab:	nopl   0x0(%rax,%rax,1)
    f4b0:	mov    0x1c(%rax),%ecx
    f4b3:	mov    0x8(%rax),%r9
    f4b7:	lea    (%r9,%rcx,1),%r11
    f4bb:	cmp    $0x3f,%edi
    f4be:	ja     f3c2 <compress_block+0x1a2>
    f4c4:	mov    %rsi,%rdx
    f4c7:	mov    %edi,%ecx
    f4c9:	shl    %cl,%rdx
    f4cc:	mov    $0x40,%ecx
    f4d1:	or     %r10,%rdx
    f4d4:	sub    %edi,%ecx
    f4d6:	mov    %rdx,(%r11)
    f4d9:	shr    %cl,%rsi
    f4dc:	lea    -0x40(%r8),%edx
    f4e0:	addl   $0x8,0x1c(%rax)
    f4e4:	jmp    f3ca <compress_block+0x1aa>
    f4e9:	nopl   0x0(%rax)
    f4f0:	mov    %edi,%ecx
    f4f2:	mov    %r8d,%edx
    f4f5:	shl    %cl,%rsi
    f4f8:	or     %r10,%rsi
    f4fb:	jmp    f3ca <compress_block+0x1aa>

Disassembly of section .fini:
