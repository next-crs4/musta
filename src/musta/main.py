import argparse

from .__details__ import *

from comoda import a_logger, LOG_LEVELS, a_handler
from importlib import import_module

SUBMOD_NAMES = [
    "test",
]

SUBMODULES = [import_module("%s.%s" % (__package__, n)) for n in SUBMOD_NAMES]

class App(object):
    def __init__(self):
        self.supported_submodules = []
        for m in SUBMODULES:
            m.do_register(self.supported_submodules)

    def make_parser(self):

        parser = argparse.ArgumentParser(prog=__appname__,
                                         formatter_class=argparse.RawTextHelpFormatter,
                                         description=__description__)

        parser.add_argument('--input-dir', '-i',
                            type=str, metavar='PATH',
                            help='input folder path')

        parser.add_argument('--output-dir', '-o',
                            type=str, metavar='PATH',
                            help='output folder path')

        parser.add_argument('--work-dir', '-w',
                            type=str, metavar='PATH',
                            help='working folder path')

        parser.add_argument('--reference-dir', '-r',
                            type=str, metavar='PATH',
                            help='reference folder path')

        parser.add_argument('--samples', '-s',
                            type=str, metavar='PATH',
                            help='sample list file in YAML format')

        parser.add_argument('--config_file', '-c',
                            type=str, metavar='PATH',
                           help='configuration file',
                           default='/code/src/musta/config/musta_config.yml')

        parser.add_argument('--logfile', type=str, metavar='PATH',
                            help='log file (default=stderr)')

        parser.add_argument('--loglevel', type=str, help='logger level.',
                            choices=LOG_LEVELS, default='INFO')

        subparsers = parser.add_subparsers(dest='subparser_name',
                                           title='subcommands',
                                           description='valid subcommands',
                                           help='sub-command description')

        for k, h, addarg, impl in self.supported_submodules:
            subparser = subparsers.add_parser(k, help=h)
            addarg(subparser)
            subparser.set_defaults(func=impl)

        return parser


def main(argv):
    app = App()
    parser = app.make_parser()
    args = parser.parse_args(argv)
    logger = a_logger('main', level=args.loglevel, filename=args.logfile)
    logger.addHandler(a_handler())

    args.func(logger, args)

