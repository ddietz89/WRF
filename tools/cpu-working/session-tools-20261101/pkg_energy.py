import os,struct,time,json,sys
def rd(cpu,reg):
    fd=os.open('/dev/cpu/%d/msr'%cpu,os.O_RDONLY)
    try: return struct.unpack('<Q',os.pread(fd,8,reg))[0]
    finally: os.close(fd)
unit=1.0/(1<<((rd(0,0xC0010299)>>8)&0x1f))
def sample(): return [rd(c,0xC001029B)*unit for c in (0,64)], time.monotonic()
a,t0=sample(); time.sleep(float(sys.argv[1])); b,t1=sample()
w=[((y-x)%(2**32*unit))/(t1-t0) for x,y in zip(a,b)]
fr=[int(open('/sys/devices/system/cpu/cpu%d/cpufreq/scaling_cur_freq'%c).read())//1000 for c in range(0,128) if c%16!=15]
print(json.dumps({'socket0_W':round(w[0],1),'socket1_W':round(w[1],1),'mean_MHz':sum(fr)//len(fr)}))
