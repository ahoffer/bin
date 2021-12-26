#!/usr/bin/env python3
# Python 3.8+

# TODO I think this is a work in progress. Needs to be tested at the very least.


import argparse
from pathlib import Path
from sys import exit
import time
import sys
import shutil
import subprocess

parser = argparse.ArgumentParser()
parser.add_argument("tag")
args = parser.parse_args()

SCRIPT_DEST_DIR = '/media/aaron/HOFFER_BACKUP/scripts'
SCRIPT_FILENAMES = ['backup', 'restore']
SCRIPT_SOURCE_DIR = '/home/aaron/bin'
CHANGE_TO_DIR = '/home/aaron'

# BACKINGUP is a the directory (or file) relative to the CHANGE_TO
# directory that will be tarred, zipped, and encrypted (archived).
# When BACKINGUP is set to the dot '.' (current dir),
# an archive is created for the entire CHANGE_TO directory.
BACKINGUP = '.'

tmp_tar_filepath = Path(f'/tmp/backup-{args.tag}.tar.gz')
tmp_encrypt_filepath = Path(f'{tmp_tar_filepath}.aes')


def save_scripts():
    # Save the scripts that handle the backup and restore as plain text.
    dest_dir = Path(SCRIPT_DEST_DIR)
    dest_dir.mkdir(parents=True, exist_ok=True)
    source_dir = Path(SCRIPT_SOURCE_DIR)
    for fname in SCRIPT_FILENAMES:
        shutil.copy(source_dir.joinpath(fname), dest_dir.joinpath(fname))


# BEGIN MAIN FUNCTION
save_scripts()
print(f'...Creating archive for "{Path(CHANGE_TO_DIR).joinpath(BACKINGUP)}"')
tar_process = subprocess.run('tar', 'cz', '-C', CHANGE_TO_DIR, '-f', tmp_tar_filepath,
                             "--exclude='.m2/repository'", "--exclude='.cache'",
                             "--exclude='.local/share/Trash'", BACKINGUP)
