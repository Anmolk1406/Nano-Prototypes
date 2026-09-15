import numpy as np

def _down(a):
    # a: HxW or HxWxC float. 2x2 box mean, pad edge to even.
    if a.shape[0]%2: a=np.concatenate([a,a[-1:]],0)
    if a.shape[1]%2: a=np.concatenate([a,a[:,-1:]],1)
    h,w=a.shape[0]//2,a.shape[1]//2
    if a.ndim==2: return a.reshape(h,2,w,2).mean((1,3))
    return a.reshape(h,2,w,2,a.shape[2]).mean((1,3))

def _up(a,shape):
    h,w=shape
    b=np.repeat(np.repeat(a,2,axis=0),2,axis=1)[:h,:w]
    if b.shape[0]<h: b=np.concatenate([b]+[b[-1:]]*(h-b.shape[0]),0)
    if b.shape[1]<w: b=np.concatenate([b]+[b[:,-1:]]*(w-b.shape[1]),1)
    # 3-tap smooth to remove blockiness
    for ax in (0,1):
        b=(np.roll(b,1,ax)+2*b+np.roll(b,-1,ax))/4.0
    return b

def pushpull(im, known, min_size=2):
    """Harmonic-style fill of `im` (HxWxC float) wherever known==0."""
    pi=[im*known[...,None]]; pw=[known.astype(np.float64).copy()]
    while min(pw[-1].shape[:2])>min_size:
        pi.append(_down(pi[-1])); pw.append(_down(pw[-1]))
    cur=pi[-1]/np.maximum(pw[-1][...,None],1e-9)
    for l in range(len(pw)-2,-1,-1):
        u=_up(cur,pw[l].shape[:2])
        wl=np.clip(pw[l],0,1)[...,None]
        base=pi[l]/np.maximum(pw[l][...,None],1e-9)
        cur=base*wl+u*(1-wl)
    return np.clip(cur,0,1)
