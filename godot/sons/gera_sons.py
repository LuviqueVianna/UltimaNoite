import numpy as np, sys
from scipy.io import wavfile
from scipy.signal import butter, sosfilt
SR=44100; rng=np.random.default_rng(7)
pasta=sys.argv[1]
def t(d): return np.arange(int(SR*d))/SR
def bp(x,lo,hi,o=4): return sosfilt(butter(o,[lo,hi],'bandpass',fs=SR,output='sos'),x)
def lp(x,f,o=4): return sosfilt(butter(o,f,'lowpass',fs=SR,output='sos'),x)
def ler(n):
    sr,x=wavfile.read(f"{pasta}/{n}.wav"); x=x.astype(np.float32); return x/np.max(np.abs(x))
def por(base,x,ini):
    i=int(ini*SR); fim=min(len(base),i+len(x)); base[i:fim]+=x[:fim-i]; return base
def norm(x): return (x/np.max(np.abs(x))*0.95).astype(np.float32)
def salvar(n,x): wavfile.write(f"{pasta}/{n}.wav",SR,norm(x))

# Mola de ferro fechando: estalo + ressonância metálica inarmônica + o galho quebrando
d=1.4; x=np.zeros(int(SR*d))
tt=t(0.9)
metal=sum(a*np.sin(2*np.pi*f*tt)*np.exp(-tt*k) for f,a,k in [(812,1,5),(1297,.7,7),(2143,.5,9),(3460,.35,12),(5120,.2,16)])
estalo=bp(rng.standard_normal(int(SR*0.03)),1500,9000)*np.exp(-t(0.03)*120)
x=por(x,estalo*1.4,0.0); x=por(x,metal*0.55,0.0)
x=por(x,bp(rng.standard_normal(int(SR*0.04)),800,6000)*np.exp(-t(0.04)*90)*0.6,0.09)  # repique
x=por(x,ler('galho')[:int(SR*1.2)]*0.8,0.02)
salvar('armadilha_mola',x)

# Cobra: chacoalho/sibilo curto, bote (estalo seco) e baque leve
d=1.1; x=np.zeros(int(SR*d))
tt=t(0.55); env=np.minimum(tt/0.05,1)*np.exp(-np.maximum(tt-0.3,0)*12)
sib=bp(rng.standard_normal(len(tt)),3500,9500)*env*(0.7+0.3*np.sin(2*np.pi*28*tt))
x=por(x,sib*0.8,0.0)
bote=bp(rng.standard_normal(int(SR*0.025)),400,5000)*np.exp(-t(0.025)*150)
x=por(x,bote*1.6,0.5)
x=por(x,lp(rng.standard_normal(int(SR*0.12)),300)*np.exp(-t(0.12)*35)*1.2,0.51)
tt=t(0.5); x=por(x,bp(rng.standard_normal(len(tt)),4000,9000)*np.exp(-tt*9)*0.35,0.56)  # sibilo de recuo
salvar('cobra_pica',x)

# Lobo derrubando: rosnado, estalo de mandíbula e o baque do corpo no chão
r=ler('rosna'); d=max(1.6,len(r)/SR); x=np.zeros(int(SR*d))
x=por(x,r*0.8,0.0)
mand=bp(rng.standard_normal(int(SR*0.02)),1000,7000)*np.exp(-t(0.02)*180)
x=por(x,mand*1.5,0.28); x=por(x,mand*1.1,0.36)
tt=t(0.45); baque=(np.sin(2*np.pi*(70-40*tt)*tt)*1.0+lp(rng.standard_normal(len(tt)),250)*1.5)*np.exp(-tt*11)
x=por(x,baque*1.3,0.4)
x=por(x,lp(rng.standard_normal(int(SR*0.5)),1200)*np.exp(-t(0.5)*7)*0.35,0.42)  # folhas remexidas
salvar('lobo_morde',x)
print('ok')
