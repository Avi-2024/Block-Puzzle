"""Reject installable APKs that advertise an ABI but omit its Flutter runtime."""
from pathlib import Path
import argparse
import hashlib
from zipfile import ZipFile


def check(path):
    with ZipFile(path) as apk:
        corrupt = apk.testzip()
        if corrupt:
            raise ValueError(f'Corrupt APK entry: {corrupt}')
        entries = set(apk.namelist())
        abis = {name.split('/')[1] for name in entries if name.startswith('lib/') and name.endswith('.so')}
        missing = [f'lib/{abi}/{library}' for abi in sorted(abis)
                   for library in ('libflutter.so', 'libapp.so')
                   if f'lib/{abi}/{library}' not in entries]
        if missing:
            raise ValueError('Missing runtime libraries: ' + ', '.join(missing))
        expected = {'arm64-v8a', 'armeabi-v7a', 'x86_64'}
        if abis != expected:
            raise ValueError(f'Universal build expected {expected}; found {abis}')
    return {'abis': sorted(abis), 'sha256': hashlib.sha256(Path(path).read_bytes()).hexdigest()}


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('apk')
    print(check(parser.parse_args().apk))
