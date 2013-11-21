from cosmoslik import SlikPlugin, param, get_plugin

class main(SlikPlugin):

    def __init__(self):
        super(SlikPlugin,self).__init__(self)
        self.a = param(start=0.0222,scale=0.0005)
        self.b = param(start=0.120,scale=0.005)

        self.cosmo = get_plugin('models.cosmology')(
            Yp = param(start=0.248, scale=0.05)
        )

        self.sampler = get_plugin("samplers.metropolis_hastings")(self)
        
        
    def __call__(self):
        return self.a**2 + self.b**2
