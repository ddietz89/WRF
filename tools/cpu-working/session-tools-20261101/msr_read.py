import os,struct,sys
def rd(cpu,reg):
    fd=os.open('/dev/cpu/%d/msr'%cpu,os.O_RDONLY)
    try: return struct.unpack('<Q',os.pread(fd,8,reg))[0]
    finally: os.close(fd)
out={}
h=rd(0,0xC0010015); out['HWCR']=hex(h); out['CpbDis(boost disabled)']=(h>>25)&1
lim=rd(0,0xC0010061); out['PStateCurLim']=hex(lim)+' CurPstateLimit=%d PstateMaxVal=%d'%(lim&7,(lim>>4)&7)
out['PStateStat(cpu0)']=rd(0,0xC0010063)&7
for i in range(8):
    v=rd(0,0xC0010064+i)
    if v>>63:
        fid=v&0xff; did=(v>>8)&0x3f; vid=(v>>14)&0xff
        mhz=fid*200//did if did else 0
        out['PStateDef%d'%i]='%d MHz (fid=%d did=%d vid=0x%x)'%(mhz,fid,did,vid)
pu=rd(0,0xC0010299); out['RAPL_PWR_UNIT']=hex(pu)
out['CoreEnergy_cpu0']=rd(0,0xC001029A); out['PkgEnergy']=rd(0,0xC001029B)
for k,v in out.items(): print('%-24s %s'%(k,v))
