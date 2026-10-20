
/pool/wrf-experiment/wrf-cpu/kernels/compress-block-local-carry-native-hpc04-r1/output/parent-libz.so.1.3.1.zlib-ng:     file format elf64-x86-64


Disassembly of section .init:

Disassembly of section .plt:

Disassembly of section .plt.got:

Disassembly of section .text:

000000000000f220 <compress_block>:
    f220:	push   %r15
    f222:	mov    %rdi,%rax
    f225:	push   %r14
    f227:	mov    0x1778(%rax),%r8
    f22e:	push   %r13
    f230:	push   %r12
    f232:	push   %rbp
    f233:	push   %rbx
    f234:	mov    0x1740(%rdi),%ebp
    f23a:	mov    %rsi,%rbx
    f23d:	mov    0x1780(%rdi),%edi
    f243:	mov    %edi,%r11d
    f246:	test   %ebp,%ebp
    f248:	je     f3e8 <compress_block+0x1c8>
    f24e:	mov    %rdx,-0x8(%rsp)
    f253:	mov    0x1730(%rax),%r14
    f25a:	xor    %esi,%esi
    f25c:	mov    0x1738(%rax),%r13
    f263:	jmp    f2aa <compress_block+0x8a>
    f265:	nopl   (%rax)
    f268:	mov    (%rbx,%rcx,4),%edx
    f26b:	movzwl %dx,%r9d
    f26f:	shr    $0x10,%edx
    f272:	lea    (%rdx,%rdi,1),%r11d
    f276:	mov    %r11d,%ecx
    f279:	or     %edi,%ecx
    f27b:	cmp    $0x3f,%ecx
    f27e:	ja     f3c0 <compress_block+0x1a0>
    f284:	mov    %edi,%ecx
    f286:	shl    %cl,%r9
    f289:	or     %r9,%r8
    f28c:	add    $0x1,%rsi
    f290:	mov    %r11d,0x1780(%rax)
    f297:	mov    %r11d,%edi
    f29a:	mov    %r8,0x1778(%rax)
    f2a1:	cmp    %rsi,%rbp
    f2a4:	je     f3e8 <compress_block+0x1c8>
    f2aa:	movzwl (%r14,%rsi,2),%edx
    f2af:	movzbl 0x0(%r13,%rsi,1),%ecx
    f2b5:	test   %edx,%edx
    f2b7:	je     f268 <compress_block+0x48>
    f2b9:	movzbl %cl,%ecx
    f2bc:	lea    0x1677d(%rip),%r10        # 25a40 <zng_length_code>
    f2c3:	lea    0x17076(%rip),%r11        # 26340 <extra_lbits>
    f2ca:	movzbl (%r10,%rcx,1),%r10d
    f2cf:	mov    %rcx,%r9
    f2d2:	lea    0x101(%r10),%ecx
    f2d9:	mov    (%r11,%r10,4),%r11d
    f2dd:	movslq %ecx,%rcx
    f2e0:	mov    (%rbx,%rcx,4),%ecx
    f2e3:	movzwl %cx,%r12d
    f2e7:	shr    $0x10,%ecx
    f2ea:	test   %r11d,%r11d
    f2ed:	je     f303 <compress_block+0xe3>
    f2ef:	lea    0x166ca(%rip),%r15        # 259c0 <base_length>
    f2f6:	sub    (%r15,%r10,4),%r9d
    f2fa:	shl    %cl,%r9
    f2fd:	add    %r11d,%ecx
    f300:	or     %r9,%r12
    f303:	sub    $0x1,%edx
    f306:	cmp    $0xff,%edx
    f30c:	ja     f380 <compress_block+0x160>
    f30e:	mov    %edx,%r9d
    f311:	lea    0x16828(%rip),%r15        # 25b40 <zng_dist_code>
    f318:	movzbl (%r15,%r9,1),%r11d
    f31d:	mov    -0x8(%rsp),%r15
    f322:	movzbl %r11b,%r9d
    f326:	mov    (%r15,%r9,4),%r9d
    f32a:	movzwl %r9w,%r10d
    f32e:	shr    $0x10,%r9d
    f332:	shl    %cl,%r10
    f335:	add    %r9d,%ecx
    f338:	lea    0x16f81(%rip),%r9        # 262c0 <extra_dbits>
    f33f:	mov    (%r9,%r11,4),%r9d
    f343:	or     %r12,%r10
    f346:	test   %r9d,%r9d
    f349:	je     f35f <compress_block+0x13f>
    f34b:	lea    0x165ee(%rip),%r15        # 25940 <base_dist>
    f352:	sub    (%r15,%r11,4),%edx
    f356:	shl    %cl,%rdx
    f359:	add    %r9d,%ecx
    f35c:	or     %rdx,%r10
    f35f:	lea    (%rcx,%rdi,1),%r11d
    f363:	mov    %r11d,%edx
    f366:	or     %edi,%edx
    f368:	cmp    $0x3f,%edx
    f36b:	ja     f3a0 <compress_block+0x180>
    f36d:	mov    %edi,%ecx
    f36f:	shl    %cl,%r10
    f372:	or     %r10,%r8
    f375:	jmp    f28c <compress_block+0x6c>
    f37a:	nopw   0x0(%rax,%rax,1)
    f380:	mov    %edx,%r9d
    f383:	lea    0x167b6(%rip),%r15        # 25b40 <zng_dist_code>
    f38a:	shr    $0x7,%r9d
    f38e:	add    $0x100,%r9d
    f395:	movzbl (%r15,%r9,1),%r11d
    f39a:	jmp    f31d <compress_block+0xfd>
    f39c:	nopl   0x0(%rax)
    f3a0:	mov    0x1c(%rax),%edx
    f3a3:	add    0x8(%rax),%rdx
    f3a7:	cmp    $0x3f,%edi
    f3aa:	jbe    f428 <compress_block+0x208>
    f3ac:	mov    %r8,(%rdx)
    f3af:	mov    %ecx,%r11d
    f3b2:	mov    %r10,%r8
    f3b5:	addl   $0x8,0x1c(%rax)
    f3b9:	jmp    f28c <compress_block+0x6c>
    f3be:	xchg   %ax,%ax
    f3c0:	mov    0x1c(%rax),%r10d
    f3c4:	add    0x8(%rax),%r10
    f3c8:	cmp    $0x3f,%edi
    f3cb:	jbe    f458 <compress_block+0x238>
    f3d1:	mov    %r8,(%r10)
    f3d4:	mov    %edx,%r11d
    f3d7:	mov    %r9,%r8
    f3da:	addl   $0x8,0x1c(%rax)
    f3de:	jmp    f28c <compress_block+0x6c>
    f3e3:	nopl   0x0(%rax,%rax,1)
    f3e8:	mov    0x400(%rbx),%edx
    f3ee:	movzwl %dx,%esi
    f3f1:	shr    $0x10,%edx
    f3f4:	lea    (%rdx,%r11,1),%edi
    f3f8:	mov    %edi,%ecx
    f3fa:	or     %r11d,%ecx
    f3fd:	cmp    $0x3f,%ecx
    f400:	ja     f480 <compress_block+0x260>
    f402:	mov    %r11d,%ecx
    f405:	shl    %cl,%rsi
    f408:	or     %r8,%rsi
    f40b:	pop    %rbx
    f40c:	pop    %rbp
    f40d:	mov    %edi,0x1780(%rax)
    f413:	pop    %r12
    f415:	pop    %r13
    f417:	mov    %rsi,0x1778(%rax)
    f41e:	pop    %r14
    f420:	pop    %r15
    f422:	ret
    f423:	nopl   0x0(%rax,%rax,1)
    f428:	mov    %edi,%ecx
    f42a:	mov    %r10,%r15
    f42d:	sub    $0x40,%r11d
    f431:	shl    %cl,%r15
    f434:	mov    %r15,%rcx
    f437:	or     %r8,%rcx
    f43a:	mov    %r10,%r8
    f43d:	mov    %rcx,(%rdx)
    f440:	mov    $0x40,%ecx
    f445:	sub    %edi,%ecx
    f447:	addl   $0x8,0x1c(%rax)
    f44b:	shr    %cl,%r8
    f44e:	jmp    f28c <compress_block+0x6c>
    f453:	nopl   0x0(%rax,%rax,1)
    f458:	mov    %edi,%ecx
    f45a:	mov    %r9,%rdx
    f45d:	sub    $0x40,%r11d
    f461:	shl    %cl,%rdx
    f464:	mov    $0x40,%ecx
    f469:	or     %r8,%rdx
    f46c:	sub    %edi,%ecx
    f46e:	mov    %r9,%r8
    f471:	mov    %rdx,(%r10)
    f474:	shr    %cl,%r8
    f477:	addl   $0x8,0x1c(%rax)
    f47b:	jmp    f28c <compress_block+0x6c>
    f480:	mov    0x1c(%rax),%r9d
    f484:	add    0x8(%rax),%r9
    f488:	cmp    $0x3f,%r11d
    f48c:	jbe    f4a0 <compress_block+0x280>
    f48e:	mov    %r8,(%r9)
    f491:	mov    %edx,%edi
    f493:	addl   $0x8,0x1c(%rax)
    f497:	jmp    f40b <compress_block+0x1eb>
    f49c:	nopl   0x0(%rax)
    f4a0:	mov    %rsi,%rdx
    f4a3:	mov    %r11d,%ecx
    f4a6:	sub    $0x40,%edi
    f4a9:	shl    %cl,%rdx
    f4ac:	mov    $0x40,%ecx
    f4b1:	or     %r8,%rdx
    f4b4:	sub    %r11d,%ecx
    f4b7:	mov    %rdx,(%r9)
    f4ba:	shr    %cl,%rsi
    f4bd:	addl   $0x8,0x1c(%rax)
    f4c1:	jmp    f40b <compress_block+0x1eb>

Disassembly of section .fini:
