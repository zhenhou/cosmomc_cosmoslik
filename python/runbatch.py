#!/usr/bin/env python
import os, batchJobArgs, jobQueue

Opts = batchJobArgs.batchArgs('Submit jobs to run chains or importance sample', notExist=True, converge=True)
Opts.parser.add_argument('--nodes', type=int, default=2)
Opts.parser.add_argument('--script', default='runMPI_HPCS.pl')

Opts.parser.add_argument('--dryrun', action='store_true')
Opts.parser.add_argument('--subitems', action='store_true')
Opts.parser.add_argument('--minimize', action='store_true')
Opts.parser.add_argument('--importance_minimize', action='store_true')
Opts.parser.add_argument('--minimize_failed', action='store_true')
Opts.parser.add_argument('--checkpoint_run', action='store_true')
Opts.parser.add_argument('--importance_ready', action='store_true')
Opts.parser.add_argument('--not_queued', action='store_true')


(batch, args) = Opts.parseForBatch()

if args.not_queued: 
    print 'Getting queued names...'
    queued = jobQueue.queued_jobs()
    
def notQueued(name):
    for job in queued:
        if name in job: 
#            print 'Already running:', name
            return False
    return True
        

variant = ''
if args.importance_minimize:
    variant = '_minimize'
    if args.importance is None: args.importance = []
    args.nodes = 0

if args.minimize:
    args.noimportance = True
    variant = '_minimize'
    args.nodes = 0

if args.importance is None: args.noimportance = True

isMinimize = args.importance_minimize or args.minimize

def submitJob(ini):
        command = 'perl ' + args.script + ' ' + ini + ' ' + str(args.nodes)
        if not args.dryrun:
            print 'Submitting...' + command
            os.system(command)
        else: print '...' + command

for jobItem in Opts.filteredBatchItems(wantSubItems=args.subitems):
        if (not args.notexist or isMinimize and not jobItem.chainMinimumExists()
       or not isMinimize and not jobItem.chainExists()) and (not args.minimize_failed or not jobItem.chainMinimumConverged()):
            if args.converge == 0 or jobItem.hasConvergeBetterThan(args.converge):
                if not args.checkpoint_run or jobItem.wantCheckpointContinue() and jobItem.notRunning():
                    if not args.importance_ready or not jobItem.isImportanceJob or jobItem.parent.chainFinished():
                        if not args.not_queued or notQueued(jobItem.name):
                            submitJob(jobItem.iniFile(variant))
