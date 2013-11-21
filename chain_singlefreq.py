from cosmoslik import param_shortcut, lsum, get_plugin, SlikDict, SlikPlugin, Slik
from numpy import identity, exp, inf, arange, hstack, loadtxt, zeros, ones
import os.path as osp
import sys
import cPickle
import mspec as M      
import pypico
        
param = param_shortcut('start','scale')

mask='4'
spec=('143','143')
doclean=True
lrange=(50,2500)
model='lcdm'

root = '/global/scratch2/sd/marius/us2/'

class main(SlikPlugin):
    
    def __init__(self):
        super(SlikPlugin,self).__init__()
    
        # This part ignored when calling from CosmoMC
        #
        self.cosmo = get_plugin('models.cosmology')(
            logA = param(3.2),
            ns = param(0.96),
            ombh2 = param(0.0221),
            omch2 = param(0.12),
            tau = param(0.09,min=0,**(dict(gaussian_prior=(0.085,0.015)) if 'taup' in model else dict())),
            theta = param(0.010413),
            omnuh2 = 0.000645
        )
        if 'neff' in model.lower(): self.cosmo.massive_neutrinos = param(3,.2)
        if 'yp' in model.lower(): self.cosmo.Yp = param(.24,0.1)
        if 'mnu' in model.lower(): self.cosmo.omnuh2 = param(0,0.001,range=(0,1))
        #
        
        
        self.egfs = SlikDict(
            aksz=param(2,2,range=(0,5)),
            aps=param(10,10,range=(0,800)),
            acib=param(10,5,range=(0,100)),
            ncib=param(1,0.2,range=(-1,1.5),gaussian_prior=(0.8,0.2)),
            argal=param(10 if doclean else 50,2,min=-20),
            nrgal=-0.5 if doclean else param(-0.5,0.1,range=(-1,0)),
            atsz=0 if '217' in spec else param(4,2,range=(0,30))
        )
        
        self.norm_ell = float(3000.)
        def norm(dl,norm=self.norm_ell): return dl/dl[norm]
        self.tsz_template = norm(hstack([[0,0],loadtxt(osp.join(root,"runs/preDX11allmasks/templates/tsz_143_eps0.50.dat"))[:,1],zeros(10000)]))
        self.ksz_template = norm(hstack([[0,0],loadtxt(osp.join(root,"runs/preDX11allmasks/templates/cl_ksz_148_trac.dat"))[:,1],zeros(10000)]))


        self.get_cmb = get_plugin('models.pico')(
            datafile=osp.join(root,'pico/pico.tailmonty.v31.dat')
        )

        self.bbn = get_plugin('models.bbn_consistency')()
#         self.hubble_theta = get_plugin('models.hubble_theta')()
        
        if 'taup' in model:
            self.lowl = lambda *arg, **kwargs: {}
        else:
            self.lowl = get_plugin('models.pico')(
                datafile=osp.join(root,'pico/pico.tailmonty.plancklike.dat')
            )
        
        
        with open(osp.join(root,'runs/preDX11allmasks/signals/mask%s.dat'%mask)) as f: signal = cPickle.load(f)
        signal.binning = M.get_bin_func('wmap')
        if doclean:
            cleaning={('T','100'):{('T','100'):1,('T','545'):-2.73e-5},
                      ('T','143'):{('T','143'):1,('T','545'):-4.08e-5},
                      ('T','217'):{('T','217'):1,('T','545'):-0.0001391}}
        else:
            cleaning={('T','100'):{('T','100'):1},
                      ('T','143'):{('T','143'):1},
                      ('T','217'):{('T','217'):1}}
        self.mspec = get_plugin('likelihoods.mspec_lnl')(
            signal=signal,
            cleaning=cleaning,
            use={(('T',spec[0]),('T',spec[1])):lrange},
        )
        
        self.priors = get_plugin('likelihoods.priors')(self)
        
    
        # This part ignored when calling from CosmoMC
        #
        output_file = 'chains/singlefreq_%smask%s_%s_%s_%s.chain'%('' if doclean else 'unclean_',mask,'x'.join(spec),'%i_%i'%lrange,model)
        self.sampler = get_plugin('samplers.metropolis_hastings')(
             self,
             num_samples=1000000,
             output_file=output_file,
             proposal_cov=osp.join(root,'runs/preDX11allmasks/slik.covmat'),
             proposal_scale=1,
             print_level=1,
             output_extra_params=['cosmo.Yp','cosmo.H0']
        )
        #
        
        print 'Running chain %s...'%output_file
    
    def __call__(self):
        if not 'cmb_result' in self:
            self.cosmo.As = exp(self.cosmo.logA)*1e-10
            if 'yp' not in model.lower(): self.cosmo.Yp = self.bbn(**self.cosmo)
#             self.cosmo.H0 = self.hubble_theta.theta_to_hubble(**self.cosmo)
            self.cmb_result = self.get_cmb(outputs=['cl_TT'],force=True,**self.cosmo)
        
        def egfs_fn(lmax,**kwargs):
            ells = hstack([ones(2),arange(2,lmax)/self.norm_ell])
            return (self.egfs.aps * ells**2 + 
                    self.egfs.aksz * self.ksz_template[:lmax] +
                    self.egfs.atsz * self.tsz_template[:lmax] +
                    self.egfs.acib * ells**self.egfs.ncib + 
                    self.egfs.argal * (ells*(self.norm_ell/1000.))**self.egfs.nrgal)
            
        self.egfs_result = egfs_fn
        
        
        #This plots the data points and current CMB+fg model
#         from matplotlib.pyplot import semilogy, show, subplot
#         ax=subplot(111)
#         self.mspec.processed_signal.plot(which=[(('T',spec[0]),('T',spec[1]))],ax=ax)
#         self.mspec.get_cl_model(self.cmb_result,self.egfs_result).plot(which=[(('T',spec[0]),('T',spec[1]))],ax=ax)
#         show()
        #
        
        
        return lsum(lambda: self.priors(self),
                    lambda: sum(self.lowl(outputs=None,force=True,**self.cosmo).values()),
                    lambda: self.mspec(self.cmb_result,
                                       self.egfs_result))

