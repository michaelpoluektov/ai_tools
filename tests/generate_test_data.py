#!/usr/bin/env python

# Copyright (c) 2019, XMOS Ltd, All rights reserved

import os
import re
import json
import shutil
import subprocess
import argparse
import directories

import multiprocessing as mp

from functools import partial

os.environ["CUDA_VISIBLE_DEVICES"] = "-1"  # this should happen before tf is loaded
stdout_lock = mp.Lock()


def make_folder_and_arguments(**kwargs):
    folder_fields = []
    aurgment_fields = []
    compiled_re = re.compile(r'(?<=-)\w+')

    if kwargs:
        for key, value in kwargs.items():
            if key == 'smoke':
                continue
            elif key.startswith('-'):
                hyphenless_key = compiled_re.search(key).group(0)  # strip off leading hyphens
            else:
                hyphenless_key = key

            if isinstance(value, list):
                value_folder_str = 'x'.join([str(v).lower() for v in value])
                value_argument_str = ' '.join([str(v) for v in value])
            else:
                value_folder_str = str(value).lower()
                value_argument_str = str(value)

            folder_fields.append(f'{hyphenless_key}={value_folder_str}')
            if key != 'xfail':
                aurgment_fields.append(f'{key} {value_argument_str}')

        return '_'.join(folder_fields), ' '.join(aurgment_fields)
    else:
        return 'defaults', ''


def generate_test_case(dry_run, test_case):
    operator = test_case['operator']
    generator = test_case['generator']
    subtype = test_case['subtype']
    if 'parameters' in test_case:
        parameters = test_case['parameters']
    else:
        parameters = {}

    if test_case['train_model']:
        train_model_flag = '--train_model'
    else:
        train_model_flag = ''

    folder, arguments = make_folder_and_arguments(**parameters)
    output_dir = os.path.join(directories.OP_TEST_MODELS_DATA_DIR, operator, subtype, folder)
    cmd = f'python {generator} {train_model_flag} {arguments} -path {output_dir}'
    with stdout_lock:
        print(f'running: {cmd}')
    if not dry_run:
        try:
            subprocess.check_output(cmd, stderr=subprocess.STDOUT, shell=True)
        except subprocess.CalledProcessError as cmdexc:
            print(cmdexc.output.decode('utf-8'))


def load_test_cases(test_file, smoke=False):
    test_cases = []
    with open(test_file, 'r') as fd:
        operators = json.loads(fd.read())
        for operator in operators:
            for params in operator['parameters']:
                if not smoke or (smoke and params.get('smoke', False)):
                    test_cases.append({
                        'operator': operator['operator'],
                        'subtype': operator.get('subtype', ''),
                        'generator': operator['generator'],
                        'train_model': operator.get('train_model', False),
                        'parameters': params
                    })
    return test_cases


def run_generate(test_file, jobs, *, dry_run=False, smoke=False):
    test_cases = load_test_cases(test_file, smoke)

    # Remove all existing data
    if not dry_run:
        if os.path.exists(directories.DATA_DIR):
            shutil.rmtree(directories.DATA_DIR)

    # now generate all the test cases
    pool = mp.Pool(processes=jobs)
    func = partial(generate_test_case, dry_run)
    pool.map(func, test_cases)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument(
        '-t', '--test-file', default='tests.json',
        help="Test to run (defaults to tests.json)"
    )
    parser.add_argument(
        '-n', '--workers', type=int, default=1,
        help="Allow generation in N processes at once"
    )
    parser.add_argument(
        '--smoke', action='store_true', default=False,
        help='Run smoke tests (smoke_tests.json)'
    )
    parser.add_argument(
        '--dry-run', action='store_true', default=False,
        help='Perform a dry run'
    )
    args = parser.parse_args()

    cpu_count = mp.cpu_count()
    if args.workers == -1 or args.workers > cpu_count:
        args.workers = cpu_count
    elif args.workers == 0:
        args.dry_run = True
        args.workers = 1
    elif args.workers < -1:
        raise argparse.ArgumentTypeError(f"Invalid number of workers: {args.workers}")

    run_generate(args.test_file, args.workers,
        dry_run=args.dry_run, smoke=args.smoke)
