#!/usr/bin/env python3
"""Restaura la pieza de archivos del respaldo del kit hefesto-academia.

Uso:
  python3 scripts/restore_files.py <respaldo> --dry-run
  python3 scripts/restore_files.py <respaldo> --confirmar CONFIRMAR_RESTAURACION

El destino debe estar VACIO: nunca se sobrescriben datos existentes.
"""
import argparse
import datetime
import hashlib
import json
import os
import subprocess
import sys
import tarfile
import tempfile
from pathlib import Path, PurePosixPath

ROOT = Path(__file__).resolve().parents[1]
os.chdir(ROOT)
KIT = json.loads((ROOT / 'scripts' / 'kit.json').read_text())
TOKEN = 'CONFIRMAR_RESTAURACION'
PIEZA = 'moodledata.tar.gz'
VOLUMEN = '/var/moodledata'


def dc(*args, **kw):
    return subprocess.run(['docker', 'compose', *args], check=True, **kw)


def main(argv=None):
    ap = argparse.ArgumentParser(description='Restaura ' + PIEZA)
    ap.add_argument('respaldo')
    ap.add_argument('--dry-run', action='store_true')
    ap.add_argument('--confirmar', metavar=TOKEN)
    args, extras = ap.parse_known_args(argv)
    respaldo = Path(args.respaldo).resolve()
    verificador = ROOT / 'scripts' / 'check_backup.py'
    proc = subprocess.run([sys.executable, str(verificador), str(respaldo),
                           '--software', KIT['software']], capture_output=True, text=True)
    if proc.returncode != 0:
        print((proc.stderr or proc.stdout).strip(), file=sys.stderr)
        sys.exit(proc.returncode or 2)
    print('Plan (no se ejecuta nada): restaurar ' + PIEZA + ' sobre el volumen de ' + VOLUMEN + '.')
    if args.dry_run:
        print('Modo ensayo: no se escribio nada.')
        return 0
    if args.confirmar != TOKEN:
        print('Falta --confirmar ' + TOKEN + ': no se escribio nada.', file=sys.stderr)
        return 1
    with tempfile.TemporaryDirectory(prefix='hefesto-restore-files-') as tmp:
        destino = Path(tmp)
        with tarfile.open(respaldo / 'data.tar.gz', 'r:gz') as tf:
            for miembro in tf.getmembers():
                if miembro.isfile() and PurePosixPath(miembro.name).name == PIEZA:
                    tf.extract(miembro, destino)
        pieza = destino / PIEZA
        if not pieza.is_file():
            print('El respaldo no contiene ' + PIEZA, file=sys.stderr)
            return 2
        with tarfile.open(pieza, 'r:gz') as tf:
            for miembro in tf:
                nombre = PurePosixPath(miembro.name)
                if nombre.is_absolute() or '..' in nombre.parts:
                    print('Ruta no admitida dentro del archivo', file=sys.stderr)
                    return 2
        if dc('ps', '--status', 'running', '-q', 'web',
              capture_output=True, text=True).stdout.strip():
            print('Detener web antes de restaurar', file=sys.stderr)
            return 1
        encontrado = dc('run', '--rm', '--no-deps', '-T', '--entrypoint', 'find', 'web',
                        '/var/moodledata', '-mindepth', '1', '-maxdepth', '1',
                        capture_output=True, text=True).stdout.strip()
        if encontrado:
            print('El volumen no esta vacio: no se sobrescribe', file=sys.stderr)
            return 1
        with pieza.open('rb') as f:
            dc('run', '--rm', '--no-deps', '-T', '--user', '0', '--entrypoint', 'tar',
               'web', '-xzf', '-', '-C', '/var/moodledata', stdin=f)
    print('Archivos restaurados.')
    return 0


if __name__ == '__main__':
    sys.exit(main())
