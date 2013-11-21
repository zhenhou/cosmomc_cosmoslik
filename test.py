from cosmoslik import SlikPlugin, param, get_plugin

class main(SlikPlugin):

    def __init__(self):
        super(SlikPlugin,self).__init__(self)
        self.omegabh2 = param(start=0.0222,scale=0.0005)
        self.omegach2 = param(start=0.120,scale=0.005)
        self.theta = param(start=1.040,scale=0.000)

        self.cosmo = get_plugin('models.cosmology')(
            Yp = param(start=0.248, scale=0.05)
        )

        self.sampler = get_plugin("samplers.metropolis_hastings")(self)
        
        
    def __call__(self):
        return self.a**2 + self.b**2
