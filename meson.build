# SPDX-License-Identifier: GPL-3.0-or-later
project('darkroom', ['vala', 'c'], version: '0.1.0', meson_version: '>=1.0.0',
  license: 'GPL-3.0-or-later', default_options: ['warning_level=2'])

glib = dependency('glib-2.0', version: '>=2.76')
gio = dependency('gio-2.0')
pixbuf = dependency('gdk-pixbuf-2.0')
preview_deps = [glib, gio, pixbuf]
preview_sources = files('src/photo-preview.vala')

photo_tests = executable('photo-tests', preview_sources, 'tests/photo-tests.vala',
  dependencies: preview_deps)
test('photo-preview', photo_tests, suite: 'unit')

gtk = dependency('gtk4', version: '>=4.10')
adw = dependency('libadwaita-1', version: '>=1.4')
app_deps = preview_deps + [gtk, adw]
app_sources = preview_sources + files('src/application.vala', 'src/window.vala')
executable('darkroom', app_sources, 'src/main.vala', dependencies: app_deps, install: true)
gui_tests = executable('gui-smoke', app_sources, 'tests/gui-smoke.vala', dependencies: app_deps)
xvfb = find_program('xvfb-run')
dbus = find_program('dbus-run-session')
test('gui-smoke', xvfb,
  args: ['-a', dbus.full_path(), '--config-file=' + meson.current_source_dir() / 'tests/session.conf', gui_tests],
  env: ['GDK_BACKEND=x11', 'GSK_RENDERER=cairo', 'GTK_A11Y=none', 'GIO_USE_VFS=local', 'GSETTINGS_BACKEND=memory'],
  suite: 'gui', timeout: 30)

install_data('data/org.darkroom.Darkroom.desktop', install_dir: get_option('datadir') / 'applications')
install_data('data/org.darkroom.Darkroom.metainfo.xml', install_dir: get_option('datadir') / 'metainfo')
install_data('data/org.darkroom.Darkroom.svg', install_dir: get_option('datadir') / 'icons/hicolor/scalable/apps')
install_data('LICENSE', install_dir: get_option('datadir') / 'licenses/darkroom')
desktop_validator = find_program('desktop-file-validate')
appstream_validator = find_program('appstreamcli')
test('desktop-entry', desktop_validator,
  args: [meson.current_source_dir() / 'data/org.darkroom.Darkroom.desktop'], suite: 'metadata')
test('appstream', appstream_validator,
  args: ['validate', '--no-net',
    meson.current_source_dir() / 'data/org.darkroom.Darkroom.metainfo.xml'], suite: 'metadata')
