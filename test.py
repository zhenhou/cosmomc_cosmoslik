from cosmoslik import SlikPlugin, param, get_plugin

class main(SlikPlugin):

    def __init__(self):
        super(SlikPlugin,self).__init__(self)
        self.a = param(start=0,scale=1)
        self.b = param(start=1,scale=1)
        self.sampler = get_plugin("samplers.metropolis_hastings")(self)
